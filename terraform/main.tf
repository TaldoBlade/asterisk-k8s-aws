locals { # Declare the variables to be used
  vpc_id            = "vpc-0bb7934f7c7b499cb"
  subnet_id         = "subnet-0a42df9cb59b1e21d"
  ssh_user          = "ubuntu"
  key_name          = "devops"
  private_key_path  = "/home/blade/asterisk-k8s-aws/devops.pem"
  ansible_file_path = "/home/blade/asterisk-k8s-aws/ansible/asterisk.yml"
}

provider "aws" { # Declare a provider, in this case AWS, so we can connect and send commands to
  region = "sa-east-1"
}

# Resources are codes that we want to use in order to provision infraestructure
# Creates a security group to be used by the EC2 instance
# resource "type(which doesn't change)" "name of the resource(unique)"
resource "aws_security_group" "asterisk_security_group" { 
  name_prefix        = "custom-security-group-"
  description        = "Custom security group allowing specified traffic"
  vpc_id             = local.vpc_id

  # Ingress rule for UDP traffic from port 5060 to 5065
  ingress {
    from_port   = 5060
    to_port     = 5065
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for UDP traffic from port 10000 to 20000
  ingress {
    from_port   = 10000
    to_port     = 20000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for SSH (TCP port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch an EC2 instance with the custom security group
resource "aws_instance" "asterisk" {
  ami                         = "ami-0b6c2d49148000cd5"  # Ubuntu AMI ID, change this to the desired AMI
  subnet_id                   = local.subnet_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = local.key_name
  security_groups = [aws_security_group.asterisk_security_group.id]

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = aws_instance.asterisk.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.asterisk.public_ip}, --private-key ${local.private_key_path} -u ubuntu ${local.ansible_file_path}"
  }
}

output "asterisk_ip" {
  value = aws_instance.asterisk.public_ip
}
