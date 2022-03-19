#
# Copyright (c) 2018 Sijie. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# VPC for bastion instances
resource "aws_vpc" "bastion_vpc" {
  cidr_block           = "${var.bastion_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "${var.cluster_name} - Bastion VPC"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

# Gateway for Bastion Instances
resource "aws_internet_gateway" "bastion_gateway" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  tags {
    Name    = "${var.cluster_name} - Bastion Gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

# Subnet for Bastion Instances
resource "aws_subnet" "bastion_subnet" {
  vpc_id                  = "${aws_vpc.bastion_vpc.id}"
  cidr_block              = "${var.bastion_subnet_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "${var.cluster_name} - Bastion Subnet"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

# Bastion Route Table
resource "aws_route_table" "bastion_route_table" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bastion_gateway.id}"
  }

  lifecycle {
    ignore_changes = ["*"]
  }

  tags {
    Name    = "${var.cluster_name} - Bastion Route Table"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_route_table_association" "bastion_table_association" {
  subnet_id      = "${aws_subnet.bastion_subnet.id}"
  route_table_id = "${aws_route_table.bastion_route_table.id}"
}

# Bastion Instances

resource "aws_instance" "bastion_instance" {
  ami           = "${var.aws_ami}"
  instance_type = "${var.instance_types["bastion"]}"
  key_name      = "${aws_key_pair.bastion_kp.key_name}"
  subnet_id     = "${aws_subnet.bastion_subnet.id}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion_sg.id}",
  ]

  associate_public_ip_address = true

  tags {
    Name    = "${var.cluster_name} - Bastion Server"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }

  provisioner "file" {
    source      = "${var.pulsar_private_key_path}"
    destination = "/home/${var.bastion_user}/.ssh/"

    connection {
      type        = "ssh"
      user        = "${var.bastion_user}"
      private_key = "${file("${var.bastion_private_key_path}")}"
      timeout     = "5m"
    }
  }
}
