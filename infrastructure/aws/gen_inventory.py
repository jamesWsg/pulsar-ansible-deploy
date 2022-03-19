#!/usr/bin/env python
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


import json
import sys, subprocess
from jinja2 import Environment, FileSystemLoader

template_loader = FileSystemLoader("templates")
env = Environment(loader=template_loader)

result = subprocess.run(
    ["terraform", "output", "-json"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE)

if result.returncode != 0:
    print(result.stderr)
    sys.exit(1)

infra=json.loads(result.stdout)

zookeeper_servers = infra['zookeeper_servers']['value']
bookies = infra['bookies']['value']
brokers = infra['brokers']['value']
proxies = infra['proxies']['value']
monitoring_servers = infra['monitoring_servers']['value']
pulsar_service_vip_name = infra['pulsar_service_vip_name']['value']

if len(brokers) == 0:
    brokers = proxies

if len(proxies) == 0:
    proxies = brokers

monitored_servers = zookeeper_servers + bookies + brokers + proxies
monitored_servers = list(set(monitored_servers))

if len(zookeeper_servers) == 0:
    print("No zookeeper servers found")
    sys.exit(1)

if len(bookies) == 0:
    print("No bookies found")
    sys.exit(1)

if len(brokers) == 0:
    print("No brokers found")
    sys.exit(1)

if len(proxies) == 0:
    print("No proxies found")
    sys.exit(1)

if len(monitoring_servers) == 0:
    print("No monitoring servers found")
    sys.exit(1)

monitoring_server = monitoring_servers[0]

inventory_template = env.get_template("inventory.ini.j2")
inventory_output = inventory_template.render(
    zookeeper_servers = zookeeper_servers,
    bookies = bookies,
    brokers = brokers,
    proxies = proxies,
    monitored_servers = monitored_servers,
    monitoring_server = monitoring_server,
    pulsar_service_vip_name = pulsar_service_vip_name,
)

with open("inventory.ini", "w") as inventory_file:
    inventory_file.write(inventory_output)

print("Successfully generate inventory file in `inventory.ini`")
