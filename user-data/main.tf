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

echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
start ecs
EOF
  }

  part {
    content_type = "text/x-shellscript"

    content = "${module.teleport_bootstrap_script.teleport_bootstrap_script}"
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
