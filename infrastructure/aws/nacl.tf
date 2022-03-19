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

# --------------------------------------------------------------------------------------------------------------
# NACL
# --------------------------------------------------------------------------------------------------------------
resource "aws_network_acl" "bastion" {
  vpc_id     = "${aws_vpc.bastion_vpc.id}"
  subnet_ids = ["${aws_subnet.bastion_subnet.id}"]

  tags {
    Name    = "${var.cluster_name} - Pulsar Bastion NACL"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_network_acl_rule" "bastion_ssh_in" {
  count          = "${length(var.ssh_inbound)}"
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "${100 + count.index}"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.ssh_inbound[count.index]}"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "bastion_ssh_out" {
  count          = "${length(var.ssh_inbound)}"
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "${100 + count.index}"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.ssh_inbound[count.index]}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "bastion_ssh_to_pulsar" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "200"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "bastion_ssh_from_pulsar" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "bastion_ssh_to_monitoring" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "240"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "bastion_ssh_from_monitoring" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "240"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "bastion_http_out" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "220"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "bastion_https_out" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "230"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "bastion_http_in" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "220"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl" "pulsar" {
  vpc_id     = "${aws_vpc.pulsar_vpc.id}"
  subnet_ids = ["${aws_subnet.pulsar_subnet.id}"]

  tags {
    Name    = "${var.cluster_name} - Pulsar ACL"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_network_acl_rule" "pulsar_ssh_in" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "100"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "pulsar_ssh_out" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "100"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "pulsar_http_out" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "200"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "pulsar_https_out" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "210"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "pulsar_http_in" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "pulsar_internal_all_in" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "400"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "pulsar_internal_all_out" {
  network_acl_id = "${aws_network_acl.pulsar.id}"
  rule_number    = "400"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl" "pulsar_nat" {
  vpc_id     = "${aws_vpc.pulsar_vpc.id}"
  subnet_ids = ["${aws_subnet.pulsar_nat.id}"]

  tags {
    Name    = "${var.cluster_name} - Pulsar NAT ACL"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}

resource "aws_network_acl_rule" "pulsar_nat_http_out" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "100"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "pulsar_nat_https_out" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "110"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "pulsar_nat_http_in" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "100"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nat_http_from_pulsar" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "nat_https_from_pulsar" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "210"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nat_http_to_pulsar" {
  network_acl_id = "${aws_network_acl.pulsar_nat.id}"
  rule_number    = "200"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "monitoring_grafana_in" {
  count          = "${length(var.ssh_inbound)}"
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "${500 + count.index}"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.ssh_inbound[count.index]}"
  from_port      = 3000
  to_port        = 3000
}

resource "aws_network_acl_rule" "monitoring_to_pulsar_nodeexporter" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "600"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 9100
  to_port        = 9100
}

resource "aws_network_acl_rule" "monitoring_to_pulsar_blackbox_exporter" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "601"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 9115
  to_port        = 9115
}

resource "aws_network_acl_rule" "monitoring_to_pulsar_http" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "602"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "monitoring_to_pulsar_stats" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "603"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.pulsar_subnet_cidr}"
  from_port      = 8080
  to_port        = 8080
}
