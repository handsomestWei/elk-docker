#!/bin/bash

## 日志文件的进度信息,以保证filebeat在重启之后能够接着处理未处理过的数据，而无需从头开始
#mkdir /root/elk/filebeat/data
#cat <<EOF > /root/elk/filebeat/data/registry
#[]
#EOF

docker rm -f filebeat
image=docker.elastic.co/beats/filebeat:5.5.1
docker pull $image
## 指定root用户运行，才有权限访问挂载的目录
## 挂载pod日志目录、容器目录、配置文件、数据目录
docker run -d --name filebeat --user root -p 5043:5043 -it \
-v /var/log/pods/:/app/logs \
-v /var/lib/docker/containers/:/var/lib/docker/containers \
-v /root/elk/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v /root/elk/filebeat/data/:/usr/share/filebeat/data \
$image
