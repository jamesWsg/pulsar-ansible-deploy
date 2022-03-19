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

output "pulsar_service_vip_name" {
  value = "${var.eip_nat_ip}"
}

output "pulsar_service_url" {
  value = "pulsar://${var.eip_nat_ip}:6650"
}

output "pulsar_web_url" {
  value = "http://${var.eip_nat_ip}:8080"
}

output "pulsar_bastion_host" {
  value = "${aws_instance.bastion_instance.public_ip}"
}

output "zookeeper_servers" {
  value = "${aws_instance.zookeeper.*.private_ip}"
}

output "bookies" {
  value = "${aws_instance.bookie.*.private_ip}"
}

output "brokers" {
  value = "${aws_instance.broker.*.private_ip}"
}

output "proxies" {
  value = "${aws_instance.proxy.*.private_ip}"
}

output "monitoring_servers" {
  value = "${aws_instance.monitoring.*.private_ip}"
}
