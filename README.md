

## Overview



This repo is based on https://github.com/streamnative/apache-pulsar-ansible,  for deploy larger pulsar cluster in production environment (like china union project), mainly include the following function:

- Deploy pulsar cluster
- Pulsar maitain ( located in `tools/configer` directory,  like config collect and distribution,)
- Some common tools in production environment ( located in `tools` directory ,like disk partition, mkfs, mount and so on )



## Environment

Suppose we have four vm, one is control-vm, the other three node (called pulsar nodes in following ) is to deploy pulsar cluster, env as following ():

| Hostname        | IP       | OS /defalt user account      | Planed-roles                     |
| --------------- | -------- | ---------------------------- | -------------------------------- |
| Control-machine | 10.2.0.8 | ubuntu20/azureuser           | Prometheus/grafana/node_exporter |
| Node1           | 10.2.0.4 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
| Node2           | 10.2.0.6 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
| Node3           | 10.2.0.7 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
|                 |          |                              |                                  |
|                 |          |                              |                                  |

> Attentions: in azure env, the OS default user not allowed to ssh login with passoword, but first time control-machine need to ssh to other nodes using password, refer to   https://phoenixnap.com/kb/ssh-permission-denied-publickey solve the problem



## Download ansible-docker image 

Download from aliyun OSS 

```
in bucket streamnative-edm-images ,you can find pulsar-ansible-deploy/ansible-ubuntu20v1.img

https://streamnative-edm-images.oss-cn-beijing.aliyuncs.com/pulsar-ansible-deploy/ansible-ubuntu20v1.img?Expires=1650894338&OSSAccessKeyId=TMP.3KfFnKDnUEi4CYu3BAjtiVH8YknYYf1Sf2yUsmyeA7uphgukW8yh4e2HZ2ejJdgwg9gwUo6NJRAF99GGDqbwPgNyVwZBJZ&Signature=DAnMV6VagqFsM9kTzEiogj%2BCCxM%3D
```

> the above S3 url may expire ,you should check, or you can build your docker imge  use repo's Dockfile



## Prepare docker environment 

in control-machine

### step1: load ansible docker image

```
sudo docker load -i ansible-ubuntu20v1.img
```

### Step2: make host path for docker use, and get ansible repo

```
mkdir -p /home/wsg/deploy
cd /home/wsg/deploy
mkdir .ssh              ##this is used for generate ssh-key in docker

git clone git@github.com:streamnative/pulsar-ansible-deploy.git
```

### step3: run ansible docker

```
wsg@ansible-control:~/deploy$ sudo docker run --rm -v /home/wsg/deploy/pulsar-ansible-deploy:/home/pulsar/deploy -v /home/wsg/deploy/.ssh:/home/pulsar/.ssh -it ansible-ubuntu20v1 /bin/bash
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

pulsar@3036ec8b2631:/$ pwd
/
```

Now you have entered docker ,default user is pulsar in docker container, check the deploy directory（mount from host path） in /home/pulsar

```
pulsar@3036ec8b2631:~$ cd /home/pulsar/
pulsar@3036ec8b2631:~$ ls deploy/
ls: cannot open directory 'deploy/': Permission denied
pulsar@3036ec8b2631:~$

## because the deploy is mount from hostPath, docker default user is pulsar, not same as host,shoulde change owner like following 

pulsar@3036ec8b2631:~$ pwd
/home/pulsar
pulsar@3036ec8b2631:~$ sudo chown -R pulsar:pulsar *
pulsar@3036ec8b2631:~$ ls deploy/
Dockerfile               ansible.cfg     deploy_bookkeeper.yml          deploy_host_preconfig.yml  
pulsar@3036ec8b2631:~$

```

Now you can access the deploy, everything is ok now 

### step4: generate ssh-key

the key is used for  ansible docker ssh to other host without ssh-password

```
pulsar@3036ec8b2631:~$ pwd
/home/pulsar
pulsar@3036ec8b2631:~$ sudo chown -R pulsar:pulsar .ssh/

pulsar@3036ec8b2631:~$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/pulsar/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/pulsar/.ssh/id_rsa
Your public key has been saved in /home/pulsar/.ssh/id_rsa.pub

## after finish,you can see the key in .ssh/
pulsar@3036ec8b2631:~$ ls -l .ssh/
total 8
-rw------- 1 pulsar pulsar 2610 Apr 25 04:06 id_rsa
-rw-r--r-- 1 pulsar pulsar  573 Apr 25 04:06 id_rsa.pub
pulsar@3036ec8b2631:~$
```



## inventory and global variable prepare

After ansible docker is running, enter /home/pulsar/deploy directory in docker

There is some config file related the custom's environment need to modify as following

### host.ini

This inventory file is only used for create pulsar user in other pulsar node  

```
$ cat hosts.ini
[servers]
10.2.0.4
10.2.0.6
10.2.0.7
10.2.0.8

[all:vars]
username = pulsar
ansible_ssh_pass='abc12345'
ansible_ssh_user='azureuser'
~
```



### inventory.ini

The file `inventory.ini` define which node run pulsar component, pulsar running directory, and the version of corresponding package,

In this example as following:

````
# vim inventory.ini
[brokers]
10.2.0.4
10.2.0.6
10.2.0.7
[bookies]
10.2.0.4
10.2.0.6
10.2.0.7

[zookeeper]
10.2.0.4
10.2.0.6
10.2.0.7
## Monitoring

# monitoring system metrics (e.g. node_exporter and blackbox_exporter)
[monitored_hosts]
10.2.0.4
10.2.0.6
10.2.0.7
10.2.0.8
[prometheus]
10.2.0.8
[grafana]
10.2.0.8

## Group Variables

[all:vars]
pulsar_dir = /opt/pulsar
monitoring_dir = /opt/pulsar/monitoring
pulsar_data_dir = /opt/pulsar/data

pulsar_version = 2.8.1
jdk_version = 11.0.1
cluster_name = test-cluster

# ansible user
ansible_user = pulsar

# process supervision : [systemd]
process_supervision = systemd

# monitoring related settings
node_exporter_version = 1.3.1
blackbox_exporter_version = 0.12.0
pushgateway_version = 0.6.0
prometheus_version = 2.33.4
alertmanager_version = 0.23.0
grafana_version = 8.1.3

# grafana
grafana_admin_user = "admin"
grafana_admin_password = "admin"
````

 

### global variable

Include control-machine variables , pulsar variables 

````
vim group_vars/all.yml

# variables applied to all host groups
deploy_user: "{{ ansible_user }}"

# control machine
download_dir: "{{ playbook_dir }}/deploy/download"
resources_dir: "{{ playbook_dir }}/deploy/resources"
scripts_dir: "{{ playbook_dir }}/deploy/scripts"
deploy_conf_dir: "{{ playbook_dir }}/deploy/conf"

####################
# pulsar variables
####################

# common
pulsar_current_dir: "{{ pulsar_dir }}/current"
pulsar_pkg_dir: "{{ pulsar_dir }}/packages/apache-pulsar-{{ pulsar_version }}"
pulsar_log_dir: "{{ pulsar_dir }}/logs"

# zookeeper
zk_port: 2181
zk_http_port: 7000

# bookkeeper
bookie_port: 3181
bookie_http_port: 8000
num_ledger_dirs: 2
num_journal_dirs: 2
````



### download package

After modified the inventory.ini file ,then run

```
ansible-playbook -i inventory.ini cm_prepare.yml
```

The command will create deploy directory ,and download the package defined in inventory.ini , you can check the downloaded file as following.

```
pulsar@ubuntu20:~/apache-pulsar-ansible$ tree deploy -L 2
deploy
├── conf
│   ├── binary_packages.yml
│   └── common_packages.yml
├── download
│   ├── alertmanager-0.23.0.tar.gz
│   ├── blackbox_exporter-0.12.0.tar.gz
│   ├── grafana-5.3.2.tar.gz
│   ├── grafana-8.1.3.tar.gz
│   ├── jdk-11.0.1_linux-x64_bin.rpm
│   ├── node_exporter-1.3.1.linux-amd64
│   ├── node_exporter-1.3.1.tar.gz
│   ├── prometheus-2.33.4.tar.gz
│   ├── pulsar-2.8.1.tar.gz
```

Now you have all things prepared. 

> Note: if custom's environment can not access internet, you should do this in an satisfied environment, after download finish, you can tar the deploy directory, then used in custom's environment.



## create pulsar user in other pulsar node

```
ansible-playbook -i hosts.ini playbooks/create_service_account.yml
```

after finish you can check ssh to other host is ok

```
pulsar@3036ec8b2631:~/deploy$ ssh 10.2.0.7
Last login: Mon Apr 25 04:35:51 2022 from ansible-control.internal.cloudapp.net
[pulsar@test-withDokerAnsible ~]$

```



## quick start

if you just deploy pulsar in test environment, you just need run

````
ansible-playbook -i inventory.ini deploy_pulsar_stack.yml
````

This will put zookeeper, bookie data all into /opt/pulsar/ (which physically one disk, this is not suited in production environment). You can see production deploy for more information

> Attentions: if you deploy zk, broker on same host, check port confict,which defined in group_vars



## production deploy

 in production environment, you should consider: 

- Zookeeper data dirs

- Bookeeper journal and ledger dirs

- Prometheus data dirs

you can see the complete example as following:

[production deploy example](production-deploy-example.md)



## config management

after deploy finish ,we may need to change configuration, you can use `tools/configer/` directory

suppose we need to change bookkeeper config , you can do as following 

1. get bookeeeper config

   ```
   ansible-playbook -i ../../inventory.ini bookkeeper-config-get.yml
   ```

   the above command will create tmp dir in current dir  as following:

   ```
   pulsar@ansible-control:~/pulsar-ansible-deploy/tools/configer$ tree tmp/
   tmp/
   ├── bookkeeper.conf-10.2.0.12
   ├── bookkeeper.conf-10.2.0.13
   └── bookkeeper.conf-10.2.0.14
   
   ```

2.  modify one of the bookeeper.conf.*  ,then mvto configer  directory as following

   ```
   pulsar@ansible-control:~/pulsar-ansible-deploy/tools/configer$ ll
   total 64
   drwxrwxr-x  3 pulsar pulsar  4096 Mar 17 13:20 ./
   drwxr-xr-x 17 pulsar pulsar  4096 Mar 17 13:12 ../
   -rw-rw-r--  1 pulsar pulsar   546 Mar 17 13:17 bookeeper-config-distribute.yml
   -rw-rw-r--  1 pulsar pulsar   384 Mar 17 13:08 bookeeper-config-get.yml
   -rw-rw-r--  1 pulsar pulsar 30352 Mar 17 13:11 bookkeeper.conf
   drwxrwxr-x  2 pulsar pulsar  4096 Mar 17 13:12 tmp/
   ```

3. Then distribute bookeeper.conf to all bookeeper nodes

   ```
   ansible-playbook -i ../../inventory.ini bookkeeper-config-distribute.yml
   ```




If your configuration is different  on each node, should consider use template, you need subtract diff as variable in template

## more

if you want to know more about this repo，refer [readme for developer](README-for-developer.md)





















