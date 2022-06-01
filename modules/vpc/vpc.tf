module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "~> 3.0"
  name                   = "terraform-vpc"
  cidr                   = var.cidr
  azs                    = var.azs
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
}

resource "aws_security_group" "default_ssh_sg" {
  name        = "terraform-ssh-sg"
  description = "Enables SSH/RDP traffic from my IP"
  vpc_id      = module.vpc.vpc_id
  ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["67.168.24.180/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    },
    {
      description      = "RDP"
      from_port        = 3389
      to_port          = 3389
      protocol         = "tcp"
      cidr_blocks      = ["67.168.24.180/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]
  egress = [
    {
      description      = "All traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]
}

resource "aws_cloudwatch_log_group" "vpc_cloudwatch_log_group" {
  name              = "terraform-vpc-cloudwatch-log-group"
  retention_in_days = 365
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "terraform-vpc-flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "terraform-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination = aws_cloudwatch_log_group.vpc_cloudwatch_log_group.arn
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}