version: '2'
services:
 kafka:
  image: wurstmeister/kafka
  container_name: kafka-{{ID}}
  network_mode: "host"
  restart: on-failure
  ports:
    - "9092:9092"
  environment:
   KAFKA_BROKER_ID: {{ID}} 
   KAFKA_ADVERTISED_HOST_NAME: {{HOST}}
   KAFKA_ZOOKEEPER_CONNECT: {{ZOOKEEPERS}} 
