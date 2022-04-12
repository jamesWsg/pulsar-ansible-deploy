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


PUB_KEY_FILE=~/tmp/id_rsa.pub

# ssh to control machine to generate rsa key
vagrant ssh -c "yes y | ssh-keygen -t rsa -f id_rsa -N ''" control-machine

# copy the key to local
vagrant scp control-machine:/home/vagrant/.ssh/id_rsa.pub ${PUB_KEY_FILE}
sed -i.bak 's/control-machine/192.168.33.10/' ${PUB_KEY_FILE}

# copy the key to all machines and add it to authorized_key
for host in zk1 zk2 zk3 broker1 broker2 broker3; do
  echo $host
  vagrant scp ${PUB_KEY_FILE} ${host}:/home/vagrant/.ssh/id_rsa.pub
  vagrant ssh -c "cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys" ${host}
done
