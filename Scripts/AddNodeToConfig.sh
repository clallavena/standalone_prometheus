#!/bin/bash



if [ "root" != `whoami` ]
then
	echo "You are not in sudo mode, pls execute the script with the correct privilege"
	exit 1
fi

echo "
- job_name: 'node_exporter'
  scrape_interval: 5s
  static_configs:
    - targets: ['localhost:9100']
" >> /etc/prometheus/prometheus.yml
