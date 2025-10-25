locals {
  tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform" 
  }
}
