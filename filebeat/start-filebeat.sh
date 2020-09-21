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
docker run -d --name filebeat --user root -p 5043:5043 -it \
## 挂载pod目录
-v /var/log/pods/:/app/logs \
## 挂载容器目录
-v /var/lib/docker/containers/:/var/lib/docker/containers \
## 挂载配置文件
-v /root/elk/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
## 挂载数据目录
-v /root/elk/filebeat/data/:/usr/share/filebeat/data \
$image
