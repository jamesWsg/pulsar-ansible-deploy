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

variable "tags" {
  default = {
    "owner"   = "sijie"
    "project" = "pulsar-test"
  }
}

variable "bastion_user" {
  default = "ec2-user"
}

variable "cluster_name" {
  default = "The pulsar cluster name"
}

variable "pulsar_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/my_keys.pub
Default: ~/.ssh/id_rsa.pub
DESCRIPTION
}

variable "pulsar_private_key_path" {
  description = <<DESCRIPTION
Path to the SSH private key to be used for bastion to connect to pulsar instances.
DESCRIPTION
}

variable "bastion_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/my_keys.pub
Default: ~/.ssh/id_rsa.pub
DESCRIPTION
}

variable "bastion_private_key_path" {
  description = <<DESCRIPTION
Path to the SSH private key to be used to connect to bastion.
DESCRIPTION
}

variable "key_name_prefix" {
  description = "The prefix for the randomly generated name for the AWS key pair to be used for SSH connections (e.g. `pulsar-terraform-ssh-keys-0a1b2cd3`)"
  default     = "pulsar-terraform-ssh-keys"
}

variable "region" {
  description = "The AWS region in which the Pulsar cluster will be deployed"
}

variable "availability_zone" {
  description = "The AWS availability zone in which the cluster will run"
}

variable "aws_ami" {
  description = "The AWS AMI to be used by the Pulsar cluster"
}

variable "num_zookeeper_nodes" {
  description = "The number of EC2 instances running ZooKeeper"
}

variable "num_bookie_nodes" {
  description = "The number of EC2 instances running BookKeeper"
}

variable "num_broker_nodes" {
  description = "The number of EC2 instances running Pulsar brokers"
}

variable "num_proxy_nodes" {
  description = "The number of EC2 instances running Pulsar proxies"
}

variable "num_monitoring_nodes" {
  description = "The number of EC2 instances running Monitoring service (e.g. Prometheus, Grafana)"
}

variable "instance_types" {
  type = "map"
}

variable "bastion_vpc_cidr" {
  default = "172.21.20.0/24"
}

variable "pulsar_vpc_cidr" {
  default = "172.21.10.0/24"
}

variable "bastion_subnet_cidr" {
  default = "172.21.20.0/26"
}

variable "pulsar_subnet_cidr" {
  default = "172.21.10.0/26"
}

variable "pulsar_nat_cidr" {
  default = "172.21.10.64/26"
}

variable "eip_nat_ip" {
  default = "172.21.10.70"
}

variable "ssh_inbound" {
  type    = "list"
  default = ["0.0.0.0/0"]
}
