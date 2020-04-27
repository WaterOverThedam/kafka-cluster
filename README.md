# kafka-cluster
##安装
一、zookeper单点安装kafka集群
1.按实际环境，设置主机参数 cfg/cluster_hosts
kafka主机ip     是否安装kafka-manager  是否安装zookeeper
172.16.208.10 0 1
172.16.208.11 1 0
172.16.208.12 0 0
##配置增加主机可以增加kafka节点

2.设置免密码登陆
free-login.sh

3.多节点一键安装
sh  zookeeper-standalone.sh install

4.其它命令
##停止
sh  zookeeper-standalone.sh stop
##删除
sh  zookeeper-standalone.sh remove
##启动
sh  zookeeper-standalone.sh start

二、zookeper集群方式安装
1.按实际环境，设置主机参数 cfg/cluster_hosts_ha
kafka主机ip     是否安装kafka-manager  是否安装zookeeper
172.16.208.10 0 1
172.16.208.11 1 0
172.16.208.12 0 0
##配置增加主机可以增加kafka节点

2.设置免密码登陆
free-login.sh

3.多节点一键安装
sh  zookeeper-ha.sh install

4.其它命令
##停止
sh  zookeeper-ha.sh stop
##删除
sh  zookeeper-ha.sh remove
##启动
sh  zookeeper-ha.sh start

三、其它
#增加kafka节点命令
--添加节点
docker run --name kafka4  -itd  --restart=onfailure \
-p 9092:9092 \
-e KAFKA_BROKER_ID=4 \
-e KAFKA_ZOOKEEPER_CONNECT=172.16.208.10:2181 \
-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://172.16.208.10:9092 \
-e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092  wurstmeister/kafka

#消息测试
$KAFKA_HOME/bin/kafka-topics.sh  --describe --topic test2 --zookeeper 172.16.208.10:2181 
$KAFKA_HOME/bin/kafka-console-producer.sh --broker-list 172.16.208.10:9092,172.16.208.11:9092,172.16.208.12:9092 --topic test2
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server 172.16.208.10:9092,172.16.208.11:9092,172.16.208.12:9092 --topic test2 --from-beginning
