# 1. Criação da VPC
resource "aws_vpc" "fiapx_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "fiapx-vpc" }
}

# 2. Internet Gateway (Para dar saída para a rua)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.fiapx_vpc.id
}

# 3. Subnets (Precisamos de pelo menos 2 em zonas diferentes para o RDS/MQ)
resource "aws_subnet" "pub_a" {
  vpc_id            = aws_vpc.fiapx_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fiapx-pub-a"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/fiapx-cluster-${random_id.id.hex}" = "shared"
  }
}

resource "aws_subnet" "pub_b" {
  vpc_id            = aws_vpc.fiapx_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "fiapx-pub-b"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/fiapx-cluster-${random_id.id.hex}" = "shared"
  }
}

# 4. Tabela de Roteamento
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.fiapx_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_elasticache_subnet_group" "redis_net" {
  name       = "fiapx-redis-net-${random_id.id.hex}"
  subnet_ids = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]
}