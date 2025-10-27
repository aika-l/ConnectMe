output "alb_dns_name" {
    value       =  aws_lb.public.dns_name 
    description =  "Public ALB DNS"
}

output "bastion_public_ip" {
    value       = aws_instance.bastion.public_ip 
    description = "Bastion public IP"
} 

output "rds_endpoint" {
    value       = aws_db_instance.mysql.address 
    description = "RDS MySQL endpoint" 
}

output "vpc_id" {
    value = aws_vpc.main.id
}