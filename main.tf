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

resource "random_id" "random_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "csye6225-${var.aws_profile}-${random_id.random_bucket_suffix.hex}"
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
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id
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

resource "aws_iam_instance_profile" "s3_access_instance_profile" {
  name = var.s3_iam_pro
  role = aws_iam_role.s3_access_role.name

  tags = {
    Terraform = "true"
  }
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
          "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"
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

resource "aws_db_instance" "rds_instance" {
  identifier           = var.db_username
  allocated_storage    = 20
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.instance_class
  db_name              = var.db_username
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = aws_db_parameter_group.parameter_group.name
  vpc_security_group_ids = [
    aws_security_group.db_security_group.id
  ]
  skip_final_snapshot = true
  multi_az            = false
  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.my_subnet_group.name

}

resource "aws_db_parameter_group" "parameter_group" {
  name_prefix = "${var.aws_profile}-rds-db-parameter-group"
  family      = "${var.db_engine}-${var.db_engine_version}"
  description = "Custom parameter group for ${var.db_engine}"
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

resource "aws_security_group" "application_sec_grp" {
  name_prefix = var.security_grp_name
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port   = var.ports[0]
    to_port     = var.ports[0]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[3]
    to_port     = var.ports[3]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  egress {
    from_port = var.ports[5]
    to_port   = var.ports[5]
    protocol  = var.protocol
  }
  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = var.e_protocol
    cidr_blocks = [var.rt_cidr]
  }
}

resource "aws_security_group" "db_security_group" {
  name_prefix = var.db_security_grp_name
  vpc_id      = aws_vpc.vpc_1.id
  tags = {
    Name = "${var.db_security_grp_name}"
  }
}

# Add an inbound rule to the RDS security group to allow traffic from the EC2 security group
resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = var.protocol
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.application_sec_grp.id
}
# Add an outbound rule to the RDS security group to allow traffic from the EC2 security group
resource "aws_security_group_rule" "rds_egress" {
  type                     = "egress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = var.protocol
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.application_sec_grp.id
}

# Add an inbound rule to the EC2 security group to allow traffic to the RDS security group
resource "aws_security_group_rule" "ec2_ingress" {
  type                     = "ingress"
  from_port                = var.ports[5]
  to_port                  = var.ports[5]
  protocol                 = var.protocol
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.application_sec_grp.id
}

resource "aws_db_subnet_group" "my_subnet_group" {
  name        = "my-subnet-group"
  description = "My subnet group for RDS instance"

  subnet_ids = [aws_subnet.private_subnets_1[0].id, aws_subnet.private_subnets_1[1].id, aws_subnet.private_subnets_1[2].id]
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

resource "aws_instance" "prod_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnets_1[0].id
  vpc_security_group_ids      = [aws_security_group.application_sec_grp.id]
  key_name                    = aws_key_pair.app_key_pair.key_name
  disable_api_termination     = false
  ebs_optimized               = false
  associate_public_ip_address = true
  root_block_device {
    volume_size           = var.ebs_vol_size
    volume_type           = var.ebs_vol_type
    delete_on_termination = true
  }
  iam_instance_profile = aws_iam_instance_profile.s3_access_instance_profile.name
  tags = {
    Name = var.ec2_name
  }

  user_data = <<EOF
#!/bin/bash
echo "[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
Environment="DB_USER=${aws_db_instance.rds_instance.username}"
Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
Environment="DB_DATABASE=${aws_db_instance.rds_instance.db_name}"
Environment="AWS_BUCKET_NAME=${aws_s3_bucket.s3_bucket.bucket}"
Environment="AWS_REGION=${var.aws_region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service
EOF
}