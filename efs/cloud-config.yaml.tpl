#cloud-config
package_upgrade: true
packages:
- nfs-utils
runcmd:
- mkdir -p ${mount_point}
- chown ec2-user:ec2-user ${mount_point}
- echo "${dns_name}:/ ${mount_point} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab
- mount -a -t nfs4
