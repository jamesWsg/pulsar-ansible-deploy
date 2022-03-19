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

cluster_name = "pulsar-test-cluster"

pulsar_key_path = "~/.ssh/id_rsa.pub"

pulsar_private_key_path = "~/.ssh/id_rsa"

bastion_key_path = "~/.ssh/id_rsa.pub"

bastion_private_key_path = "~/.ssh/id_rsa"

region = "us-west-1"

availability_zone = "us-west-1a"

aws_ami = "ami-18726478"

num_zookeeper_nodes = 3

num_bookie_nodes = 3

num_broker_nodes = 0

num_proxy_nodes = 3

num_monitoring_nodes = 1

instance_types = {
  "bastion"    = "t2.small"
  "zookeeper"  = "t2.small"
  "bookie"     = "i3.xlarge"
  "broker"     = "c5.2xlarge"
  "proxy"      = "c5.2xlarge"
  "monitoring" = "c5.2xlarge"
}
