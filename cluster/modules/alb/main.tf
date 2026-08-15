/*==============================================================
      AWS Application Load Balancer + Target groups
===============================================================*/

resource "aws_alb" "alb" {
  count              = var.create_alb == true ? 1 : 0
  name               = "${var.name}-alb"
  subnets            = var.subnets
  security_groups    = var.security_group
  load_balancer_type = "application"
  internal           = var.internal
  enable_http2       = var.internal
  idle_timeout       = 30
}

resource "aws_alb_listener" "https_listener" {
  count             = var.create_alb == true ? 1 : 0
  load_balancer_arn = aws_alb.alb[0].id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Default response from ALB"
      status_code  = "200"
    }
  }
}
