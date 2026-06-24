
# ────────────────────────────────────────────
# 1. VPC（虚拟私有网络）
# ────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}

# ────────────────────────────────────────────
# 2. 子网（2 个公有子网，2 个私有子网）
# ────────────────────────────────────────────
data "aws_availability_zones" "available" {
  state = "available"
}

# 公有子网（放 Web 服务器、负载均衡）
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true   # 自动分配公网 IP

  tags = {
    Name = "${var.project}-${var.env}-public-${count.index}"
  }
}

# 私有子网（放数据库、内部服务）
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project}-${var.env}-private-${count.index}"
  }
}

# ────────────────────────────────────────────
# 3. 互联网网关（让 VPC 能访问公网）
# ────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

# ────────────────────────────────────────────
# 4. 路由表（公有子网连 IGW，私有子网连 NAT）
# ────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.env}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ────────────────────────────────────────────
# 5. 安全组（防火墙规则）
# ────────────────────────────────────────────

# Web 服务器安全组（开放 80 和 443）
resource "aws_security_group" "web" {
  name        = "${var.project}-${var.env}-web-sg"
  description = "Allow HTTP/HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "${var.project}-${var.env}-web-sg"
  }
}

# 数据库安全组（只允许来自 Web 安全组的流量）
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.env}-db-sg"
  description = "Allow DB access from web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]   # 只放行 Web 安全组的流量
  }

  tags = {
    Name = "${var.project}-${var.env}-db-sg"
  }
}

# ────────────────────────────────────────────
# 6. EC2 实例（Web 服务器）
# ────────────────────────────────────────────

# 查找最新的 Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_key_pair" "web" {
  key_name   = "${var.project}-${var.env}-web-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name = "${var.project}-${var.env}-web-key"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name               = aws_key_pair.web.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd mariadb105
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project}-${var.env}-web-server"
  }
}

# ────────────────────────────────────────────
# 7. RDS 数据库（MySQL）
# ────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project}-${var.env}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.env}-mysql"

  engine         = "mysql"
  engine_version = "8.0.46"
  instance_class = "db.t3.micro"

  db_name  = "appdb"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  skip_final_snapshot  = true       # 学习环境跳过快照
  publicly_accessible  = false      # 不开放公网访问
  allocated_storage    = 20

  tags = {
    Name = "${var.project}-${var.env}-mysql"
  }
}