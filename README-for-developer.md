

# code directory structure

The repo mainly have the following sub-directory 

```
├── conf                               ## conf template for deploy use
│   ├── bookkeeper
│   │   ├── bookkeeper.conf.2.8.1.j2
│   │   └── bookkeeper.conf.j2
│   ├── broker
│   │   ├── broker.conf.2.8.1.j2
│   │   └── broker.conf.j2
│   └── zookeeper
│       ├── myid.j2
│       ├── zookeeper.conf.2.8.1.j2
│       └── zookeeper.conf.j2
├── group_vars                        ## global variable
│   ├── all.yml
│   ├── grafana.yml
│   ├── monitored_hosts.yml
│   └── prometheus.yml

├── playbooks                         ## start stop pulsar component
│   ├── start_bookkeeper.yml
│   ├── start_broker.yml
│   ├── start_grafana.yml
│   ├── start_node_exporter.yml
│   ├── start_prometheus.yml

├── roles                            ## common used ansible roles
│   ├── bookie
│   ├── broker
│   ├── cluster_initialization
│   ├── config-checker
│   ├── controlmachine
│   ├── grafana
│   ├── host-bootstrap
│   ├── host-common
│   ├── host-system-checker
│   ├── node_exporter
│   ├── prometheus
│   ├── pulsar-common
│   ├── pulsar-post-deploy
│   ├── pulsar-pre-deploy
│   ├── systemd
│   ├── systemd-grafana
│   ├── systemd-node-exporter
│   ├── systemd-prometheus
│   └── zookeeper

└── tools                             ## common tools
    ├── configer                      ## conf distribute after deploy finish
    │   ├── bookkeeper-config-distribute.yml
    │   ├── bookkeeper-config-get.yml
    │   ├── bookkeeper.conf
    │   ├── config-distribute.yml
    │   ├── config-get.yml
    │   └── zookeeper-config-get.yml
    ├── mkfs-bookeeper.yml
    ├── mkfs-zookeeper.yml
    ├── mkfs.yml
    ├── mount-bookeeper.yml
    ├── mount-zookeeper.yml
```



the repo main directory used for pulsar deploy ,the tools sub-directory include some tool for production-deploy, the configer sub-directory in tools used for conf distribute when deploy is finished 

# cluster deploy



mainly use deploy_*.yml files and  sub-directory(include conf ,roles, group_var)

# cluster maintain



## start and stop broker,bookeeper ...

You can use playbooks's yml to start stop pulsar component

if you want to know the status of broker ,bookeeper .. ,you can use following cmd

```
ansible bookies -m shell -a "sudo systemctl status bookie.service"

or

ansible bookies -m shell -a "ps aux |grep java"
```





## conf distribute

when deploy is finished, we want to modify bookeeper or broker conf , you can use tools/configer as following steps

suppose we want to modify bookkeeper conf

in `tools/configer/` directory, get bookeeeper config

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

Then modify one of the bookeeper.conf.*  ,then rename to configer directory, as following

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

Then distribute bookeeper.conf to all bookeeper nodes(in target node,will automatically backup the conf)

```
ansible-playbook -i ../../inventory.ini bookkeeper-config-distribute.yml
```

 After distribute success ,delete the manually created bookkeeper.conf and tmp-subdirectory







