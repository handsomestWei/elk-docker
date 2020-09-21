# 搭建ELK日志采集分析监控告警平台
## 平台架构
![](/resources/elk-docker.jpg?raw = true)

## 组件依赖

|组件                              |版本                                |
|:------------------------------------:|------------------------------------|
|[Filebeat](#部署Filebeat)                               |5.5.1|
|[Logstash](#部署Logstash)                              |6.5.4|
|[Elasticsearch](#部署Elasticsearch)                              |6.8.4|
|[Kibana+Sentinl](#部署Kibana)                              |6.8.4|


## 部署Filebeat

### `registry`文件说明
保存filebeat处理日志文件的进度信息。以保证在重启之后能够接着处理未处理过的数据，而无需从头开始   
``` 
mkdir /root/elk/filebeat/data   
cat <<EOF > /root/elk/filebeat/data/registry   
[]   
EOF   
```
docker运行时挂载
```
-v /root/elk/filebeat/data/:/usr/share/filebeat/data \
```


### 配置文件`filebeat.yml`说明
读取指定pod的日志文件
```
/var/log/pods/nameSpace_imageName-*/imageName/*.log 
```

上述文件是软链接，还需filebeat开启配置才能识别
```
symlinks: true 
```

过滤异常日志并关联下文
```
include_lines: ["ERR","error"]
multiline.pattern: '^[["log":"\\u0009]]+(at|\.{3})\b|^Caused by:'
multiline.negate: false
multiline.match: after
```

### 输出到Redis
为避免下游日志组件故障而导致数据丢失，filebeat先把数据写入redis缓存。等下游日志组件故障恢复后，继续从redis缓存消费读取数据。

## 部署Logstash

### 配置文件`filedemo.conf`说明
使用mutate修改数据
```
filter {
    mutate {
	## 移除字段
        remove_field => ["@version","type"]
        ## 移除标签
        remove_tag => ["beats_input_codec_plain_applied"]
    }
}
```
数据存入es，按自然日和日志级别，自动创建索引归集日志
```
if "imageName-err" in [tags] {
        elasticsearch {
        	hosts => "esIpAddr:9200"
          	index => "imageName-err-%{+YYYY.MM.dd}"
        }
        stdout {
		codec => rubydebug
        }
}
```

### sincedb
当input数据源是文件时，logstash读取的偏移量会存储到.sincedb_**文件
```
input {
    file {
        path => "/xxx/*.log"
        type => "log"
        start_position => "beginning"
        sincedb_path => "/xxx/xx"        
        sincedb_write_interval => 10
    }
}
```

## 部署Elasticsearch

### 数据持久化
创建data目录
```
mkdir /root/elk/es/data
chmod 777 /root/elk/es/data
```
docker运行时挂载
```
-v /root/elk/es/data/:/usr/share/elasticsearch/data \
```

## 部署Kibana
### 安装sentinl
插件版本要与kibana版本一致 [sentinl的git地址](https://github.com/lmangani/sentinl)   
也可直接使用整合了sentinl插件的镜像
```
docker pull wjy2020/kibana-with-sentinl:6.8.4
```

### sentinl监控告警配置
#### 配置定时器
<details>
<summary>例：每5分钟执行一次</summary>
<pre><code>"trigger": {
    "schedule": {
      "later": "every 5 minutes"
    }
  },
</code></pre>
</details>

#### 配置查询条件
<details>
<summary>例：查询6分钟前指定索引的所有数据</summary>
<pre><code>"input": {
    "search": {
      "request": {
        "index": [
          "imageName-err*"
        ],
        "body": {
          "query": {
            "bool": {
              "filter": {
                "range": {
                  "@timestamp": {
                    "from": "now-6m"
                  }
                }
              }
            }
          }
        }
      }
    }
  },
</code></pre>
</details>

#### 配置告警条件
<details>
<summary>例：若查询总数大于等于1则触发告警</summary>
<pre><code>"condition": {
    "script": {
      "script": "payload.hits.total >= 1"
    }
  },
</code></pre>
</details>

#### 配置钉钉告警
<details>
<summary>例：发送到钉钉机器人，告警频率为每5分钟一次</summary>
<pre><code>"actions": {
    "Webhook_b32fa3de-0028-40b2-9880-a31a6c6bf188": {
      "name": "dingding-Webhook",
      "throttle_period": "5",
      "webhook": {
        "priority": "low",
        "stateless": false,
        "method": "POST",
        "host": "oapi.dingtalk.com",
        "port": "443",
        "path": "/robot/send?access_token=qwer",
        "body": "{\n    \"msgtype\":\"text\",\n    \"text\":{\n        \"content\":\"XX环境\n{{watcher.title}}有{{payload.hits.total}}条异常日志        \"\n    }\n}",
        "params": {
          "watcher": "{{watcher.title}}",
          "payload_count": "{{payload.hits.total}}"
        },
        "headers": {
          "Content-Type": "application/json"
        },
        "auth": "",
        "message": "",
        "use_https": true
      }
    }
  },
</code></pre>
</details>

## 参考
+ [ES技术栈之filebeat](https://www.elastic.co/cn/beats/filebeat) 
+ [ES技术栈之logstash](https://www.elastic.co/cn/logstash) 
+ [ES中文官网](https://www.elastic.co/cn/elasticsearch/) 
+ [ES技术栈之kibana](https://www.elastic.co/cn/kibana)  
+ [kibana插件sentinl](https://github.com/lmangani/sentinl) 
+ [logstash最佳实践](https://doc.yonyoucloud.com/doc/logstash-best-practice-cn/index.html)


