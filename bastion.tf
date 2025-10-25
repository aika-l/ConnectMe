data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu22.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public["a"].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name
  associate_public_ip_address = true
  tags = merge(local.tags, { Name = "${var.project_name}-bastion" })
}