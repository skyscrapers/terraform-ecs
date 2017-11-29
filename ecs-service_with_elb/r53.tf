resource "aws_route53_zone" "zone" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "service_record" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${var.service_name}"
  type    = "A"

  alias {
    name                   = "${module.elb.elb_dns_name}"
    zone_id                = "${module.elb.elb_zone_id}"
    evaluate_target_health = "${var.evaluate_target_health}"
  }
}

