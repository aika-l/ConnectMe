# Subnet group for RDS (private DB subnets)
resource "aws_db_subnet_group" "db" {
    name        = lower("${var.project_name}-db-subnets")
    subnet_ids  = [for s in aws_subnet.db : s.id]
    tags        = merge(local.tags, { Name = "${var.project_name}-db-subnets"})
}

# MySQL instance (Multi-AZ true to mirror the diagram)
resource "aws_db_instance" "mysql" {
    identifier             = lower("${var.project_name}-mysql")
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = var.db_instance_class
    db_subnet_group_name    = aws_db_subnet_group.db.name
    vpc_security_group_ids  = [aws_security_group.rds.id]
    allocated_storage       = var.db_allocated_storage
    storage_type            = "gp3"
    multi_az                = true
    username                = var.db_username 
    password                = var.db_password
    db_name                 = "connectwithme"
    skip_final_snapshot     = true
    deletion_protection     = false
    publicly_accessible     = false
    backup_retention_period = 5
    copy_tags_to_snapshot   = true
    auto_minor_version_upgrade  = true
    tags = merge(local.tags, { Name = "${var.project_name}-rds" })
}