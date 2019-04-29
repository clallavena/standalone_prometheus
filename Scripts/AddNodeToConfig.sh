#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


if [ "root" != `whoami` ]
then
	echo -e "${RED}[ERROR]You are not in sudo mode, pls execute the script with the correct privilege"
	exit 1
fi

echo "
	- job_name: 'node_exporter'
  	scrape_interval: 5s
  	static_configs:
    	- targets: ['localhost:9100']
" >> /etc/prometheus/prometheus.yml

echo -e "${GREEN}[INFO] ${NC} Check if the status is ok"
systemctl status prometheus

