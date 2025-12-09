provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Owner       = var.owner
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedBy   = "Terraform"
    }
  }
}
