resource "aws_route53_zone" "zone" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "service_record" {
  zone_id = ${aws_route53_zone.zone.zone_id}
  name    = "${service_name}"
  type    = "A"

  alias {
    name                   = "${module.elb.dns_name}"
    zone_id                = "${module.elb.zone_id}"
  }
}

