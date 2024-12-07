# Variables
variable "region" {
  default = "us-east-1"
}

variable "db_name" {
  default = "exampledb"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "password123" # This should not be hard-coded in production
}

# Provider Configuration
provider "aws" {
  region = var.region
}

# Create a Secrets Manager secret for the database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "rds_db_credentials"
  description = "Credentials for the RDS database"

  tags = {
    Name = "RDS_DB_Credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# Create an RDS Subnet Group
resource "aws_db_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = ["subnet-xxxxxx", "subnet-yyyyyy"] # Replace with your Subnet IDs

  tags = {
    Name = "Example DB Subnet Group"
  }
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow RDS traffic"
  vpc_id      = "vpc-xxxxxx" # Replace with your VPC ID

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with restricted CIDR ranges in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an RDS instance
resource "aws_db_instance" "example" {
  identifier              = "example-rds-instance"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = var.db_name # Corrected here
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.example.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true

  tags = {
    Name = "Example RDS Instance"
  }
}


output "db_instance_endpoint" {
  value = aws_db_instance.example.endpoint
}

output "secrets_manager_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}
