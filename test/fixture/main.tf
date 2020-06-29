terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.52.0"
  region  = var.region
}

resource "random_string" "test_token" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "tls_private_key" "test_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "test_key" {
  key_name   = "armor-eks-ami-test-key-${random_string.test_token.result}"
  public_key = tls_private_key.test_key.public_key_openssh
}

#
# On ingress is required since AWS SSM will be used
# to access the instance for manual tests.
#
resource "aws_security_group" "allow_egress_only" {
  name        = "allow_all_egress"
  description = "Allow egress traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "All_All_Egress_${random_string.test_token.result}"
  }
}

resource "aws_iam_role" "role" {
  name               = "armor-eks-ami-test-role-${random_string.test_token.result}"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_attaachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  name = "armor-eks-ami-test-profile-${random_string.test_token.result}"
  role = aws_iam_role.role.name
}

resource "aws_instance" "inst" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.test_key.key_name
  vpc_security_group_ids      = [aws_security_group.allow_egress_only.id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.profile.id

  tags = {
    Name = "armor-eks-ami-test-${random_string.test_token.result}"
  }
}