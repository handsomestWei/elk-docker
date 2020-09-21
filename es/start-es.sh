#!/bin/bash

#mkdir /root/elk/es/data
#chmod 777 /root/elk/es/data

docker rm -f elasticsearch
image=elasticsearch:6.8.4
docker pull $image
docker run -d --name elasticsearch --net host --user root -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -it \
-v /root/elk/es/data/:/usr/share/elasticsearch/data \
-v /root/elk/es/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
$image
