output "userdata" {
  value = data.template_cloudinit_config.teleport_bootstrap.rendered
}

