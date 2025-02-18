resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
 
resource "aws_subnet" "subnet-public" {
  count                 = length(var.public_subnet_cidrs)
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.public_subnet_cidrs[count.index]
  availability_zone     = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-${count.index + 1}"
  }
}
 
resource "aws_subnet" "subnet-private" {
  count                 = length(var.private_subnet_cidrs)
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.private_subnet_cidrs[count.index]
  availability_zone     = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-private-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-internet-gateway"
  } 
} 

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-route-table"
  }
}
  
resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gateway.id
}
 
resource "aws_route_table_association" "route-table-association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.subnet-public[count.index].id
  route_table_id = aws_route_table.route-table.id
}
  
resource "aws_security_group" "security-group-master" {
  name        = "${var.project_name}-security-group-master"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.vpc.id
 
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 
resource "aws_security_group" "security-group-nodes" {
  name        = "${var.project_name}-security-group-nodes"
  description = "Allow traffic from load balancer only"
  vpc_id      = aws_vpc.vpc.id
 
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "TCP"
  #   security_groups = [aws_security_group.security-group-lb.id]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 
 
  
resource "aws_instance" "master-node" {
  instance_type          = "c5a.2xlarge"
  ami                    = data.aws_ami.ubuntu-ami.id
  key_name               = data.aws_key_pair.auth-key.key_name 
  vpc_security_group_ids = [aws_security_group.security-group-master.id]
  subnet_id              = aws_subnet.subnet-public[0].id
  
  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "${var.project_name}-master-node"
  }

  user_data = join( "\n", [
    file("/scripts/createuser.sh"),
    file("/scripts/setup_containerd.sh"), 
    file("/scripts/setup_k8s.sh"),  
    file("/scripts/setup_control_plane.sh"),  
    file("/scripts/setup_control_plane_nginx.sh"),  
    file("/scripts/cleanup.sh"), 
  ]
  ) 
  provisioner "local-exec" {
    command = templatefile("/scripts/${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user = "root",
      identityFile = "~/.ssh/${var.key_name}"
    })
    interpreter = var.host_os == "windows" ? [ "Powershell", "-Command" ] : [ "bash", "-c" ]
  } 
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "worker-node" {
  count = 2
  instance_type          = "t2.micro" 
  ami                    = data.aws_ami.ubuntu-ami.id
  key_name               = data.aws_key_pair.auth-key.key_name 
  vpc_security_group_ids = [aws_security_group.security-group-nodes.id]
  subnet_id              = aws_subnet.subnet-public[count.index].id
  
  # root_block_device {
  #   volume_size = 10
  # } 
  tags = {
    Name = "${var.project_name}-worker-node-${count.index + 1}"
  }

  user_data = join( "\n", [ 
    file("/scripts/createuser.sh"),
    file("/scripts/setup_containerd.sh"), 
    file("/scripts/setup_k8s.sh"),  
    "CONTROL_PLANE_IP=${data.aws_instance.master_node.public_ip}",
    "NODE_INDEX=${count.index + 1}",
    file("/scripts/setup_worker_nodes.sh"), 
    file("/scripts/cleanup.sh"), 
  ]
  ) 
  provisioner "local-exec" {
    command = templatefile("/scripts/${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user = "root",
      identityFile = "~/.ssh/${var.key_name}"
    })
    interpreter = var.host_os == "windows" ? [ "Powershell", "-Command" ] : [ "bash", "-c" ]
  } 
  lifecycle {
    create_before_destroy = true
  }
}
 
resource "aws_security_group" "security-group-lb" {
  name        = "${var.project_name}-security-group-lb"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.vpc.id
 
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 
resource "aws_lb_target_group" "target-group" {
  name     = "${var.project_name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id 
}
resource "aws_lb_target_group_attachment" "target-group-attachment" {   
  for_each = {
    for k, v in aws_instance.worker-node :
    k => v
  }
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = each.value.id
  port             = 80 
}

resource "aws_lb" "loadbalancer" {
  name               = "${var.project_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  
  security_groups    = [aws_security_group.security-group-lb.id] 
  subnets            = [for subnet in aws_subnet.subnet-public : subnet.id]
  enable_deletion_protection = false 
}

resource "aws_lb_listener" "loadbalancer-listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP" 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
} 