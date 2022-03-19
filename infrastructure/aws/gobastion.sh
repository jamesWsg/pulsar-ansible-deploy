#!/usr/bin/env bash
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


AWS_DIR=$(dirname $0)
BASTION=$(terraform output pulsar_bastion_host)
PULSAR_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
ssh -i ${PULSAR_PRIVATE_KEY_PATH} ec2-user@${BASTION}
