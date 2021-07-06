#!/bin/bash

minikube delete
minikube delete --all

export MINIKUBE_HOME=~/goinfre
minikube config set memory 2048
minikube config set disk-size 4096
echo -e "\033[43;31m                       \033[0m"
echo -e "\033[31;1m->  minikube start ... \033[0m"
echo -e "\033[43;31m                       \033[0m"
minikube start --driver=virtualbox
eval $(minikube -p minikube docker-env)
MINIKUBE_IP=$(minikube ip)

# nginx image build
echo -e "\033[43;31m                          \033[0m"
echo -e "\033[31;1m->  nginx image build ... \033[0m"
echo -e "\033[43;31m                          \033[0m"
sed -i '' "s/MINIKUBE_IP/$MINIKUBE_IP/g" ./srcs/nginx/srcs/default.conf
docker build ./srcs/nginx/ -t nginx42
sed -i '' "s/$MINIKUBE_IP/MINIKUBE_IP/g" ./srcs/nginx/srcs/default.conf

# mysql image build
echo -e "\033[43;31m                          \033[0m"
echo -e "\033[31;1m->  mysql image build ... \033[0m"
echo -e "\033[43;31m                          \033[0m"
sed -i '' "s/MINIKUBE_IP/$MINIKUBE_IP/g" ./srcs/mysql/srcs/wordpress.sql
docker build ./srcs/mysql/ -t mysql42
sed -i '' "s/$MINIKUBE_IP/MINIKUBE_IP/g" ./srcs/mysql/srcs/wordpress.sql

# phpmyadmin image build
echo -e "\033[43;31m                               \033[0m"
echo -e "\033[31;1m->  phpMyAdmin image build ... \033[0m"
echo -e "\033[43;31m                               \033[0m"
sed -i '' "s/MINIKUBE_IP/$MINIKUBE_IP/g" ./srcs/phpmyadmin/srcs/config.inc.php
docker build ./srcs/phpmyadmin/ -t phpmyadmin42
sed -i '' "s/$MINIKUBE_IP/MINIKUBE_IP/g" ./srcs/phpmyadmin/srcs/config.inc.php

# wordpress image build
echo -e "\033[43;31m                              \033[0m"
echo -e "\033[31;1m->  wordpress image build ... \033[0m"
echo -e "\033[43;31m                              \033[0m"
docker build ./srcs/wordpress/ -t wordpress42

# ftps image build
echo -e "\033[43;31m                         \033[0m"
echo -e "\033[31;1m->  ftps image build ... \033[0m"
echo -e "\033[43;31m                         \033[0m"
sed -i '' "s/MINIKUBE_IP/$MINIKUBE_IP/g" ./srcs/ftps/srcs/vsftpd.conf
docker build ./srcs/ftps/ -t ftps42
sed -i '' "s/$MINIKUBE_IP/MINIKUBE_IP/g" ./srcs/ftps/srcs/vsftpd.conf

# influxdb image build
echo -e "\033[43;31m                             \033[0m"
echo -e "\033[31;1m->  InfluxDB image build ... \033[0m"
echo -e "\033[43;31m                             \033[0m"
docker build ./srcs/influxdb/ -t influxdb42

# telegraf image build
echo -e "\033[43;31m                             \033[0m"
echo -e "\033[31;1m->  telegraf image build ... \033[0m"
echo -e "\033[43;31m                             \033[0m"
docker build ./srcs/telegraf/ -t telegraf42

# grafana image build
echo -e "\033[43;31m                            \033[0m"
echo -e "\033[31;1m->  grafana image build ... \033[0m"
echo -e "\033[43;31m                            \033[0m"
docker build ./srcs/grafana/ -t grafana42

# metallb (LoadBalancer)
echo -e "\033[43;31m                         \033[0m"
echo -e "\033[31;1m->  metallb ~ing ...     \033[0m"
echo -e "\033[43;31m                         \033[0m"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
sed -i '' "s/MINIKUBE_IP/$MINIKUBE_IP/g" ./srcs/metallb/metallb.yaml
kubectl apply -f ./srcs/metallb/metallb.yaml
sed -i '' "s/$MINIKUBE_IP/MINIKUBE_IP/g" ./srcs/metallb/metallb.yaml

# nginx yaml apply
echo -e "\033[43;31m                         \033[0m"
echo -e "\033[31;1m->  apply nginx.yaml ... \033[0m"
echo -e "\033[43;31m                         \033[0m"
kubectl apply -f ./srcs/nginx/srcs/nginx.yaml

# mysql yaml apply
echo -e "\033[43;31m                         \033[0m"
echo -e "\033[31;1m->  apply mysql.yaml ... \033[0m"
echo -e "\033[43;31m                         \033[0m"
kubectl apply -f ./srcs/mysql/srcs/mysql.yaml

# phpmyadmin yaml apply
echo -e "\033[43;31m                              \033[0m"
echo -e "\033[31;1m->  apply phpmyadmin.yaml ... \033[0m"
echo -e "\033[43;31m                              \033[0m"
kubectl apply -f ./srcs/phpmyadmin/srcs/phpmyadmin.yaml

# wordpress yaml apply
echo -e "\033[43;31m                             \033[0m"
echo -e "\033[31;1m->  apply wordpress.yaml ... \033[0m"
echo -e "\033[43;31m                             \033[0m"
kubectl apply -f ./srcs/wordpress/srcs/wordpress.yaml

# ftps yaml apply
echo -e "\033[43;31m                        \033[0m"
echo -e "\033[31;1m->  apply ftps.yaml ... \033[0m"
echo -e "\033[43;31m                        \033[0m"
kubectl apply -f ./srcs/ftps/srcs/ftps.yaml

# influxdb yaml apply
echo -e "\033[43;31m                            \033[0m"
echo -e "\033[31;1m->  apply influxdb.yaml ... \033[0m"
echo -e "\033[43;31m                            \033[0m"
kubectl apply -f ./srcs/influxdb/srcs/influxdb.yaml

# telegraf yaml apply
echo -e "\033[43;31m                            \033[0m"
echo -e "\033[31;1m->  apply telegraf.yaml ... \033[0m"
echo -e "\033[43;31m                            \033[0m"
kubectl apply -f ./srcs/telegraf/srcs/telegraf.yaml

# grafana yaml apply
echo -e "\033[43;31m                           \033[0m"
echo -e "\033[31;1m->  apply grafana.yaml ... \033[0m"
echo -e "\033[43;31m                           \033[0m"
kubectl apply -f ./srcs/grafana/srcs/grafana.yaml

printf "minikube ip: ${MINIKUBE_IP}\n"

minikube dashboard
