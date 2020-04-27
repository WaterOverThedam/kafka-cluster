#/bin/bash

MASTERS=();
WORKERS=();
HOSTS=();
MANAGER="";
ZOOKEEPERS="";
SERVICES="";
HOME=$(pwd);

. ./functions.sh

stop(){
  echo "stop kafka..."
  for key in ${!WORKERS[@]};do
   echo "-- ${WORKERS[$key]} ..."
   ssh ${WORKERS[$key]} "cd kafka && docker-compose down"
  done
  echo "stop zookeeper..."
  for key in ${!MASTERS[@]};do
   echo "-- ${MASTERS[$key]} ..."
   ssh ${MASTERS[$key]} "cd zookeeper && docker-compose down"
  done
  echo "stop kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker stop kafka_manager &>/dev/null'
}
start(){
  echo "start kafka..."
  for key in ${!WORKERS[@]};do
   echo "-- ${WORKERS[$key]} ..."
   ssh ${WORKERS[$key]} "cd kafka && docker-compose up -d"
  done
  echo "start zookeeper..."
  for key in ${!MASTERS[@]};do
   echo "-- ${MASTERS[$key]} ..."
   ssh ${MASTERS[$key]} "cd kafka && docker-compose up -d"
  done
  echo "start kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker start kafka_manager &>/dev/null'
}

remove(){
  stop
  for host in ${MASTERS[@]};do
      rm -rf /data/zookeeper/{data,datalog,log}
  done
  echo "remove kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker rm -f kafka_manager_cluster &>/dev/null'
}

install(){
 Echo_Cyan "genenate config files ..."
 #生成节点的dock-compose文件，并分发到各个节点
 genenate_config_files
 Echo_Cyan "docker install ..."
 ./docker-install.sh cfg/cluster_hosts_ha 
#Echo_Cyan "image install.."
#image_local_load
 Echo_Cyan "copying bin files ..."
 copy_bin_files
 Echo_Cyan "install and start zookeeper..."
 for host in ${MASTERS[@]};do
   echo "-- ${host} ..."
   ssh ${host} "
    mkdir -p /data/zookeeper/{data,datalog,log} &>/dev/null;
    chmod -R 777 /data/zookeeper && cd zookeeper && docker-compose up -d  "
 done

 Echo_Cyan "install and start kafka..."
 for host in ${WORKERS[@]};do
   echo "-- ${host} ..."
   ssh ${host} "cd kafka && docker-compose up -d "
 done
 echo "install and start kafka_manager..."
 ssh $MANAGER " docker ps|grep kafka_manager_cluster || docker run -d -p 9000:9000 --name kafka_manager_cluster --restart=on-failure -e ZK_HOSTS=${MASTERS[0]}:2181 kafkamanager/kafka-manager:1.3.3.23 " 
}

genenate_config_files(){
 TARGET=template/target
 rm -rf $TARGET
 for key in ${!MASTERS[@]};do
     host=${MASTERS[$key]}
     mkdir -p "$TARGET/${host}/zookeeper"
     sed -e "s,{{ID}},$key,g" -e "s,{{SERVICES}},${SERVICES/$host/0.0.0.0},g" template/zookeeper/docker-compose.tpl >$TARGET/${host}/zookeeper/docker-compose.yml
     rsync -avr $TARGET/${host}/zookeeper $host:~/
 done
 for key in ${!WORKERS[@]};do
     host=${WORKERS[$key]}
     mkdir -p "$TARGET/${host}/kafka"
     sed -e "s/{{ID}}/$key/g;s/{{ZOOKEEPERS}}/${ZOOKEEPERS}/g;s/{{HOST}}/$host/g" template/kafka/docker-compose.tpl >$TARGET/${host}/kafka/docker-compose.yml
     rsync -avr $TARGET/${host}/kafka $host:~/
 done
}

image_local_load(){
  echo "image kafka..."
  for host in ${WORKERS[@]};do
    echo "-- ${host} ..."
    rsync -av images/wurstmeister_kafkalatest.tar.gz $host:~/
    ssh $host 'docker load -i wurstmeister_kafkalatest.tar.gz'
  done
  echo "image zookeeper..."
  for host in ${MASTERS[@]};do
    echo "-- ${host} ..."
    rsync -av images/zookeeperlatest.tar.gz $host:~/
    ssh $host 'docker load -i zookeeperlatest.tar.gz'
  done
  echo "image manager..."
  rsync -av images/kafkamanager_kafka-manager1.3.3.23.tar.gz $MANAGER:~/
  ssh $MANAGER 'docker load -i kafkamanager_kafka-manager1.3.3.23.tar.gz'
}
copy_bin_files(){
 for host in ${HOSTS[@]};do
     rsync -av $HOME/bin/* $host:/usr/local/bin/
 done
}

main(){
 #parameters
 while read host ismanage iszookeeper;do
    [ "$ismanage" == "1" ] && MANAGER=$host
    [ "$iszookeeper" == "1" ] && MASTERS[${#MASTERS[*]}]=$host 
    WORKERS[${#WORKERS[*]}]=$host
    HOSTS[${#HOSTS[*]}]=$host
 done <  ./cfg/cluster_hosts_ha

 ZOOKEEPERS=$(echo "${MASTERS[@]}:2181"|sed 's/ /:2181,/g')
 for key in ${!MASTERS[@]};do
     SERVICES="${SERVICES} server.${key}=${MASTERS[$key]}:2888:3888;2181"
 done
 SERVICES=$(echo $SERVICES)

 if [ ! -z $1 ];then
   $1;
 else
   echo "usage: $0 (start|stop|install|remove)";
 fi
}
main $@
