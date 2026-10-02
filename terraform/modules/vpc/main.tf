# ============================================================
# 1. PROJECT VPC NETWORKING SECTION
# ============================================================

resource "aws_vpc" "my_vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

# ============================================================
# 2. INTERNET GATEWAY 
# ============================================================


resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.my_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

# ============================================================
# 3. PUBLIC SUBNETS
# ============================================================
resource "aws_subnet" "public" {

  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                     = "${local.name_prefix}-public-${count.index + 1}"
      Tier                     = "Public"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# ============================================================
# 4. PRIVATE SUBNETS
# ============================================================

resource "aws_subnet" "private_app" {

  count = length(var.private_app_subnet_cidrs)

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-app-${count.index + 1}"
      Tier = "Application"
    }
  )
}

# ============================================================
# 5. PRIVATE SUBNETS FOR DATABASE
# ============================================================

resource "aws_subnet" "private_db" {

  count = length(var.private_db_subnet_cidrs)

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-db-${count.index + 1}"
      Tier = "Database"
    }
  )
}

# ============================================================
# 6. ELASTIC IP FOR NAT GATEWAY
# ============================================================
resource "aws_eip" "nat" {

  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip"
    }
  )
}

# ============================================================
# 7. NAT GATEWAY
# ============================================================
resource "aws_nat_gateway" "nat" {

  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat"
    }
  )
}

# ============================================================
# 8. PUBLIC ROUTE TABLE
# ============================================================
resource "aws_route_table" "public" {

  vpc_id = aws_vpc.my_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

# ============================================================
# 9. PRIVATE ROUTE TABLE FOR APPLICATION SUBNETS
# ============================================================
resource "aws_route_table" "private_app" {

  vpc_id = aws_vpc.my_vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-app-rt"
    }
  )
}

# ============================================================
# 10. PRIVATE ROUTE TABLE FOR DATABASE SUBNETS
# ============================================================
resource "aws_route_table" "private_db" {

  vpc_id = aws_vpc.my_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-db-rt"
    }
  )
}

# ============================================================
# 11. ASSOCIATION OF PUBLIC SUBNETS WITH PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table_association" "public" {

  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# 12. ASSOCIATION OF PRIVATE SUBNETS WITH PRIVATE ROUTE TABLE FOR APPLICATION SUBNETS
# ============================================================
resource "aws_route_table_association" "private_app" {

  count = length(aws_subnet.private_app)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# ============================================================
# 13. ASSOCIATION OF PRIVATE SUBNETS WITH PRIVATE ROUTE TABLE FOR DATABASE SUBNETS
# ============================================================
resource "aws_route_table_association" "private_db" {

  count = length(aws_subnet.private_db)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}


