resource "aws_alb_listener_rule" "dynamic_host_header_rule" {
  for_each     = var.listener_rules
  listener_arn = data.terraform_remote_state.ecs_cluster_main.outputs["https_listener_arn_public"]

  priority = each.value.priority

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {
    host_header {
      values = [each.value.host_header]
    }
  }
}

resource "aws_alb_listener_rule" "dynamic_host_header_rule_pvt" {
  for_each     = var.listener_rules_private
  listener_arn = data.terraform_remote_state.ecs_cluster_main.outputs["https_listener_arn_private"]

  priority = each.value.priority

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {
    host_header {
      values = [each.value.host_header]
    }
  }
}
