data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deployer" {
  key_name   = "cicd-typescript-key"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "app_server" {
  name        = "cicd-typescript-sg"
  description = "Allow SSH access to the application server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "Allow all outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "K3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }
  ingress {
    description = "kubelet communication API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }
  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "ICMP between nodes"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self        = true
  }
  tags = {
    Name = "cicd-typescript-sg"
  }
}

resource "aws_instance" "k3s_nodes" {
  for_each = var.k3s_nodes

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.app_server.id]
  associate_public_ip_address = true

  tags = {
    Name    = each.key
    Role    = each.value.role
    Project = "cicd-typescript"
  }
}
