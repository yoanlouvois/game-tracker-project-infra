data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

####################################
# Launch Template Front
####################################

resource "aws_launch_template" "front" {
  name_prefix   = "${var.project_name}-${var.environment}-front-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type_app

  iam_instance_profile {
    name = var.front_instance_profile_name
  }

  vpc_security_group_ids = [var.front_sg_id]

    block_device_mappings {
      device_name = "/dev/xvda"

      ebs {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
    }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

dnf update -y
dnf install -y docker awscli amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

systemctl enable docker
systemctl start docker

aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin 147914447581.dkr.ecr.eu-west-3.amazonaws.com

docker pull ${var.front_repository_url}:latest

docker run -d \
  --name gametracker-front \
  --restart=always \
  -p 80:80 \
  ${var.front_repository_url}:latest
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-front"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "front" {
  name                = "${var.project_name}-${var.environment}-front-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = var.private_app_subnet_ids

  target_group_arns = [var.front_target_group_arn]

  launch_template {
    id      = aws_launch_template.front.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 120
}

####################################
# Launch Template Back
####################################

resource "aws_launch_template" "back" {
  name_prefix   = "${var.project_name}-${var.environment}-back-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type_app

  iam_instance_profile {
    name = var.back_instance_profile_name
  }

  vpc_security_group_ids = [var.back_sg_id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

dnf update -y
dnf install -y docker awscli amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

systemctl enable docker
systemctl start docker

aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin 147914447581.dkr.ecr.eu-west-3.amazonaws.com

BACKEND_SECRET=$(aws secretsmanager get-secret-value \
  --region ${var.aws_region} \
  --secret-id ${var.project_name}/${var.environment}/backend \
  --query SecretString \
  --output text)

SPRING_DATASOURCE_PASSWORD=$(echo $BACKEND_SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['SPRING_DATASOURCE_PASSWORD'])")
CLOUDINARY_API_SECRET=$(echo $BACKEND_SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['CLOUDINARY_API_SECRET'])")
JWT_SECRET=$(echo $BACKEND_SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['JWT_SECRET'])")

CLOUDINARY_CLOUD_NAME=$(aws ssm get-parameter --region ${var.aws_region} --name "/${var.project_name}/${var.environment}/cloudinary/cloud-name" --query Parameter.Value --output text)
CLOUDINARY_API_KEY=$(aws ssm get-parameter --region ${var.aws_region} --name "/${var.project_name}/${var.environment}/cloudinary/api-key" --query Parameter.Value --output text)

docker pull ${var.back_repository_url}:latest

docker run -d \
  --name gametracker-back \
  --restart=always \
  -p 8081:8081 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://${var.db_address}:3306/db_pgt?sslMode=REQUIRED&serverTimezone=UTC" \
  -e SPRING_DATASOURCE_USERNAME="${var.spring_datasource_username}" \
  -e SPRING_DATASOURCE_PASSWORD="$SPRING_DATASOURCE_PASSWORD" \
  -e CLOUDINARY_CLOUD_NAME="$CLOUDINARY_CLOUD_NAME" \
  -e CLOUDINARY_API_KEY="$CLOUDINARY_API_KEY" \
  -e CLOUDINARY_API_SECRET="$CLOUDINARY_API_SECRET" \
  -e JWT_SECRET="$JWT_SECRET" \
  ${var.back_repository_url}:latest
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-back"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "back" {
  name                = "${var.project_name}-${var.environment}-back-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = var.private_app_subnet_ids

  target_group_arns = [var.back_target_group_arn]

  launch_template {
    id      = aws_launch_template.back.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180
}