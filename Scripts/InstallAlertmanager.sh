#!/bin/bash

## Return 1 if you're not in sudo mode
## Return 2 if a files is missing
## Return 3 if a directory is missing


GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


file_name=alertmanager
smtpHost=mtarelay.dsi.uca.fr:25

if [ "root" != `whoami` ]
then
	echo -e  "${RED}You're not in sudo mode, pls execute this script with the correct privilege"
	exit 1
fi

if [[ ! -d /etc/prometheus/  ]]
then
	echo -e "${RED} Directory /etc/prometheus/ does not exist, pls check that you have done the Prometheus install correctly "
	exit 3
fi

if [[ ! -f /etc/prometheus/prometheus.yml  ]]
then
	echo -e "${RED} Files /etc/prometheus/prometheus.yml does not exist, and it is needed for the installation of AlertManager, pls check that you have done the Prometheus install correctly "
	exit 2
fi

echo -e "${GREEN}Get the link of the latest version of alertmanager at : https://prometheus.io/download/#alertmanager, Linux binary"

read link

echo -e "${GREEN}Is this the good link ? $link"
echo "[y/N]: "
read answer

if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 1
fi

echo -e  "${GREEN}dowloading the source using the link.."
wget $link
tar -xvf `echo $link | gawk -F"/" '{print $NF}'`
mv `echo $link | gawk -F"/" '{split($NF, A, /[:alnum:]*\.tar/) ; print A[1]}'` $file_name

sudo cp $file_name/alertmanager /usr/local/bin

echo -e  "${GREEN}Creation of the user alertmanager..."
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager/data 
sudo chown -R alertmanager. /var/lib/alertmanager

echo -e  "${GREEN}Configuration of alertmanager..."
echo -e  "${GREEN}Do you want to change the smtp host ? (default: mtarelay.dsi.uca.fr:25) [y/N]"
read answer

if [[ $answer =~ [yY].* ]]
then
  echo "Enter the new smtp host: "
	read smtpHost
fi

echo -e  "${GREEN}Creation of the configuration file in /etc/alertmanager/alertmanager.yml"
echo -e  "${GREEN}Enter an email for your basic receiver: "
read receiver

while [[ -z $receiver ]]
do
	echo -e "${RED}[ERROR] Empty string"
	read receiver
done

echo "
# Documentation: https://prometheus.io/docs/alerting/configuration/
# Good example: https://github.com/prometheus/alertmanager/blob/master/doc/examples/simple.yml 

global:
  resolve_timeout: 5m

  smtp_smarthost: $smtpHost
  smtp_from: 'alertmanager@infra.dsi.uca.fr'
  smtp_require_tls: false

route:
#  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email'

# Can define several  'routes:' field which is a child route tree.
# Theses routes can perfome a regular expression were alert can match with this regex.
# Allow to catch alert and permit to define a special receiver for each alert (dev, infra, ...)
# example: https://github.com/prometheus/alertmanager/blob/master/doc/examples/simple.yml


receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
- name: 'email'
  email_configs:
  - to: '$receiver'

# Mute any warning-level notifications if the same alertis already critical
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
#    equal: ['alertname', 'cluster', 'service']
" > /etc/alertmanager/alertmanager.yml

echo "Creation of the service at /etc/systemd/system/alertmanager.service..."

echo "
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/data

[Install]
WantedBy=mutli-user.target_match
" > /etc/systemd/system/alertmanager.service

sudo systemctl daemon-reload
sudo systemctl start alertmanager.service
sudo systemctl status alertmanager

echo "
rule_files:
	- \"rules.yml\"

alerting:
  alertmanagers:
   - static_configs:
     - targets: ['localhost:9093']
" >> /etc/prometheus/prometheus.yml

echo "
groups:
  - name: up
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: page
      annotations:
        summary: \"Instance {{ \$labels.instance }} down\"
        description: \"{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 1 minutes.""
" >> /etc/prometheus/rules.yml

echo "Do you want to enable the alertmanager.service ? [y/N]"

read answer

if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 0
fi

sudo systemctl enable alertmanagers

