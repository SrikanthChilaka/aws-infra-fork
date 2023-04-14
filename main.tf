provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "vpc_1" {
  cidr_block = var.vpc_cidr[0]

  tags = {
    Name = "${var.vpc_name_1}"
  }
}

# resource "aws_vpc" "vpc_2" {
#   cidr_block = var.vpc_cidr[1]

#   tags = {
#     Name = "${var.vpc_name_2}"
#   }
# }

resource "aws_subnet" "public_subnets_1" {
  count             = 3
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "${var.subnet_prefix_1}${count.index + 1}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index + 1}"
  }
}

# resource "aws_subnet" "public_subnets_2" {
#   count             = 3
#   vpc_id            = aws_vpc.vpc_2.id
#   cidr_block        = "${var.subnet_prefix_2}${count.index + 1}${var.subnet_postfix}"
#   availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

#   tags = {
#     Name = "${var.public_subnet_name}-${count.index + 1}"
#   }
# }

resource "aws_subnet" "private_subnets_1" {
  count             = 3
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "${var.subnet_prefix_1}${count.index + 4}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index + 1}"
  }
}

# resource "aws_subnet" "private_subnets_2" {
#   count             = 3
#   vpc_id            = aws_vpc.vpc_2.id
#   cidr_block        = "${var.subnet_prefix_2}${count.index + 4}${var.subnet_postfix}"
#   availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

#   tags = {
#     Name = "${var.private_subnet_name}-${count.index + 1}"
#   }
# }

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.gateway_name_1}"
  }
}

# resource "aws_internet_gateway" "gw2" {
#   vpc_id = aws_vpc.vpc_2.id

#   tags = {
#     Name = "${var.gateway_name_2}"
#   }
# }

resource "aws_route_table" "public_route_table_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = var.rt_cidr
    gateway_id = aws_internet_gateway.gw1.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

# resource "aws_route_table" "public_route_table_2" {
#   vpc_id = aws_vpc.vpc_2.id

#   route {
#     cidr_block = var.rt_cidr
#     gateway_id = aws_internet_gateway.gw2.id
#   }

#   tags = {
#     Name = "${var.public_rt_name}"
#   }
# }

resource "aws_route_table_association" "rt_associate_public_1" {
  count          = 3
  subnet_id      = aws_subnet.public_subnets_1[count.index].id
  route_table_id = aws_route_table.public_route_table_1.id
}

# resource "aws_route_table_association" "rt_associate_public_2" {
#   count          = 3
#   subnet_id      = aws_subnet.public_subnets_2[count.index].id
#   route_table_id = aws_route_table.public_route_table_2.id
# }

resource "aws_route_table" "private_route_table_1" {

  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.private_rt_name}"
  }

}

# resource "aws_route_table" "private_route_table_2" {

#   vpc_id = aws_vpc.vpc_2.id

#   tags = {
#     Name = "${var.private_rt_name}"
#   }

# }

resource "aws_route_table_association" "rt_associate_private_1" {
  count          = 3
  subnet_id      = aws_subnet.private_subnets_1[count.index].id
  route_table_id = aws_route_table.private_route_table_1.id
}

# resource "aws_route_table_association" "rt_associate_private_2" {
#   count          = 3
#   subnet_id      = aws_subnet.private_subnets_2[count.index].id
#   route_table_id = aws_route_table.private_route_table_2.id
# }

resource "random_uuid" "random_bucket_suffix" {
}

resource "aws_s3_bucket" "webapp_s3_bucket" {
  bucket = "webapp-s3-${var.aws_profile}-${random_uuid.random_bucket_suffix.result}"
  acl    = "private"
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       sse_algorithm = "AES256"
  #     }
  #   }
  # }
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.webapp_s3_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.webapp_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp_s3_bucket.id
  rule {
    id     = "transition-objects-to-standard-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  # rule {
  #   id     = "delete-empty-bucket"
  #   prefix = ""
  #   status = "Enabled"
  #   expiration {
  #     days = 14
  #   }
  # }
}

resource "aws_iam_role" "s3_access_role" {
  name = var.s3_iam_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_instance_profile" "s3_access_instance_profile" {
  name = var.s3_iam_pro
  role = aws_iam_role.s3_access_role.name

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name = var.s3_iam_pol
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.webapp_s3_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.webapp_s3_bucket.bucket}/*"
        ]
      }
    ]
    }
  )
}
resource "aws_iam_role_policy_attachment" "s3_access_role_policy_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.s3_access_role.name
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds_subnet_group"
  subnet_ids = [
    aws_subnet.private_subnets_1[0].id,
    aws_subnet.private_subnets_1[1].id,
    aws_subnet.private_subnets_1[2].id
  ]
  description = "Subnet group for the RDS instance"
}

resource "aws_db_instance" "rds_instance" {
  db_name                = var.DB_NAME
  identifier             = var.DB_IDENTIFIER
  engine                 = var.db_engine
  instance_class         = "db.t3.micro"
  multi_az               = false
  username               = var.DB_USERNAME
  password               = var.DB_PASSWORD
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.name
  allocated_storage      = 20
  skip_final_snapshot    = true
  #   engine_version         = "5.7"

  tags = {
    Name = "csye6225_rds"
  }
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  name_prefix = "rds-db-parameter-group"
  family      = "mysql8.0"
  description = "MySQL parameter group for RDS DB"
  # tags        = local.common_tags

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "268435456"
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.application.id
}

resource "aws_security_group_rule" "rds_egress" {
  type                     = "egress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.application.id
}

resource "aws_security_group_rule" "ec2_ingress_db" {
  type                     = "ingress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.application.id
  source_security_group_id = aws_security_group.db_security_group.id
}

resource "aws_security_group" "application" {
  name        = var.security_grp_name
  description = "security group for ec2-webapp"
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port       = var.ports[3]
    to_port         = var.ports[3]
    protocol        = "tcp"
    cidr_blocks     = [var.rt_cidr]
    security_groups = [aws_security_group.lb_sg.id]
  }

  # ingress {
  #   from_port   = var.ports[1]
  #   to_port     = var.ports[1]
  #   protocol    = "tcp"
  #   cidr_blocks = [var.rt_cidr]
  # }

  ingress {
    from_port       = var.ports[0]
    to_port         = var.ports[0]
    protocol        = "tcp"
    cidr_blocks     = [var.rt_cidr]
    security_groups = [aws_security_group.lb_sg.id]
  }

  # ingress {
  #   from_port   = var.ports[2]
  #   to_port     = var.ports[2]
  #   protocol    = "tcp"
  #   cidr_blocks = [var.rt_cidr]
  # }

  egress {
    from_port = var.ports[5]
    to_port   = var.ports[5]
    protocol  = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = "-1"
    cidr_blocks = [var.rt_cidr]
  }
  tags = {
    Name = var.security_grp_name
  }
}

resource "aws_security_group" "db_security_group" {
  name_prefix = var.db_security_grp_name
  vpc_id      = aws_vpc.vpc_1.id
  tags = {
    Name = "${var.db_security_grp_name}"
  }
}
resource "aws_key_pair" "app_key_pair" {
  key_name   = var.keypair_name
  public_key = file(var.keypair_path)
}

# resource "aws_ebs_volume" "ebs_vol" {
#   availability_zone = "${var.aws_region}${var.availability_zones[0]}"
#   size              = var.ebs_vol_size
#   type              = var.ebs_vol_type
#   tags = {
#     Name = var.ebs_vol_name
#   }
# }

# resource "aws_eip" "elastic_ip" {
#   instance = aws_instance.webapp_ec2.id
#   vpc      = true
# }

resource "aws_route53_record" "srikanthchilaka_A_record" {
  zone_id = var.aws_profile == "dev" ? var.dev_hostedzone_id : var.prod_hostedzone_id
  name    = var.aws_profile == "dev" ? var.dev_A_record_name : var.prod_A_record_name
  type    = "A"
  # ttl     = 60
  # records = [aws_eip.elastic_ip.public_ip]
  alias {
    name                   = aws_lb.webapp_lb.dns_name
    zone_id                = aws_lb.webapp_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  name = "EC2-CSYE6225-Instance-Profile"
  role = aws_iam_role.s3_access_role.name
}

resource "aws_iam_policy" "WebAppCloudWatch" {
  name        = "WebAppCloudWatch"
  description = "Allows EC2 instances to access CloudWatch"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:PutMetricData",
            "ec2:DescribeTags",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter",
            "ssm:PutParameter"
          ],
          "Resource" : "arn:aws:ssm:::parameter/AmazonCloudWatch-*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  policy_arn = aws_iam_policy.WebAppCloudWatch.arn
  role       = aws_iam_role.s3_access_role.name
}

data "aws_acm_certificate" "acm_cert" {
  domain   = var.prod_A_record_name
  statuses = ["ISSUED"]
}

resource "aws_lb" "webapp_lb" {
  name               = "web-application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets_1 : subnet.id]

  # enable_deletion_protection = true

  tags = {
    Environment = "development"
  }
}

resource "aws_security_group" "lb_sg" {
  name_prefix = "load_balancer_security_group"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.vpc_1.id
  ingress {
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = "tcp"
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = "tcp"
    cidr_blocks = [var.rt_cidr]
  }
  egress {
    from_port   = var.ports[3]
    to_port     = var.ports[3]
    protocol    = "tcp"
    cidr_blocks = [var.rt_cidr]
  }
  tags = {
    Name = "load_balancer_security_group"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "tf-lb-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_1.id
  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
  tags = {
    Name = "tf-lb-tg"
  }
}

# resource "aws_lb_target_group_attachment" "attacht" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id        = aws_instance.webapp_ec2.id
#   port             = 3000
# }
resource "aws_lb_listener" "web_tgl" {
  load_balancer_arn = aws_lb.webapp_lb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_lb_target_group.web_tg.arn
    type             = "forward"
  }
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.acm_cert.arn}"
}

resource "aws_kms_key" "ebs_encryption_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable EBS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "rds_encryption_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable EBS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_autoscaling_group" "webapp_asg" {
  name                      = "webapp_asg"
  health_check_grace_period = 1200
  launch_template {
    id      = aws_launch_template.webapp_asg_launch_template.id
    version = "$Latest"
  }
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public_subnets_1[0].id, aws_subnet.public_subnets_1[1].id, aws_subnet.public_subnets_1[2].id]
  health_check_type   = "EC2"
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "scale_up_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.webapp_asg.name
  scaling_adjustment      = 1
  cooldown                = 60
  metric_aggregation_type = "Average"
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "scale_down_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.webapp_asg.name
  scaling_adjustment      = -1
  cooldown                = 60
  metric_aggregation_type = "Average"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  alarm_description   = "scaleupalarm"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  treat_missing_data  = "notBreaching"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.webapp_asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  alarm_description   = "scaledownalarm"
  evaluation_periods  = "2"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "2"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.webapp_asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}

resource "aws_launch_template" "webapp_asg_launch_template" {
  name          = "webapp_asg_launch_template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.app_key_pair.key_name
  # disable_api_termination = false
  # ebs_optimized           = false
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.ebs_vol_size
      volume_type           = var.ebs_vol_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs_encryption_key.arn
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interfaces {
    associate_public_ip_address = true
    # subnet_id                   = aws_subnet.public_subnets_1[0].id
    security_groups = [aws_security_group.application.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.s3_access_instance_profile.name
  }

  # tags = {
  #   Name = var.ec2_name
  # }
  user_data = base64encode(<<-EOF
#!/bin/bash
cat <<EOT > /etc/systemd/system/webapp.service
[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="NODE_ENV=dev"
Environment="DB_PORT=3306"
Environment="DB_DIALECT=mysql"
Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
Environment="DB_USERNAME=${aws_db_instance.rds_instance.username}"
Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
Environment="DB_NAME=${aws_db_instance.rds_instance.db_name}"
Environment="AWS_BUCKET_NAME=${aws_s3_bucket.webapp_s3_bucket.bucket}"
Environment="AWS_REGION=${var.aws_region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node listener.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json
echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc,
echo 'export PORT=3000' >> /home/ec2-user/.bashrc,
echo 'export DB_DIALECT=mysql' >> /home/ec2-user/.bashrc,
echo 'export DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc,
echo 'export DB_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc,
echo 'export DB_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc,
echo 'export DB_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc,
echo 'export AWS_BUCKET_NAME=${aws_s3_bucket.webapp_s3_bucket.bucket}' >> /home/ec2-user/.bashrc,
echo 'export AWS_REGION=${var.aws_region}' >> /home/ec2-user/.bashrc,
source /home/ec2-user/.bashrc
EOF
  )
}