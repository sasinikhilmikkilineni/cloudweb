variable "project" {
  type    = string
  default = "proshop"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "backend_image" {
  type = string
}

variable "frontend_bucket_name" {
  type = string
}

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
