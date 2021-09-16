terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
  access_key = var.ac_key
  secret_key = var.sc_key
}

/* ------------------------------ SSH ------------------------------ */


resource "aws_key_pair" "ssh-key" {
  key_name = "ssh-key"
  public_key = file(var.pub-key-path)

  tags = {
    name = "SSH Key for DigitalCheckList Instances"
    project = var.project
  }
}

/* ------------------------------ Data search ------------------------------ */

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_ami" "nat-router" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}

/* ------------------------------ VMS ------------------------------ */

/* ------------------------------ NAT ------------------------------ */

resource "aws_network_interface" "nat-router-interface" {
  subnet_id = aws_subnet.DigitalCheckList-Public-Subnet.id
  source_dest_check = false
  security_groups = [aws_security_group.nat-router-sg.id]
  tags = {
    name = "NAT Router Interface for DigitalCheckList"
    project = var.project
  }
}

resource "aws_instance" "nat-router" {
  availability_zone = data.aws_availability_zones.available.names[0]
  ami = data.aws_ami.nat-router.id
  instance_type = var.nat-router-instance
  key_name = aws_key_pair.ssh-key.key_name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nat-router-interface.id
  }

  tags = {
    name = "NAT Router for Public Subnet"
    project = var.project
  }
}

/* ------------------------------ App Servers ------------------------------ */

resource "aws_instance" "app-server-1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance
  subnet_id = aws_subnet.DigitalCheckList-Private-Subnet.id
  key_name = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.DigitalCheckList-Private-SG.id]

  depends_on = [aws_instance.mongodb-server, aws_security_group.DigitalCheckList-Private-SG, aws_instance.nat-router]

  user_data = templatefile("startups/diglist_install.sh.tpl", {
    INITIAL_USERNAME = var.db_user
    INITIAL_EMAIL = var.db_mail
    INITIAL_PASSWORD =var.mongodb_password
    NODE_ENV = var.nd_env
    JWT = var.token
    PORT = var.wport
    MONGO_URI = local.mongo_ip
    INITIAL_IP = var.sip
  })

  tags = {
    name = "App Server #1 for DigitalCheckList"
    project = var.project
  }
}

resource "aws_instance" "app-server-2" {
  availability_zone = data.aws_availability_zones.available.names[0]
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance
  subnet_id = aws_subnet.DigitalCheckList-Private-Subnet.id
  key_name = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.DigitalCheckList-Private-SG.id]

  depends_on = [aws_instance.mongodb-server, aws_security_group.DigitalCheckList-Private-SG, aws_instance.nat-router]

  user_data = templatefile("startups/diglist_install.sh.tpl", {
    INITIAL_USERNAME = var.db_user
    INITIAL_EMAIL = var.db_mail
    INITIAL_PASSWORD =var.mongodb_password
    NODE_ENV = var.nd_env
    JWT = var.token
    PORT = var.wport
    MONGO_URI = local.mongo_ip
    INITIAL_IP = var.sip
  })

  tags = {
    name = "App Server #2 for DigitalCheckList"
    project = var.project
  }
}

/* ------------------------------ Database Server ------------------------------ */

resource "aws_instance" "mongodb-server" {
  availability_zone = data.aws_availability_zones.available.names[0]
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance
  subnet_id = aws_subnet.DigitalCheckList-Private-Subnet.id
  key_name = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.DigitalCheckList-Private-SG.id]
  depends_on = [aws_instance.nat-router]

  user_data = file("startups/db_startup.sh")

  tags = {
    name = "Database for DigitalCheckList"
    project = var.project
  }
}

/* ------------------------------ Load Balancer Server ------------------------------ */

resource "aws_instance" "nginx-load-balancer-server" {
  availability_zone = data.aws_availability_zones.available.names[0]
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance
  subnet_id = aws_subnet.DigitalCheckList-Public-Subnet.id
  key_name = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.DigitalCheckList-Public-SG.id]
  user_data = templatefile("startups/nginx_startup.sh.tpl", {
    FIRST_APP_SERVER = aws_instance.app-server-1.private_ip
    SECOND_APP_SERVER = aws_instance.app-server-2.private_ip
    DB_SERVER = aws_instance.mongodb-server.private_ip
  })

  depends_on = [aws_security_group.DigitalCheckList-Public-SG]

  provisioner "file" {
    source = var.prv-key-path
    destination = "/home/ubuntu/.ssh/id_rsa"
    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key =file(var.prv-key-path)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa"
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key =file(var.prv-key-path)
    }
  }

  provisioner "file" {
    source      = "confs/nginx.conf"
    destination = "/home/ubuntu/nginx.conf"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file(var.prv-key-path)
    }

  }

  tags = {
    name = "Load Balancer for DigitalCheckList"
    project = var.project
  }

}

resource "local_file" "load_balancer_config" {
  content = templatefile("confs/nginx.conf.template", {
    FIRST_APP_SERVER = aws_instance.app-server-1.private_ip
    SECOND_APP_SERVER = aws_instance.app-server-2.private_ip
  })
  filename = "confs/nginx.conf"
}