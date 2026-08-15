# resource "null_resource" "update_ecs_service" {
#   depends_on = [
#     module.ecs_core_services.aws_ecs_service.hermes, # Ensure ECS service is fully created
#   ]

#   provisioner "local-exec" {
#     command = <<EOT
#       echo "Updating ECS service..."
#       echo "Cluster: ${data.terraform_remote_state.ecs_cluster_crawler.outputs.ecs_cluster_name}"
#       echo "Service: ${var.base_name}-hermes"
#       aws ecs update-service \
#         --cluster "${data.terraform_remote_state.ecs_cluster_crawler.outputs.ecs_cluster_name}" \
#         --service "${var.base_name}-hermes" \
#         --force-new-deployment \
#         --propagate-tags SERVICE
#     EOT
#   }
# }
