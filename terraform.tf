terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~>3.0"
      }
  }
}



#configure aws provider

provider "aws" {
  region = "us-east-2"
  
}

#create vpc

resource  "aws_vpc" "mylab-vpc" {
  cidr_block = var.cidr_block[0]

  tags = {
    Name = "mylab-vpc"
  }

}

#create public subnet

resource "aws_subnet" "mylab-subnet1" {
  vpc_id = aws_vpc.mylab-vpc.id
  cidr_block = var.cidr_block[1]

  tags = {
    Name = "mylab-subnet1"
  }
}

#create internet gateway

resource "aws_internet_gateway" "mylab-iw" {
  vpc_id = aws_vpc.mylab-vpc.id
  tags = {
    "Name" = "mylab-iw"
  }
}

#create security group

resource "aws_security_group" "mylab-sg" {
  name = "mylab security group"
  description = "To allow inbound and outbound traffic"
  vpc_id = aws_vpc.mylab-vpc.id

  dynamic ingress  {
    iterator = port
    for_each = var.ports
     content{
        from_port = port.value
        to_port = port.value
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

     }
    
  } 
    

  egress  {
    from_port =0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow traffic"
  }
}

#create route table and association
resource "aws_route_table" "mylab-routetable" {
  vpc_id = aws_vpc.mylab-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mylab-iw.id
  }
  tags = {
    "name" = "mylab_routetable"
  }

}

resource "aws_route_table_association" "mylab-assn" {
  subnet_id = aws_subnet.mylab-subnet1.id
  route_table_id = aws_route_table.mylab-routetable.id
}

#create jenkins EC2 instance
resource "aws_instance" "Jenkins" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.mylab-sg.id]
  subnet_id = aws_subnet.mylab-subnet1.id
  associate_public_ip_address = true
  user_data = file("./installJenkins.sh")
  tags = {
    Name = "Jenkins-server"
  }  
}


#create ansible node
resource "aws_instance" "Ansiblecontroller" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.mylab-sg.id]
  subnet_id = aws_subnet.mylab-subnet1.id
  associate_public_ip_address = true
  user_data = file("./installansiblecn.sh")
  tags = {
    Name = "Ansible-controlnode"
  }  
}

#ansible managed node with apache tomcat
resource "aws_instance" "ansiblemn1" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.mylab-sg.id]
  subnet_id = aws_subnet.mylab-subnet1.id
  associate_public_ip_address = true
  user_data = file("./ansiblemntomcate.sh")
  tags = {
    Name = "ansiblemn-apachetomcat"
  }  
}

#ansible managed node to host docker

resource "aws_instance" "dockerhost" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.mylab-sg.id]
  subnet_id = aws_subnet.mylab-subnet1.id
  associate_public_ip_address = true
  user_data = file("./docker.sh")
  tags = {
    Name = "dockerhost"
  }  
}

#sonatype nexus
resource "aws_instance" "nexus" {
  ami = var.ami
  instance_type = var.instance_type_nexus
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.mylab-sg.id]
  subnet_id = aws_subnet.mylab-subnet1.id
  associate_public_ip_address = true
  user_data = file("./sonatypenexus.sh")
  tags = {
    Name = "nexus-server"
  }  
}




