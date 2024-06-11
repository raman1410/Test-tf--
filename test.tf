provider "aws"{
    region = "us-east-1"
}      

resource "aws_default_vpc" "deafult" {

}


resource "AWS_security_group" "my_sg"{
    name = "my_security_group"

    vpc_id = aws_default_vpc.default.id
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
    }
    egress {
        from_port=0
        to_port = 0
        protocol = -1
    }
    tags ={
        name = "my_server_sg"
    }
resource "aws_security_group" "elb_sg"{
    name = "elb_sg"
    vpc_id = aws_default_vpc.default.id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
    }
    egress {
        from_port=80
        to_port = 80
        protocol = "tcp"
    }
    tags ={
        name = "my_elb_sg"
    }

}
}
resource "aws_elb" "elb" {
    name = "my_elb"
    subnets = subnet_id
    security_group = [aws_security_group.elb_sg.id]
    instances = value(aws_instance.my_instance).*.id
    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 443
        lb_protocol = "http"

    }
}

resource "aws_instance" "my_instance" {
    ami = value[aws_ami.nginx_image.id]

    for_each = toset(["one", "two", "three"])

  name = "instance-${each.key}"

  instance_type          = "t2.micro"
  key_name               = "user1"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = "subnet-eddcdzz4"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "keyname"
    host = self.public_ip
  }
  provisioner "remote_exec"{
    inline = [
        "sudo yum install nginx -y",
        "sudo yum install start nginx",
        "sudo yum install enable nginx"
    ]
  }

}


data "aws_ami" "nginx_image" {
  executable_users = ["self"]
  most_recent      = true
  name_regex       = "^nginx-\\d{3}"
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["nginx-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }
}
 