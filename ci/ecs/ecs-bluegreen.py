#!/usr/bin/env python2.7

import boto3
import getopt
import sys
import subprocess
import time
from datetime import datetime
import json


def main(argv):
    helptext = 'ecs-bluegreen.py -f <path to terraform project> -a <ami> -c <command> -t <timeout> -e <environment.tfvars> <path>'

    try:
        opts, args = getopt.getopt(argv, "hsrf:a:c:t:e:", ["folder=", "ami=", "command=", "timeout=", "environment="])
    except getopt.GetoptError:
        print(helptext)
        sys.exit(2)

    if opts:
        for opt, arg in opts:
            if opt == '-h':
                print(helptext)
                sys.exit(2)
            elif opt in ("-f", "--folder"):
                projectPath = arg
            elif opt in ("-a", "--ami"):
                ami = arg
            elif opt in ("-c", "--command"):
                command = arg
            elif opt in ("-t", "--timeout"):
                maxTimeout = int(arg)
            elif opt in ("-e", "--environment"):
                environment = arg
            elif opt in ("-s"):
                stopScaling = True
            elif opt in ("-r","--force-recycle"):
                forceRecycle = True
    else:
        print(helptext)
        sys.exit(2)

    if 'command' not in locals():
        command = 'plan'

    if 'maxTimeout' not in locals():
        maxTimeout = 200

    if 'projectPath' not in locals():
        print('Please give your folder path of your Terraform project')
        print(helptext)
        sys.exit(2)

    if 'ami' not in locals():
        print('Please give an AMI as argument')
        print(helptext)
        sys.exit(2)

    if 'environment' not in locals():
        environment = None

    if 'stopScaling' not in locals():
        stopScaling = False

    if 'forceRecycle' not in locals():
        forceRecycle = False

    # Retrieve autoscaling group names and ecs cluster info
    tf_output = getTerraformOutput(projectPath)
    output_requirements = ['blue_asg_id','green_asg_id','ecs_cluster_name']
    # Verify TF output
    if len([x for x in output_requirements if x not in tf_output.keys()]) > 0:
        print("Missing required output from terraform stack " + str([x for x in output_requirements if x not in tf_output.keys()]))
        sys.exit(2)
    agBlue = tf_output['blue_asg_id']
    agGreen = tf_output['green_asg_id']
    ecs_cluster = tf_output['ecs_cluster_name']
    # Retrieve autoscaling groups information
    info = getAutoscalingInfo([agBlue, agGreen])
    # Determine the active autoscaling group
    active = getActive(info)
    desiredInstanceCount = info['AutoScalingGroups'][active]['DesiredCapacity'] * 2
    # Bring up the not active autoscaling group with the new AMI
    scaleUpAutoscaling(info, active, ami, command, projectPath, environment)

    # Retrieve autoscaling groups information (we need to do this again because the launchconig has changed and we need this in a later phase)
    info = getAutoscalingInfo([agBlue, agGreen])
    if 'apply' in command:
        print('Waiting for 30 seconds to get autoscaling status')
        time.sleep(30)
        timeout = 30
        ecs_info = getECSInfo(ecs_cluster)
        while len(ecs_info['containerInstanceArns']) != desiredInstanceCount:
            print("Current active cluster nodes: %s desired: %s" % (str(len(ecs_info['containerInstanceArns'])),str(desiredInstanceCount)))
            if timeout > maxTimeout:
                print('Rolling back, reached timeout while registering instances to ECS cluster')
                rollbackAutoscaling(info, active, ami, command, projectPath, environment)
                print('Rollback complete: unable to get the desired amount of nodes registered to the ECS cluster')
                sys.exit(2)

            print('Waiting for 10 seconds to get ecs status')
            time.sleep(10)
            timeout += 10
            ecs_info = getECSInfo(ecs_cluster)
        removeInstancesFromECS(info['AutoScalingGroups'][active],ecs_cluster,ecs_info,forceRecycle,maxTimeout)
        print('Deactivating the autoscaling')
        scaleDownAutoscaling(info, active, ami, command, projectPath, environment)

def removeInstancesFromECS(old_asg,ecs_cluster,ecs_info,forceRecycle,maxTimeout=500):
    client = boto3.client('ecs')
    ecs_instances_list = describeECSInstance(ecs_info['containerInstanceArns'],ecs_cluster)
    old_cluster_instance_ids = [ecs_instance['containerInstanceArn'] for ecs_instance in ecs_instances_list['containerInstances'] if ecs_instance['ec2InstanceId'] in [instance['InstanceId'] for instance in old_asg['Instances']]]
    response = client.update_container_instances_state(
        cluster=ecs_cluster,
        containerInstances=old_cluster_instance_ids,
        status='DRAINING'
    )
    time.sleep(60)
    timeout=60
    for instance in old_cluster_instance_ids:
        instance_details = describeECSInstance([instance],ecs_cluster)
        while instance_details['containerInstances'][0]['runningTasksCount'] != 0:
            if timeout > maxTimeout:
                if forceRecycle:
                    print("Force recycling of instance: "+instance)
                    break
                else:
                    sys.exit(2)
            print("still active number of tasks: " + str(instance_details['containerInstances'][0]['runningTasksCount']))
            time.sleep(10)
            instance_details = describeECSInstance([instance],ecs_cluster)
            timeout += 10
        response = client.deregister_container_instance(
            cluster=ecs_cluster,
            containerInstance=instance,
            force=False
        )
        timeout=0

def describeECSInstance(container_instance_ids,ecs_cluster):
    client = boto3.client('ecs')
    response = client.describe_container_instances(
        cluster=ecs_cluster,
        containerInstances=container_instance_ids
    )
    return response

def getECSInfo(ecs_cluster):
    client = boto3.client('ecs')
    response = client.list_container_instances(
        cluster=ecs_cluster
    )
    return response

def getTerraformOutput(projectPath, output=''):
    process = subprocess.Popen('terraform output -json' + output, shell=True, cwd=projectPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    std_out, std_err = process.communicate()
    if process.returncode != 0:
        err_msg = "%s. Code: %s" % (std_err.strip(), process.returncode)
        print(err_msg)
        sys.exit(process.returncode)
    tf_output=json.loads(std_out)

    try:
        return {name : tf_output[name]["value"] for name in tf_output.keys()}
    except:
        print(std_out)

def getAutoscalingInfo(asgs):
    client = boto3.client('autoscaling')
    response = client.describe_auto_scaling_groups(
        AutoScalingGroupNames=asgs,
        MaxRecords=2
    )
    return response


def getAmi(launchconfig):
    client = boto3.client('autoscaling')
    response = client.describe_launch_configurations(
        LaunchConfigurationNames=[
            launchconfig,
        ],
        MaxRecords=1
    )
    return response['LaunchConfigurations'][0]['ImageId']


def getLaunchconfigDate(launchconfig):
    client = boto3.client('autoscaling')
    response = client.describe_launch_configurations(
        LaunchConfigurationNames=[
            launchconfig,
        ],
        MaxRecords=1
    )
    return response['LaunchConfigurations'][0]['CreatedTime']


def getActive(info):
    if info['AutoScalingGroups'][1]['DesiredCapacity'] == 0:
        print('Blue is active')
        return 0
    elif info['AutoScalingGroups'][0]['DesiredCapacity'] == 0:
        print('Green is active')
        return 1
    else:
        blueDate = getLaunchconfigDate(info['AutoScalingGroups'][0]['LaunchConfigurationName'])
        greenDate = getLaunchconfigDate(info['AutoScalingGroups'][1]['LaunchConfigurationName'])
        # use the ASG with the oldest launch config
        if blueDate < greenDate:
            print('Blue has oldest launchconfig')
            return 1
        else:
            print('Green has oldest launchconfig')
            return 0


def scaleUpAutoscaling(info, active, ami, command, projectPath, environment):
    blueMin = info['AutoScalingGroups'][active]['MinSize']
    blueMax = info['AutoScalingGroups'][active]['MaxSize']
    blueDesired = info['AutoScalingGroups'][active]['DesiredCapacity']

    greenMin = info['AutoScalingGroups'][active]['MinSize']
    greenMax = info['AutoScalingGroups'][active]['MaxSize']
    greenDesired = info['AutoScalingGroups'][active]['DesiredCapacity']

    if active == 0:
        blueAMI = getAmi(info['AutoScalingGroups'][active]['LaunchConfigurationName'])
        greenAMI = ami
    elif active == 1:
        blueAMI = ami
        greenAMI = getAmi(info['AutoScalingGroups'][active]['LaunchConfigurationName'])
    else:
        print('No acive AMI')
        sys.exit(1)

    updateAutoscaling(command, blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, projectPath, environment)


def scaleDownAutoscaling(info, active, ami, command, projectPath, environment):
    blueAMI = getAmi(info['AutoScalingGroups'][0]['LaunchConfigurationName'])
    greenAMI = getAmi(info['AutoScalingGroups'][1]['LaunchConfigurationName'])
    if active == 0:
        blueMin = 0
        blueMax = 0
        blueDesired = 0

        greenMin = info['AutoScalingGroups'][active]['MinSize']
        greenMax = info['AutoScalingGroups'][active]['MaxSize']
        greenDesired = info['AutoScalingGroups'][active]['DesiredCapacity']
    elif active == 1:
        blueMin = info['AutoScalingGroups'][active]['MinSize']
        blueMax = info['AutoScalingGroups'][active]['MaxSize']
        blueDesired = info['AutoScalingGroups'][active]['DesiredCapacity']

        greenMin = 0
        greenMax = 0
        greenDesired = 0
    else:
        print('No acive AMI')
        sys.exit(1)

    updateAutoscaling(command, blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, projectPath, environment)


def rollbackAutoscaling(info, active, ami, command, projectPath, environment):
    blueAMI = getAmi(info['AutoScalingGroups'][0]['LaunchConfigurationName'])
    greenAMI = getAmi(info['AutoScalingGroups'][1]['LaunchConfigurationName'])

    if active == 0:
        blueMin = info['AutoScalingGroups'][0]['MinSize']
        blueMax = info['AutoScalingGroups'][0]['MaxSize']
        blueDesired = info['AutoScalingGroups'][0]['DesiredCapacity']

        greenMin = 0
        greenMax = 0
        greenDesired = 0
    elif active == 1:
        greenMin = info['AutoScalingGroups'][1]['MinSize']
        greenMax = info['AutoScalingGroups'][1]['MaxSize']
        greenDesired = info['AutoScalingGroups'][1]['DesiredCapacity']

        blueMin = 0
        blueMax = 0
        blueDesired = 0
    else:
        print('No acive AMI')
        sys.exit(1)

    updateAutoscaling(command, blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, projectPath, environment)


def stopAutoscaling(info, active, ami, command, projectPath, environment):
    blueMin = info['AutoScalingGroups'][active]['MinSize']
    blueMax = info['AutoScalingGroups'][active]['MaxSize']
    blueDesired = 0

    greenMin = info['AutoScalingGroups'][active]['MinSize']
    greenMax = info['AutoScalingGroups'][active]['MaxSize']
    greenDesired = 0

    if active == 0:
        blueAMI = getAmi(info['AutoScalingGroups'][active]['LaunchConfigurationName'])
        greenAMI = ami
    elif active == 1:
        blueAMI = ami
        greenAMI = getAmi(info['AutoScalingGroups'][active]['LaunchConfigurationName'])
    else:
        print('No acive AMI')
        sys.exit(1)

    updateAutoscaling(command, blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, projectPath, environment)


def updateAutoscaling(command, blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, projectPath, environment):
    command = 'terraform %s %s' % (command, buildTerraformVars(blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, environment))
    print(command)
    process = subprocess.Popen(command, shell=True, cwd=projectPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = process.communicate()
    print('stdoutput')
    print(out)
    if process.returncode != 0:
        print('stderror')
        print(err)
        sys.exit(process.returncode)


def buildTerraformVars(blueMax, blueMin, blueDesired, blueAMI, greenMax, greenMin, greenDesired, greenAMI, environment):
    variables = {
        'blue_max_size': blueMax,
        'blue_min_size': blueMin,
        'blue_desired_capacity': blueDesired,
        'blue_ami': blueAMI,
        'green_max_size': greenMax,
        'green_min_size': greenMin,
        'green_desired_capacity': greenDesired,
        'green_ami': greenAMI
    }
    out = []

    # When using terraform environments, set the environment tfvars file
    if environment is not None:
        out.append('-var-file=%s' % (environment))

    for key, value in variables.iteritems():
        out.append('-var \'%s=%s\'' % (key, value))

    return ' '.join(out)


if __name__ == "__main__":
    main(sys.argv[1:])
