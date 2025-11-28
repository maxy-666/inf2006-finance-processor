resource "aws_db_instance" "example" {
  identifier             = "inf2006proj"
  
  # Engine Configuration
  engine                 = "mysql"
  engine_version         = "8.0.43"
  instance_class         = "db.t3.micro"
  
  # Storage
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted      = true
  
  # Database Credentials
  db_name                = "users"
  username               = "admin"
  password               = "INF2006Year2Tri1" 
  
  # Network & Access
  publicly_accessible    = true
  skip_final_snapshot    = true 
  vpc_security_group_ids = ["sg-0e71643aa5d853f25"] 
  availability_zone      = "us-east-1a"

  # Backups
  backup_retention_period = 1
  delete_automated_backups = true
  
  tags = {
    Project = "INF2006-Financial-Processor"
  }
}