

## overview



this repo is based on https://github.com/streamnative/apache-pulsar-ansible,  for deploy larger pulsar cluster in production environment (like china union project), mainly include the following function:

- Deploy pulsar cluster
- Pulsar maitain ( located in `tools/configer` directory,  like config collect and distribution,)
- Some common tools in production environment ( located in `tools` directory ,like disk partition, mkfs, mount and so on )



## Environment

Suppose we have four vm, one is control-vm, the other three node (called pulsar nodes in following ) is to deploy pulsar cluster, env as following :

| Hostname        | IP       | OS /defalt user account      | Planed-roles                     |
| --------------- | -------- | ---------------------------- | -------------------------------- |
| Control-machine | 10.2.0.8 | ubuntu20/azureuser           | Prometheus/grafana/node_exporter |
| Node1           | 10.2.0.4 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
| Node2           | 10.2.0.6 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
| Node3           | 10.2.0.7 | redhat7.6/azureuser/abc12345 | Zk/bookie/broker/node_exporter   |
|                 |          |                              |                                  |
|                 |          |                              |                                  |

> Attentions: in azure env, the OS default user not allowed to ssh login with passoword, but first time control-machine need to ssh to other nodes using password, refer to   https://phoenixnap.com/kb/ssh-permission-denied-publickey solve the problem



## control machine prepare

Before you start, make sure you have:

(TBD)

### Step 1: Install system dependencies on the control machine.

Log in to the `control machine` using the `root` user account, and run the
corresponding command according to your operating system.

#### CentOS

Run the following command:

```bash
# yum -y install epel-release git curl sshpass
# yum -y install python-pip
```

#### ubuntu

```
# apt install git curl sshpass 
```



### Step 2: Create the `pulsar` user on the control machine

Make sure you have logged in to the control machine using a user account
that has super permissions. Then run the following commands:

1. Create `pulsar` user.

  ```bash
useradd -m -d /home/pulsar pulsar
  ```

2. Set a password for `pulsar` user account.

  ```bash
passwd pulsar
  ```

3. Add `pulsar` to sudoer list.

  The wheel group is a special user group that allows all members in the group
  to run all commands. Therefore, we need to add the new user to this group
  so it can run commands as superuser.

  ```bash
usermod -aG wheel pulsar
  ```

  Once the user is added to `wheel` group, use `visudo` to open and edit
  `/etc/sudoers` file. Make sure that the line that starts with `%wheel` is
  not commented. It should look exactly like this:

  ```bash
## Allows people in group wheel to run all commands
%wheel  ALL=(ALL)       ALL
  ```

  Then configure sudo without password for the `pulsar account` by adding
  `pulsar ALL=(ALL) NOPASSWD: ALL` to the end of the `/etc/sudoers` file.

  ```bash
pulsar ALL=(ALL) NOPASSWD: ALL
  ```

4. Generate the SSH key.

  Execute the `su` command to switch the user to `pulsar`.

  ```bash
su - pulsar
  ```

  Create the SSH key for the `pulsar` user account and hit the Enter key
  when `Enter passphrase` is promoted. After successful execution, the ssh
  private key file is `/home/pulsar/.ssh/id_rsa`, and the SSH public key
  file is `/home/pulsar/.ssh/id_rsa.pub`.

  ```bash
ssh-keygen -t rsa
  ```

5. Once the SSH key is generated for user `pulsar`, make sure its key is whitelisted at root user.

   At the root user, do following:

   ```bash
   sudo cat /home/pulsar/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
   ```



### Step 3: Checkout `pulsar-ansible` to the control machine

1. Login to the control machine using the `pulsar` user account and
   enter the `/home/pulsar` directory.

2. Git clone the `pulsar-ansible` repo.

  ```bash
git clone git@github.com:streamnative/pulsar-ansible-deploy.git
  ```

  > **NOTE**: it is important to clone `pulsar-ansible` to the `/home/pulsar`
  > directory using `pulsar` user account. Otherwise, you will encounter
  > privilege issue.

### Step 4: Install Ansible and its dependencies on the control machine

> Make sure you have logged in the control machine using `pulsar` user account.

1. Install Ansible and its dependencies.

  ```bash
$ cd /home/pulsar/pulsar-ansible-deploy
$ sudo pip install -r ./requirements.txt
  ```

2. Make sure Ansible is installed correctly.

  ```bash
$ ansible --version
ansible 2.6.7
  ```

### Step 5: Create `pulsar` user on all pulsar nodes to run pulsar service

> Make sure you have logged in the control machine using `pulsar` user account.

1. Add the addresses of your target machines to the `[servers]` section
   of the `hosts.ini` file.

  ```bash
$ cd /home/pulsar/pulsar-ansible-deploy
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

2. Run `create_service_account.yml` playbook.

  ```bash
ansible-playbook -i hosts.ini playbooks/create_service_account.yml
  ```

> Attention: in azure cloud, the default sshd config not allowed to login with user/password, you can refer https://phoenixnap.com/kb/ssh-permission-denied-publickey to solve this problem. After create pulsar user, you can restore the sshd_config. Following steps, we will use pulsar user (with ssh-key method)

  This playbook creates `pulsar` service account on the target machines,
  configures the sudo rules and the SSH mutual trust from control machine
  to the target machines.

3. Check ssh to pulsar nodes without password

   ```
   pulsar@ubuntu20:~/apache-pulsar-ansible$ ssh 10.2.0.4
   Last login: Thu Mar 17 04:29:31 2022 from ubuntu20.internal.cloudapp.net
   [pulsar@redhat1 ~]$
   ```

4. then modify the host.ini, comment out ssh password as following:

   Otherwise ansible prefer use ssh password to login remote servers, if you configured the sshd_config in step 2 and restored the sshd_config will have problem.

   ```
   # cat hosts.ini
   [servers]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   10.2.0.8
   
   [all:vars]
   username = pulsar
   #ansible_ssh_pass='abc12345'
   #ansible_ssh_user='azureuser'
   ```

   



## inventory and global variable prepare



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

 

After modifie the inventory.ini file ,then run

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





Now you have all things prepared. 



## quick start

if you just deploy pulsar in test environment, you just need run

````
ansible-playbook -i inventory.ini deploy_pulsar_stack.yml
````

> Attentions: if you deploy zk, broker on same host, check port confict



## production deploy

 in production environment, you should consider: 

- Zookeeper data dirs

- Bookeeper journal and ledger dirs

- Prometheus data dirs

you can see the complete example as following:

[production deploy example](production-deploy-example.md)



## more

if you want to know more about this repo，refer [readme for developer](README-for-developer.md)





















