## Tagging Documentation
## Mandatory tags are enforced via provider default_tags in providers.tf
## All resources automatically receive these tags:
## - Project: var.project (ProShop)
## - Owner: var.owner (sasinikhil@sjsu.edu)
## - Environment: var.environment (production)
## - ManagedBy: "Terraform"
## - CreatedBy: "Terraform"

output "tag_query_examples" {
  value = <<EOF
# Find all ProShop resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=ProShop" --region ${var.region}

# Find all Production resources
aws ec2 describe-instances --filters "Name=tag:Environment,Values=production" --region ${var.region}

# Find all resources created by Terraform
aws ec2 describe-instances --filters "Name=tag:CreatedBy,Values=Terraform" --region ${var.region}

# Cost analysis by project
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-12-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=Project

# Tag compliance report
aws resourcegroupstaggingapi get-resources \
  --filters-expression "tag:Project=ProShop" \
  --region ${var.region}
EOF
  description = "Examples of querying resources by tags"
}

