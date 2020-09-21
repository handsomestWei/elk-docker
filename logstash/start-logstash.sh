#!/bin/bash
docker rm -f logstash
image=docker.elastic.co/logstash/logstash:6.5.4
docker pull $image
docker run -d --name logstash -p 5044:5044 -p 9600:9600 -it \
-v /root/elk/logstash/config/:/usr/share/logstash/config/ \
$image
