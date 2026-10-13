data "aws_caller_identity" "current" {}

####################################
# EC2 Assume Role Policy
####################################

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

####################################
# Front EC2 Role
####################################

resource "aws_iam_role" "front_ec2" {
  name               = "${var.project_name}-${var.environment}-front-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "back_ssm" {
  role       = aws_iam_role.back_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "front_ssm" {
  role       = aws_iam_role.front_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "front_ec2_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [var.front_repository_arn]
  }
}

resource "aws_iam_policy" "front_ec2" {
  name   = "${var.project_name}-${var.environment}-front-ec2-policy"
  policy = data.aws_iam_policy_document.front_ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "front_ec2" {
  role       = aws_iam_role.front_ec2.name
  policy_arn = aws_iam_policy.front_ec2.arn
}

resource "aws_iam_instance_profile" "front_ec2" {
  name = "${var.project_name}-${var.environment}-front-instance-profile"
  role = aws_iam_role.front_ec2.name
}

####################################
# Back EC2 Role
####################################

resource "aws_iam_role" "back_ec2" {
  name               = "${var.project_name}-${var.environment}-back-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "back_ec2_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [var.back_repository_arn]
  }

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]

    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
    ]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [var.backend_secret_arn]
  }
}

resource "aws_iam_policy" "back_ec2" {
  name   = "${var.project_name}-${var.environment}-back-ec2-policy"
  policy = data.aws_iam_policy_document.back_ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "back_ec2" {
  role       = aws_iam_role.back_ec2.name
  policy_arn = aws_iam_policy.back_ec2.arn
}

resource "aws_iam_instance_profile" "back_ec2" {
  name = "${var.project_name}-${var.environment}-back-instance-profile"
  role = aws_iam_role.back_ec2.name
}