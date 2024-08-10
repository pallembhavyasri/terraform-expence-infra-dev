# in order to access the HTTPS we need to cerete the certificate manager 

resource "aws_acm_certificate" "expence" {
  domain_name       = "*.bhavya.store"
  validation_method = "DNS"

tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}"
    }
  )
}

#it updates the record in domain 
resource "aws_route53_record" "expence" {
  for_each = {
    for dvo in aws_acm_certificate.expence.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

#validates the certification 
resource "aws_acm_certificate_validation" "expence" {
  certificate_arn         = aws_acm_certificate.expence.arn
  validation_record_fqdns = [for record in aws_route53_record.expence : record.fqdn]
}
