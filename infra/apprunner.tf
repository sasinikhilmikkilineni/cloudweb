data "aws_secretsmanager_secret" "mongo_uri" { name = var.secret_mongo_uri_name }
data "aws_secretsmanager_secret" "jwt_secret" { name = var.secret_jwt_secret_name }
data "aws_secretsmanager_secret" "paypal_client_id" { name = var.secret_paypal_client_id_name }

resource "aws_iam_role" "apprunner_ecr" {
  name = "${local.name}-apprunner-ecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apprunner_ecr_pull" {
  name = "${local.name}-apprunner-ecr-pull"
  role = aws_iam_role.apprunner_ecr.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ecr:GetAuthorizationToken", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "apprunner_instance" {
  name = "${local.name}-apprunner-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apprunner_read_secrets" {
  name = "${local.name}-apprunner-read-secrets"
  role = aws_iam_role.apprunner_instance.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["secretsmanager:GetSecretValue"],
      Resource = [
        data.aws_secretsmanager_secret.mongo_uri.arn,
        data.aws_secretsmanager_secret.jwt_secret.arn,
        data.aws_secretsmanager_secret.paypal_client_id.arn
      ]
    }]
  })
}

resource "aws_apprunner_service" "api" {
  service_name = "${local.name}-api"

  source_configuration {
    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr.arn
    }

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = var.backend_image

      image_configuration {
        port = "5000"

        runtime_environment_variables = {
          NODE_ENV = "production"
          PORT     = "5000"
        }

        runtime_environment_secrets = {
          MONGO_URI        = data.aws_secretsmanager_secret.mongo_uri.arn
          JWT_SECRET       = data.aws_secretsmanager_secret.jwt_secret.arn
          PAYPAL_CLIENT_ID = data.aws_secretsmanager_secret.paypal_client_id.arn
        }
      }
    }
  }

  instance_configuration {
    cpu               = "1 vCPU"
    memory            = "2 GB"
    instance_role_arn = aws_iam_role.apprunner_instance.arn
  }

  health_check_configuration {
    protocol            = "HTTP"
    path = "/api/products"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = local.tags
}
