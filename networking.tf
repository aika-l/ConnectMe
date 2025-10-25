resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = merge(local.tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_nternet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags   = merge(local.tags, { Name = "${var.project_name}-igw" })
}

# Public subnets (web tier: ALB + bastion + NAT)
resource "aws_subnet" "public" {
  for_each = {
    a = { cidr = var.public_subnet_cidrs[0], az = var.azs[0] }
    b = { cidr = var.public_subnet_cidrs[1], az = var.azs[1] }
  }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "web"
  })
}

# Private subnets (application tier)
resource "aws_subnet" "app" {
  for_each = {
    a = { cidr = var.app_subnet_cidrs[0], az = var.azs[0] }
    b = { cidr = var.app_subnet_cidrs[1], az = var.azs[1] }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(local.tags, {
    Name = "${var.project_name}-app-${each.key}"
    Tier = "app"
  })
}

# Private subnets (DB tier)
resource "aws_subnet" "db" {
  for_each = {
    a = { cidr = var.db_subnet_cidrs[0], az = var.azs[0] }
    b = { cidr = var.db_subnet_cidrs[1], az = var.azs[1] }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(local.tags, {
    Name = "${var.project_name}-db-${each.key}"
    Tier = "db"
  })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.project_name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT per AZ (as per diagram)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(local.tags, { Name = "${var.project_name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = merge(local.tags, { Name = "${var.project_name}-nat-${each.key}" })
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "app" {
  for_each = aws_nat_gateway.nat
  vpc_id   = aws_vpc.main.id
  tags     = merge(local.tags, { Name = "${var.project_name}-app-rt-${each.key}" })
}

resource "aws_route" "app_default" {
  for_each               = aws_route_table.app
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "app_assoc" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

# DB subnets: usually no direct internet; allow via NAT for patching.
resource "aws_route_table" "db" {
  for_each = aws_nat_gateway.nat
  vpc_id   = aws_vpc.main.id
  tags     = merge(local.tags, { Name = "${var.project_name}-db-rt-${each.key}" })
}

resource "aws_route" "db_default" {
  for_each               = aws_route_table.db
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "db_assoc" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}