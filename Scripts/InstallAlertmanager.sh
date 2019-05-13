#!/bin/bash

## Return 1 if you're not in sudo mode
## Return 2 if a files is missing
## Return 3 if a directory is missing
## Return 4 if emtpy string
## Return 5 if Unknown option error

# <dependence>: InstallPrometheus.sh #

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


file_name=alertmanager
smtpHost=mtarelay.dsi.uca.fr:25
receiver="change@email.com"
link="https://github.com/prometheus/alertmanager/releases/download/v0.17.0/alertmanager-0.17.0.linux-amd64.tar.gz"

is_activated="y"

display_help(){
	cat <<EOF 
usage: ${0##*/} [-h | --help] [-l | --link] <link> [-n | --not-activated]	[-s | --smtp-host] <new-smtp-host>  [-f | --file-name] <new-file-name> [-r | --receiver] <receiver>
	-h | --help
		Show all the option available.
	-l | --link <link>
		Download the version that match with <link>. Default: download the latest version of the module.
	-n | --not-activated
		If this option is on, the script don't activate the service. Default: the service is enabled.
	-s | --smtp-host <new-smtp-host>
		If this option is on, <new-smtp-host> will be the new smtp host in the configuration file. Default: smtp host of mtarelay.
	-f | --file-name <new-file-name>
		If this option is on, <new-file-name> will be the new file name of your downloaded files. Default: alertmanager
	-r | --receiver <receiver>
		If this option is on, <receiver> will be the new receiver for email configuration. Default: change@email.com
EOF
}


if [ "root" != `whoami` ]
then
	echo -e  "${RED}You're not in sudo mode, pls execute this script with the correct privilege"
	exit 1
fi

while [ $# -ne 0 ]
do
	case "$1" in
		-h | --help)
			display_help
			exit 0
			;;
		-l | --link)
			link="$2"
			shift 2
			;;
		-n | --not-activated)
			is_activated="n"
			shift
			;;
		-s | --smtp-host)
			if [[ -z "$2" ]]
			then
				echo "usage: ./InstallAlertmanager.sh -s <new-smtp-host>"
				echo -e "${RED} empty string ${NC}\n"
				exit 4
			fi
			smtpHost="$2"
			shift 2
			;;
		-f | --file-name)
			if [[ -z "$2" ]]
			then
				echo "usage: $0 -f <new-file-name>"
				echo -e "${RED} empty string ${NC}\n"
				exit 4
			fi
			file_name="$2"
			shift 2
			;;
		-r | --receiver)
			if [[ -z "$2" ]]
			then
				echo "usage: $0 -r <receiver>"
				echo -e "${RED} empty string ${NC}\n"
				exit 4
			fi
			receiver="$2"
			shift 2
			;;
		-*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
	esac
done


if [[ ! -d /etc/prometheus/  ]]
then
	echo -e "${RED} Directory /etc/prometheus/ does not exist, pls check that you have done the Prometheus install correctly ${NC}\n"
	exit 3
fi

if [[ ! -f /etc/prometheus/prometheus.yml  ]]
then
	echo -e "${RED} Files /etc/prometheus/prometheus.yml does not exist, and it is needed for the installation of AlertManager, pls check that you have done the Prometheus install correctly ${NC}\n"
	exit 2
fi

echo -e  "${GREEN}dowloading the source using the link..${NC}\n"
wget $link
tar -xvf `echo $link | gawk -F"/" '{print $NF}'`
mv `echo $link | gawk -F"/" '{split($NF, A, /[:alnum:]*\.tar/) ; print A[1]}'` $file_name

sudo cp $file_name/alertmanager /usr/local/bin

echo -e  "${GREEN}Creation of the user alertmanager...${NC}\n"
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager/data 
sudo chown -R alertmanager. /var/lib/alertmanager

echo -e  "${GREEN}Configuration of alertmanager...${NC}\n"

echo -e  "${GREEN}Creation of the configuration file in /etc/alertmanager/alertmanager.yml${NC}\n"

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
" > /etc/prometheus/rules.yml

if [[ $is_activated == "y"  ]] then
	sudo systemctl enable alertmanagers
fi
