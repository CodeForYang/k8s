# modules/app/main.tf
# 定义一个"应用"模块：安全组 + EC2 实例 + 负载均衡
# 不同环境通过传递不同参数来复用这个模板

# ────────────────────────────────────────────
# 1. 安全组：允许 HTTP（80）入站
# ────────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.env}-web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-web-sg"
    Environment = var.env
  }
}

# ────────────────────────────────────────────
# 2. 应用负载均衡（ALB）
# ────────────────────────────────────────────
resource "aws_lb" "app" {
  name               = "${var.env}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.env}-app-alb"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.env}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
  }

  tags = {
    Name        = "${var.env}-app-tg"
    Environment = var.env
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ────────────────────────────────────────────
# 3. EC2 实例（数量由 replicas 控制）
# ────────────────────────────────────────────
resource "aws_instance" "web" {
  # count 控制创建几台：dev 传 1 台，prod 传 5 台
  count = var.replicas

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # 放到公有子网，并关联安全组
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true

  # 启动时安装 HTTP 服务
  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "Hello from ${var.env} environment (instance ${count.index + 1})" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.env}-web-${count.index + 1}"
    Environment = var.env
  }
}

# 把 EC2 注册到目标组（ALB 才能把流量转发过来）
resource "aws_lb_target_group_attachment" "web" {
  count            = var.replicas
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# 获取最新的 Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}