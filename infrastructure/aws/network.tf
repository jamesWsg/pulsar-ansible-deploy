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

resource "aws_vpc" "pulsar_vpc" {
  cidr_block           = "${var.pulsar_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "${var.cluster_name} - Pulsar VPC"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_internet_gateway" "pulsar_gateway" {
  vpc_id = "${aws_vpc.pulsar_vpc.id}"

  tags {
    Name    = "${var.cluster_name} - Pulsar Gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_subnet" "pulsar_subnet" {
  vpc_id                  = "${aws_vpc.pulsar_vpc.id}"
  cidr_block              = "${var.pulsar_subnet_cidr}"
  map_public_ip_on_launch = false

  tags {
    Name    = "${var.cluster_name} - Pulsar Subnet"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_subnet" "pulsar_nat" {
  vpc_id                  = "${aws_vpc.pulsar_vpc.id}"
  cidr_block              = "${var.pulsar_nat_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "${var.cluster_name} - Pulsar NAT"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the nat gateway in the pulsar nat subnet
# --------------------------------------------------------------------------------------------------------------
resource "aws_eip" "pulsar_nat" {
  vpc                       = true
  associate_with_private_ip = "${var.eip_nat_ip}"

  tags {
    Name    = "${var.cluster_name} - Pulsar NAT EIP"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_nat_gateway" "pulsar_nat_gateway" {
  allocation_id = "${aws_eip.pulsar_nat.id}"
  subnet_id     = "${aws_subnet.pulsar_nat.id}"

  tags {
    Name    = "${var.cluster_name} - Pulsar NAT Gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_route_table" "pulsar_route_table" {
  vpc_id = "${aws_vpc.pulsar_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.pulsar_nat_gateway.id}"
  }

  lifecycle {
    ignore_changes = ["*"]
  }

  tags {
    Name    = "${var.cluster_name} - Pulsar Route Table"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_route_table_association" "pulsar_rt_association" {
  subnet_id      = "${aws_subnet.pulsar_subnet.id}"
  route_table_id = "${aws_route_table.pulsar_route_table.id}"
}

resource "aws_route_table" "pulsar_nat_rt" {
  vpc_id = "${aws_vpc.pulsar_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_internet_gateway.pulsar_gateway.id}"
  }

  lifecycle {
    ignore_changes = ["*"]
  }

  tags {
    Name    = "${var.cluster_name} - Pulsar NAT Route Table"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_route_table_association" "pulsar_nat_rt_association" {
  subnet_id      = "${aws_subnet.pulsar_nat.id}"
  route_table_id = "${aws_route_table.pulsar_nat_rt.id}"
}

# --------------------------------------------------------------------------------------------------------------
# setup peering
# --------------------------------------------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "bastion_to_pulsar" {
  vpc_id      = "${aws_vpc.bastion_vpc.id}"
  peer_vpc_id = "${aws_vpc.pulsar_vpc.id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags {
    Name    = "${var.cluster_name} - Bastion to Pulsar Peering "
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

# Bastion to Pulsar routes
resource "aws_route" "pulsar_to_bastion" {
  route_table_id            = "${aws_route_table.pulsar_route_table.id}"
  destination_cidr_block    = "${var.bastion_vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.bastion_to_pulsar.id}"
}

resource "aws_route" "bastion_to_pulsar" {
  route_table_id            = "${aws_route_table.bastion_route_table.id}"
  destination_cidr_block    = "${var.pulsar_vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.bastion_to_pulsar.id}"
}
