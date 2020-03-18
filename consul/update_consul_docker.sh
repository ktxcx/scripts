#!/bin/bash
env=${1}

case $env in
        stage)
                consul_version="1.7.2"
                ;;
        *)
                consul_version="1.6.1"
                ;;
esac


# stopping consul-related containers
docker ps | grep "consul-" | cut -d. -f1 | awk '{print $1}' | xargs docker stop

# removing consul-related containers
docker container ls -a | grep "consul-" | cut -d. -f1 | awk '{print $1}' | xargs docker container rm

# running reverse consul agent
docker run -d --net=host --restart=unless-stopped -h `curl -s http://169.254.169.254/latest/meta-data/instance-id` --name consul-agent -v /opt/consul:/consul/data -v /var/run/docker.sock:/var/run/docker.sock consul:${consul_version} agent -data-dir=/consul/data -client=0.0.0.0 -join consul.${env}.doozer.internal -advertise `curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

# running service registrator with autoclean (-cleanup) flag to remove dangling services
docker run -d --net=host --restart=unless-stopped -h INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id` --name consul-registrator \
        -v /var/run/docker.sock:/tmp/docker.sock \
        gliderlabs/registrator -cleanup -ip `curl -s http://169.254.169.254/latest/meta-data/local-ipv4` consul://localhost:8500
