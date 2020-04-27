version: '2'
services:
 zookeeper-{{ID}}:
  image: zookeeper
  container_name: zookeeper-{{ID}}
  restart: on-failure
  network_mode: "host"
  ports:
    - 2181:2181
    - 2888:2888
    - 3888:3888
  volumes:
    - "/data/zookeeper/data:/data"
    - "/data/zookeeper/datalog:/datalog"
    - "/data/zookeeper/log:/log"
  environment:
    ZOO_MY_ID: {{ID}}
    ZOO_SERVERS: {{SERVICES}} 

