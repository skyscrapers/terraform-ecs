data "template_file" "prometheus_service_cloudinit" {
  template = "${file("${path.module}/templates/prometheus.service.tpl")}"

  vars {
    prometheus_service = "${indent(4,file("${path.module}/templates/prometheus-upstart.conf"))}"
    service_type_path  = "/etc/init.d/prometheus"
    file_permissions   = "0755"
  }
}

data "template_cloudinit_config" "teleport_bootstrap" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "package_update: true"
  }

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }

  part {
    content_type = "text/cloud-config"

    content = <<EOF
write_files:
${module.teleport_bootstrap_script.teleport_config_cloudinit}
${module.teleport_bootstrap_script.teleport_service_cloudinit}
${data.template_file.prometheus_service_cloudinit.rendered}
EOF
  }

  part {
    content_type = "text/x-shellscript"

    content = <<EOF
#!/bin/bash
cd /tmp
curl -L "https://get.gravitational.com/teleport-v${var.teleport_version}-linux-amd64-bin.tar.gz" > ./teleport.tar.gz
sudo tar -xzf ./teleport.tar.gz
sudo ./teleport/install

# Prevent containers that use the bridge network mode from accessing the
# credential information supplied to the container instance profile.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
service iptables save
cd /opt
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${var.node_exporter_version}/node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz"
tar -xzf node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz
mv node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
start ecs
service prometheus start
EOF
  }

  part {
    content_type = "text/x-shellscript"

    content = "${module.teleport_bootstrap_script.teleport_bootstrap_script}"
  }

  part {
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config
package_upgrade: true
packages:
- nfs-utils
runcmd:
- mkdir -p ${var.efs_mount_point}/data
- echo "fs-15a0d8dc.efs.eu-west-1.amazonaws.com:/ ${var.efs_mount_point} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab
- mount -a -t nfs4
EOF
  }
}

module "teleport_bootstrap_script" {
  source       = "github.com/skyscrapers/terraform-teleport//teleport-bootstrap-script?ref=3.2.0"
  auth_server  = "${var.teleport_server}"
  auth_token   = "${var.teleport_auth_token}"
  function     = "ecs"
  environment  = "${var.environment}"
  project      = "${var.project}"
  service_type = "upstart"
}
