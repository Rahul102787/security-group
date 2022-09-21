locals {
  vpc_name = "${var.name_prefix}-vpc"
}

data "aws_availability_zones" "available" {
  state = "available"

  # Exclude Local Zones (Los Angeles, Atlanta, Boston, etc.)
  filter {
    name = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.vpc_name}"
  }
}

resource "aws_default_route_table" "vpc" {
  default_route_table_id = aws_vpc.vpc.main_route_table_id

  tags = {
    Name = "${var.name_prefix}-vpc-main-route-table"
  }
}

resource "aws_subnet" "public" {
  count             = var.az_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index + var.az_count + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.name_prefix}-vpc-public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    EntityType = "public:subnet"
    VpcName    = local.vpc_name
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.name_prefix}-vpc-private-subnet-${data.aws_availability_zones.available.names[count.index]}"
    EntityType = "private:subnet"
    VpcName    = local.vpc_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix}-vpc-igw"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_eip" "gw" {
  count = var.az_count
  vpc   = true

  tags = {
    EntityType = "public:ein"
    Name       = "${var.name_prefix}-vpc-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "gw" {
  count = var.az_count

  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)

  tags = {
    EntityType = "public:nat-gw"
    Name = "${var.name_prefix}-vpc-nat-gw-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table" "public" {
  count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    EntityType = "public:route_table"
    Name = "${var.name_prefix}-vpc-public-route-table-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

  tags = {
    EntityType = "private:route_table"
    Name = "${var.name_prefix}-vpc-private-route-table-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "vpc" {
  name        = "${var.name_prefix}-vpc-sg"
  description = "VPC Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    self = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    self = true
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-sg"
    EntityType = "vpc:sg"
    VpcName    = local.vpc_name
  }
}

resource "aws_security_group" "https" {
  name        = "${var.name_prefix}-vpc-https-sg"
  description = "HTTPS Traffic Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-https-sg"
    EntityType = "vpc:https:sg"
    VpcName    = local.vpc_name
  }
}

resource "aws_security_group" "http" {
  name        = "${var.name_prefix}-vpc-http-sg"
  description = "HTTP Traffic Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-http-sg"
    EntityType = "vpc:http:sg"
    VpcName    = local.vpc_name
  }
}

############### Adding new 4 SG ######################

resource "aws_security_group" "dev" {
  name        = "${var.name_prefix}-vpc-dev-sg"
  description = "This Security Group will use for DEV EC2 environment"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-dev-sg"
    EntityType = "vpc:dev:sg"
    VpcName    = local.vpc_name
  }
}

resource "aws_security_group" "dev-rds" {
  name        = "${var.name_prefix}-vpc-dev-rds-sg"
  description = "This Security Group will use for DEV RDS environment"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.dev.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-dev-rds-sg"
    EntityType = "vpc:dev-rds:sg"
    VpcName    = local.vpc_name
  }
}

resource "aws_security_group" "global" {
  name        = "${var.name_prefix}-vpc-global-sg"
  description = "This Security Group will use for GLOBAL EC2 environment"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-global-sg"
    EntityType = "vpc:global:sg"
    VpcName    = local.vpc_name
  }
}

resource "aws_security_group" "global-rds" {
  name        = "${var.name_prefix}-vpc-global-rds-sg"
  description = "This Security Group will use for GLOBAL RDS environment"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.global.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.name_prefix}-vpc-global-rds-sg"
    EntityType = "vpc:global-rds:sg"
    VpcName    = local.vpc_name
  }
}
