output "cloud_config" {
  value = "${data.template_file.efs.rendered}"
}

output "dns_name" {
  value = "${aws_efs_file_system.efs.dns_name}"
}

output "kms_key_id" {
  value = "${aws_efs_file_system.efs.kms_key_id}"
}

output "efs_id" {
  value = "${aws_efs_file_system.efs.id}"
}

output "mount_ids" {
  value = "${aws_efs_mount_target.efs.*.id}"
}

output "mount_interface_ids" {
  value = "${aws_efs_mount_target.efs.*.network_interface_id}"
}
