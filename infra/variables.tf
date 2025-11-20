variable "project" {
  type    = string
  default = "proshop"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# ECR image you pushed (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/proshop-api:main)
variable "backend_image" {
  type = string
}

# Must be globally unique
variable "frontend_bucket_name" {
  type = string
}

# Existing Secrets Manager names (must already exist)
variable "secret_mongo_uri_name" {
  type    = string
  default = "proshop/MONGO_URI"
}

variable "secret_jwt_secret_name" {
  type    = string
  default = "proshop/JWT_SECRET"
}

variable "secret_paypal_client_id_name" {
  type    = string
  default = "proshop/PAYPAL_CLIENT_ID"
}
