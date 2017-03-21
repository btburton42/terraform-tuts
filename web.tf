provider "aws" {
  region = "${var.region}"
}

module "vpc" {
  source        = "github.com/btburton42/tf_vpc.git?ref=v0.0.1"
  name          = "web"
  cidr          = "${var.region} != "us-west-2" ? "172.16.0.0/12" : "172.18.0.0/12"}"
}

resource "aws_instance" "web" {
  ami = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${module.vpc.public_subnet_id}"
  private_ip = "${var.instance_ips[count.index]}"
  user_data = "${file("files/web_bootstrap.sh")}"
  associate_with_private_ip = true
  vpc_security_group_ids = [
    "${aws_security_group.web_host_sg.id}"
  ]
  tags {
    Name = "web-${format("%03d", count.index)}"
    Owner = "${element(var.owner_tag[count.index])}"
  }
  count = "${var.environment == "production" ? 4 : 2}"
}

resource "aws_elb" "web" {
  name = "web-elb"
  subnets = ["${module.vpc.public_subnet_id}"]
  security_groups = ["${aws_security_group.web_inbound_sg.id}"]
  listener {
    instance_port =  80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  instances = ["${aws_instance.web.*.id}"]
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "web_inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_host_sg" {
  name        = "web_host"
  description = "Allow SSH & HTTP to web hosts"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
