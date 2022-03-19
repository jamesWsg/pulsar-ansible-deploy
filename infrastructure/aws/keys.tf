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

resource "random_id" "pulsar_kp_name" {
  byte_length = 4
  prefix      = "${var.cluster_name}-pulsar-ssh-key-"
}

resource "aws_key_pair" "pulsar_kp" {
  key_name   = "${random_id.pulsar_kp_name.hex}"
  public_key = "${file(var.pulsar_key_path)}"
}

resource "random_id" "bastion_kp_name" {
  byte_length = 4
  prefix      = "${var.cluster_name}-bastion-ssh-key-"
}

resource "aws_key_pair" "bastion_kp" {
  key_name   = "${random_id.bastion_kp_name.hex}"
  public_key = "${file(var.bastion_key_path)}"
}
