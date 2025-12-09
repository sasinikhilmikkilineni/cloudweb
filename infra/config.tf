## AWS Config for required tagging enforcement

locals {
  config_bucket_name = "${var.project}-config-${var.environment}-${var.region}-${var.aws_account_id}"
}

resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.tags, {
    Name = "${var.project}-config-bucket"
  })
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config" {
  name               = "${var.project}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json

  tags = merge(local.tags, {
    Name = "${var.project}-config-role"
  })
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }

  depends_on = [aws_iam_role_policy_attachment.config_managed]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project}-delivery"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_config_rule" "required_tags" {
  name = "${var.project}-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  input_parameters = jsonencode({
    tag1Key = "Project"
    tag2Key = "Owner"
    tag3Key = "Environment"
    tag4Key = "ManagedBy"
    tag5Key = "CreatedBy"
  })

  maximum_execution_frequency = "Six_Hours"

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = merge(local.tags, {
    Name = "${var.project}-required-tags-rule"
  })
}
