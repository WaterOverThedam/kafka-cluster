#/bin/bash

MASTER="";
WORKERS=();
MANAGER="";

stop(){
  echo "stop kafka..."
  for key in ${!WORKERS[@]};do
   echo "-- ${WORKERS[$key]} ..."
   ssh ${WORKERS[$key]} "docker stop kafka${key} &>/dev/null"
  done
  echo "stop zookeeper..."
  echo "-- $MASTER"
  ssh $MASTER 'docker stop zookeeper &>/dev/null'
  echo "stop kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker stop kafka_manager &>/dev/null'
}
start(){
  echo "start kafka..."
  for key in ${!WORKERS[@]};do
   echo "-- ${WORKERS[$key]} ..."
   ssh ${WORKERS[$key]} "docker start kafka${key} &>/dev/null"
  done
  echo "start zookeeper..."
  echo "-- $MASTER"
  ssh $MASTER 'docker start zookeeper &>/dev/null'
  echo "start kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker start kafka_manager &>/dev/null'
}

remove(){
  echo "remove kafka..."
  for key in ${!WORKERS[@]};do
   echo "-- ${WORKERS[$key]} ..."
   ssh ${WORKERS[$key]} "docker rm -f kafka${key} &>/dev/null"
  done
  echo "remove zookeeper..."
  echo "-- $MASTER"
  ssh $MASTER 'docker rm -f zookeeper &>/dev/null'
  echo "remove kafka_manager..."
  echo "-- $MANAGER"
  ssh $MANAGER 'docker rm -f kafka_manager &>/dev/null'
}

install(){
 echo "docker install ..."
 ./docker-install.sh cfg/cluster_hosts
 #echo "image install.."
 #image_local_load
 echo "install and start zookeeper..."
 ssh $MASTER "docker ps|grep zookeeper || docker run --name zookeeper -itd  -p 2181:2181 --restart=on-failure  wurstmeister/zookeeper"
 echo "install and start kafka..."
 for key in ${!WORKERS[@]};do
   host=${WORKERS[$key]}
   echo "-- ${host} ..."
   ssh ${host} "docker ps|grep kafka${key} ||
docker run --name kafka${key}  -itd  --restart=on-failure \
-p 9092:9092 \
-e KAFKA_BROKER_ID=${key} \
-e KAFKA_ZOOKEEPER_CONNECT=172.16.208.10:2181 \
-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://${host}:9092 \
-e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092  wurstmeister/kafka
"
 done
 echo "install and start kafka_manager..."
 ssh $MANAGER "docker ps|grep kafka_manager || docker run -itd --name kafka_manager --restart=on-failure  -p 9000:9000 -e ZK_HOSTS=${MASTER}:2181 -e APPLICATION_SECRET='letmein' sheepkiller/kafka-manager:latest"
}

image_local_load(){
  echo "--image kafka"
  for host in ${WORKERS[@]};do
    rsync -av images/wurstmeister_kafkalatest.tar.gz $host:~/
    ssh $host 'docker load -i wurstmeister_kafkalatest.tar.gz'
  done
  echo "--image zookeeper"
  rsync -av  images/wurstmeister_zookeeperlatest.tar.gz $MASTER:~/
  ssh $MASTER 'docker load -i wurstmeister_zookeeperlatest.tar.gz'
  echo "--image manager"
  rsync -av  images/sheepkiller_kafka-managerlatest.tar.gz $MANAGER:~/
  ssh $MANAGER 'docker load -i sheepkiller_kafka-managerlatest.tar.gz'
}

main(){
 while read host ismanage iszookeeper;do
    [ "$ismanage" == "1" ] && MANAGER=$host
    [ "$iszookeeper" == "1" ] && MASTER=$host
    WORKERS[${#WORKERS[*]}]=$host
 done <  ./cfg/cluster_hosts

 if [ ! -z $1 ];then
   $1;
 else
   echo "usage: $0 (start|stop|install|remove)";
 fi
}
main $@
