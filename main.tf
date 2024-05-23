provider "aws" {
  region = "ap-south-1"
}

variable "cidr" {
  default = "10.0.0.0/16"
}

resource "aws_vpc" "myVpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.myVpc.id
  cidr_block = "10.0.0.0/24" 
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.myVpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "sg" {
  name = "web-sg"
  vpc_id = aws_vpc.myVpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo_instance" {
  ami = ""
  subnet_id = aws_subnet.sub1.id
  instance_type = "t2.micro"
  key_name = "sahith"
  vpc_security_group_ids = [aws_security_group.sg.id]

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/sahith.pem")
    host = self.public_ip
  }

  provisioner "file" {
    source = "app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [ 
        "echo 'Hello from the remote instance'",
        "sudo apt update",
        "sudo apt install -y python3-pip",
        "cd /home/ubuntu/ &&",
        "sudo pip3 install flask",
        "sudo python3 app.py"
     ]
  }
}