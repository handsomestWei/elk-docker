#!/bin/bash
docker rm -f kibana
image=wjy2020/kibana-with-sentinl:6.8.4
docker pull $image
docker run -d --name kibana -p 5601:5601 -it \
-v /root/elk/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml \
$image
