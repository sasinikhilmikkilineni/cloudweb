## ECS Task Execution Role (Minimal Permissions)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "proshop-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

## Policy: Pull Docker image from ECR only
resource "aws_iam_role_policy" "ecs_task_execution_ecr_pull" {
  name   = "proshop-ecr-pull"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRGetAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRBatchGetImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/proshop-*"
      }
    ]
  })
}

## Policy: Write logs to CloudWatch only
resource "aws_iam_role_policy" "ecs_task_execution_logs" {
  name   = "proshop-cloudwatch-logs"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:/ecs/proshop-*"
      }
    ]
  })
}

## ECS Task Role (Application Runtime)
resource "aws_iam_role" "ecs_task_role" {
  name = "proshop-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

## Policy: Read secrets from Secrets Manager ONLY
resource "aws_iam_role_policy" "ecs_task_secrets_manager" {
  name   = "proshop-secrets-manager-read"
  role   = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProshopSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:proshop/*"
        ]
      }
    ]
  })
}

## Data source: Get current AWS account ID
data "aws_caller_identity" "current" {}

## Outputs
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

## Policy: Task execution role needs to read secrets for injection
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name   = "proshop-execution-secrets-read"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProshopSecretsForExecution"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:proshop/*"
        ]
      }
    ]
  })
}
