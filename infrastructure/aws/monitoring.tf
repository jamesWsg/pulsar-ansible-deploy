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

resource "aws_instance" "monitoring" {
  ami           = "${var.aws_ami}"
  instance_type = "${var.instance_types["monitoring"]}"
  key_name      = "${aws_key_pair.bastion_kp.id}"
  subnet_id     = "${aws_subnet.bastion_subnet.id}"

  vpc_security_group_ids = [
    "${aws_security_group.monitoring_sg.id}",
  ]

  count = "${var.num_monitoring_nodes}"

  tags {
    Name    = "${var.cluster_name} - monitoring-${count.index + 1}"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
  }
}
