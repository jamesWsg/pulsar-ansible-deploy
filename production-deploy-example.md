



# Pre-consideration



## Zookeeper data directory config

In this example, each vm use sdc for zookeeper , sdc have two partion: sdc1 for zk data, sdc2 for zk txlog

zookeeper data dir if defined in `roles/zookeeper/defaults/main.yml` as following

```
# zookeeper data dir
zookeeper_data_dir: "{{ pulsar_dir }}/data/zookeeper"
zookeeper_txlog_dir: "{{ pulsar_dir }}/data/zookeeper/txlog"

```

this config no need change



## bookier data directory config

in this example, bookie journal and ledger have two directories, should change the  the follwoing config

```
vim group_vars/all.yml

num_ledger_dirs: 2
num_journal_dirs: 2


```



## zk,bk,broker conf

different release version may have different conf（include zookeeper.conf, bookie.conf, broker.conf）,if you deploy new version, should add  conf template, currently the repo has 2.8.1 conf template in following directory

```
pulsar@ubuntu20:~/apache-pulsar-ansible$ tree conf
conf
├── bastion
│   └── client.conf.j2
├── bookkeeper
│   ├── bookkeeper.conf.2.8.1.j2
│   └── bookkeeper.conf.j2
├── broker
│   ├── broker.conf.2.8.1.j2
│   └── broker.conf.j2
├── proxy
│   └── proxy.conf.j2
└── zookeeper
    ├── myid.j2
    ├── zookeeper.conf.2.8.1.j2
    └── zookeeper.conf.j2

```

> If you want to deploy pulsar 2.9.1, you should add `bookkeeper.conf.2.9.1.j2`, `broker.conf.2.8.1.j2`,and so on



## linux kernel parameter

include max openfiles，swapness

```
- name: Set absent kernel params
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    sysctl_set: yes
    ignoreerrors: yes
    state: absent
  with_items:
    - { name: 'net.ipv4.tcp_tw_recycle', value: 0 }
  when: tuning_kernel_parameters
  
  
  - name: Update existing kernel params
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    ignoreerrors: yes
    state: present
  with_items:
    - { name: 'net.core.somaxconn', value: 32768 }
    - { name: 'vm.swappiness', value: 0 }
    - { name: 'net.ipv4.tcp_syncookies', value: 0 }
    - { name: 'fs.file-max', value: 1000000 }
  when: tuning_kernel_parameters
  
```



文件数的修改

```
- name: Update /etc/security/limits.conf
  blockinfile:
    dest: /etc/security/limits.conf
    insertbefore: '# End of file'
    block: |
      {{ deploy_user }}        soft        nofile        1000000
      {{ deploy_user }}        hard        nofile        1000000
      {{ deploy_user }}        soft        stack         10240
  when: tuning_kernel_parameters
  
```



软中断的修改（只有在配置文件存在的情况下，才修改，加了一层判断）

```
# modify irqbalance configuration file
- name: check centos configuration file exists
  stat: path=/etc/sysconfig/irqbalance
  register: centos_irq_config_file

- name: modify centos irqbalance configuration file
  lineinfile:
    dest=/etc/sysconfig/irqbalance
    regexp='(?<!_)ONESHOT='
    line='ONESHOT=yes'
  when:
    - tuning_irqbalance_value
    - centos_irq_config_file.stat.exists


```



# deploy steps

> Deploy step include  main direct  ?????
>
> Host.init.production
>
> inventory
>
> /etc/ansible/hosts
>
> tools/host.int

## step1: ansible inventory prepare

two inventory file should modify

1. /etc/ansible/hosts

   used for run ansible command, example as following, should change according to your environment

   ```
   pulsar@ubuntu20:~/apache-pulsar-ansible$ cat /etc/ansible/hosts  |grep -v "^#"
   [servers]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   10.2.0.8
   
   [zookeeper]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   
   [bookies]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   
   
   [all:vars]
   username = pulsar
   ```

   

3. inventory.ini (same as quick start use)

   Used for run ansible-playbook, for deploy pulsar cluster ,

   ```
   pulsar@ubuntu20:~/apache-pulsar-ansible$ cat inventory.ini
   ## Apache Pulsar Cluster
   
   [proxies]
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
   [pushgateway]
   10.2.0.8
   [grafana]
   10.2.0.8
   ...
   skipped
   ...
   ```
   
   
   






## step2: deploy host_preconfig

```
ansible-playbook -i inventory.ini deploy_host_preconfig.yml
```

Modify  hosts config include kernel patameter and swap 



## step3: partition and label zk ,bookeeper device



1. Zk device

   In this example, zk use one disk

   ```
   ansible -i inventory.ini zookeeper -m shell -a "sudo sgdisk /dev/sdc -n 1:0:+50G -n 2:0:+50G"
   
   sudo sgdisk /dev/sdc -n 1:2048  ## 单个分区使用全部磁盘空间
   # then label the partion
   ansible -i inventory.ini zookeeper -m shell -a "sudo sgdisk /dev/sdc -c 1:"zk-data" -c 2:"zk-txlog""
   
   
   sudo sgdisk /dev/sdc -c 1:"zk-data"
   
   ```

   

2. bookie device

   In this example, bookie use two disk, every disk have two portions(one is for journal ,the other is fo ledger)

   ```
   ansible -i inventory.ini bookies -m shell -a "sudo sgdisk /dev/sdd -n 1:0:+40G -n 2:0:+50G"
   ansible -i inventory.ini bookies -m shell -a "sudo sgdisk /dev/sdd -c 1:"journal-0" -c 2:"ledgers-0""
   
   ansible -i inventory.ini bookies -m shell -a "sudo sgdisk /dev/sde -n 1:0:+40G -n 2:0:+50G"
   ansible -i inventory.ini bookies -m shell -a "sudo sgdisk /dev/sde -c 1:"journal-1" -c 2:"ledgers-1""
   
   ## 如果第二个分区想用完所有空间，
   sudo sgdisk /dev/sdd -n 1:0:+40G -n 2:0:
   ```

   > if want to delete disk partion, use `ansible bookies -m shell -a "sudo sgdisk -z /dev/sdc"`
   >
   > 
   >
   > 

3. Check the result

   In one target pulsar node , check the following cmd , you can see the label link to corresponding device

   ```
   [pulsar@redhat2 pulsar]$ ll /dev/disk/by-partlabel/
   total 0
   lrwxrwxrwx. 1 root root 10 Mar 15 10:06 EFI\x20System\x20Partition -> ../../sda1
   lrwxrwxrwx. 1 root root 10 Mar 16 03:25 journal-0 -> ../../sdd1
   lrwxrwxrwx. 1 root root 10 Mar 16 03:25 journal-1 -> ../../sde1
   lrwxrwxrwx. 1 root root 10 Mar 16 03:25 ledgers-0 -> ../../sdd2
   lrwxrwxrwx. 1 root root 10 Mar 16 03:25 ledgers-1 -> ../../sde2
   lrwxrwxrwx. 1 root root 10 Mar 15 14:14 zk-data -> ../../sdc1
   lrwxrwxrwx. 1 root root 10 Mar 15 14:14 zk-txlog -> ../../sdc2
   ```

   

## step4: mkfs zk device 

in tools directory 

```
ansible-playbook -i inventory.ini tools/mkfs-zookeeper.yml
```





## step5: mount zookeeper device 



```
ansible-playbook -i inventory.ini tools/mount-zookeeper.yml
```



in pulsar node check

````
[pulsar@redhat1 pulsar]$ df -h
Filesystem                 Size  Used Avail Use% Mounted on
/dev/sdc1                   50G   53M   47G   1% /opt/pulsar/data/zookeeper
/dev/sdc2                   50G   53M   47G   1% /opt/pulsar/data/zookeeper/txlog

````

And check  fstab

```
[azureuser@redhat2 ~]$ cat /etc/fstab
/dev/disk/by-partlabel/zk-data /opt/pulsar/data/zookeeper ext4 defaults 0 0
/dev/disk/by-partlabel/zk-txlog /opt/pulsar/data/zookeeper/txlog ext4 defaults 0 0

```

## step6: change zk device mount path owner

```
ansible-playbook -i inventory.ini zookeeper -m shell -a "sudo chown -R pulsar:pulsar /opt/pulsar"
```

## step7: deploy zookeeper(metadata service)

```
ansible-playbook -i inventory.ini deploy_zookeeper.yml
```

## step8: start zookeeper

```
ansible-playbook -i inventory.ini playbooks/start_zookeeper.yml
```

## step9: cluster initialize

```
ansible-playbook -i inventory.ini deploy_cluster_initialize.yml
```

## step10: deploy bookeeper

```
ansible-playbook -i inventory.ini deploy_bookkeeper.yml
```

## step11: check bookeeper data directory

after deploy bookie, it will create the following directory for bookie journal and ledger directory, we need mount the coresponding device to these directory

```
[pulsar@redhat2 pulsar]$ tree /opt/pulsar/data/
/opt/pulsar/data/
├── bookkeeper
│   ├── journal-0
│   ├── journal-1
│   ├── ledgers-0
│   └── ledgers-1

```

## step12: mount bookeeper device

> The default conf should change according your practical environment

1. Mkfs to bookeeper journal and ledger device

   

   ```
   
   ansible-playbook -i inventory.ini tools/mkfs-bookeeper.yml
   ```
   
2. Mount journal and ledger device

   ```
   
   ansible-playbook -i inventory.ini tools/mount-bookeeper.yml
   
   ```
   





3. Check the result

   in one target pulsar nodde , run cmd `df -h` should see following info

   ```
   /dev/sdd1                   40G   49M   38G   1% /opt/pulsar/data/bookkeeper/journal-0
   /dev/sdd2                   50G   53M   47G   1% /opt/pulsar/data/bookkeeper/ledgers-0
   /dev/sde1                   40G   49M   38G   1% /opt/pulsar/data/bookkeeper/journal-1
   /dev/sde2                   50G   53M   47G   1% /opt/pulsar/data/bookkeeper/ledgers-1
   ```

4. modify the mount directory owner to pulsar user

   ```
   ansible bookies -m shell -a "sudo chown -R pulsar:pulsar /opt/pulsar"
   ```

   

## Step13: start  bookeeper

Back to main directory

```
ansible-playbook -i inventory.ini playbooks/start_bookkeeper.yml
```

 



## deploy and start broker

````
ansible-playbook -i inventory.ini deploy_broker.yml

ansible-playbook -i inventory.ini start_broker.yml
````



## deploy node_exporter and prometheus ,grafana

```
ansible-playbook -i inventory.ini deploy_node_exporter.yml
ansible-playbook -i inventory.ini deploy_prometheus.yml
ansible-playbook -i inventory.ini deploy_grafana.yml

## start service
ansible-playbook -i inventory.ini playbooks/start_node_exporter.yml
ansible-playbook -i inventory.ini playbooks/start_prometheus.yml
ansible-playbook -i inventory.ini playbooks/start_grafana.yml
```



# common tools for production

These common tool in directory `apache-pulsar-ansible/tools`



```
pulsar@ubuntu20:~$ cat /etc/ansible/hosts  |grep -v "^#"
[servers]
10.2.0.4
10.2.0.6
10.2.0.7

[all:vars]
username = pulsar
```



## install package

> if uninstall just change the state in yum.yml

1. prepare the target host and vars 

   ```
   
   apache-pulsar-ansible/tools/hosts.ini
   
   [servers]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   10.2.0.8
   
   ```

2. Add the package in yum.yml ,then run

   ```
   ansible-playbook -i hosts.ini yum.yml
   ```




## delete partition



```
ansible servers -m shell -a "sudo sgdisk -z /dev/sdc"

```





## partition 



Ansible parted mod have some problem in some linux distribution

so we use gdisk command to partion disk, if target does't have 



1. Check target host config

   ```
   pulsar@ubuntu20:~$ cat /etc/ansible/hosts  |grep -v "^#"
   [servers]
   10.2.0.4
   10.2.0.6
   10.2.0.7
   
   [all:vars]
   username = pulsar
   ```

   

Sdc we want have two partion

```
sgdisk /dev/sdc -n 1:0:+50G -n 2:0:+50G
```

then

```
ansible servers -m shell -a "sudo sgdisk /dev/sdc -n 1:0:+50G -n 2:0:+50G"

```



## partition label(zk)



```
ansible servers -m shell -a "sudo sgdisk /dev/sdc -c 1:"zk-data" -c 2:"zk-txlog""
```



Check target host result

```
[azureuser@redhat2 ~]$ ll /dev/disk/by-partlabel/
total 0
lrwxrwxrwx. 1 root root 10 Mar 15 13:04 zk-data -> ../../sdc1
lrwxrwxrwx. 1 root root 10 Mar 15 13:04 zk-txlog -> ../../sdc2
[azureuser@redhat2 ~]$
```



## partition label(bookie)

This example ,we have two disks for bookie 

```

```



















