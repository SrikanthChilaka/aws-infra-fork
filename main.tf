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
  # acl    = "private"
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
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

resource "aws_security_group_rule" "ec2_ingress" {
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
    from_port   = var.ports[3]
    to_port     = var.ports[3]
    protocol    = "tcp"
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = "tcp"
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[0]
    to_port     = var.ports[0]
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

resource "aws_instance" "webapp_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnets_1[0].id
  vpc_security_group_ids      = [aws_security_group.application.id]
  key_name                    = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = aws_iam_instance_profile.s3_access_instance_profile.name
  root_block_device {
    volume_size           = var.ebs_vol_size
    volume_type           = var.ebs_vol_type
    delete_on_termination = true
  }
  disable_api_termination = false

  tags = {
    Name = var.ec2_name
  }
  user_data = <<EOT
#!/bin/bash
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="NODE_ENV=dev"
Environment="DATABASE_PORT=3306"
Environment="DATABASE_DIALECT=mysql"
Environment="DATABASE_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
Environment="DATABASE_USER=${aws_db_instance.rds_instance.username}"
Environment="DATABASE_PASSWORD=${aws_db_instance.rds_instance.password}"
Environment="DATABASE=${aws_db_instance.rds_instance.db_name}"
Environment="AWS_BUCKET_NAME=${aws_s3_bucket.webapp_s3_bucket.bucket}"
Environment="AWS_REGION=${var.aws_region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node listener.js
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
EOF


sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service

echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc,
echo 'export PORT=3000' >> /home/ec2-user/.bashrc,
echo 'export DATABASE_DIALECT=mysql' >> /home/ec2-user/.bashrc,
echo 'export DATABASE_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc,
echo 'export DATABASE_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc,
echo 'export DATABASE_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc,
echo 'export DATABASE_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc,
echo 'export AWS_BUCKET_NAME=${aws_s3_bucket.webapp_s3_bucket.bucket}' >> /home/ec2-user/.bashrc,
echo 'export AWS_REGION=${var.aws_region}' >> /home/ec2-user/.bashrc,
source /home/ec2-user/.bashrc
EOT

}