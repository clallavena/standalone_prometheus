#!/bin/bash

############################
# Author: Clément Allavena #
###########################

## Return 1 if you're not in sudo mode
## Return 2 if a files is missing
## Return 3 if a directory is missing
## Return 4 if emtpy string
## Return 5 if Unknown option error

# <dependence>: #

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
link="https://github.com/prometheus/prometheus/releases/download/v2.9.2/prometheus-2.9.2.linux-amd64.tar.gz"
file_name="prometheus-files"
is_activated="y"

if [ 'root' != `whoami` ]
then
	echo -e  "${RED}Please execute the script with the right privilige"
	exit 1
fi

display_help(){
	cat <<EOF 
usage: ${0##*/} [-h | --help] [-l | --link] <link> [-n | --not-activated]	[-s | --smtp-host] <new-smtp-host>  [-f | --file-name] <new-file-name> [-r | --receiver] <receiver>
	-h | --help
		Show all the option available.
	-l | --link <link>
		Download the version that match with <link>. Default: download the latest version of the module.
	-n | --not-activated
		If this option is on, the script don't activate the service. Default: the service is enabled.
	-f | --file-name <new-file-name>
		If this option is on, <new-file-name> will be the new file name of your downloaded files. Default: prometheus-files
EOF
}

while [ $# -ne 0 ]
do
	case "$1" in
		-h | --help)
			display_help
			exit 0
			;;
		-l | --link)
			if [[ -z "$2" ]]
			then
				echo "usage: $0 -l <link>"
				echo -e "${RED} empty string ${NC}\n"
				exit 4
			fi
			link="$2"
			shift 2
			;;
		-n | --not-activated)
			is_activated="n"
			shift
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
		-*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
	esac
done

echo -e "${GREEN}[INFO] Updating the system..."
sudo yum update -y || sudo dnf update || sudo apt update

echo -e "${GREEN}[INFO] Creation of a Prometheus user and required directories, and make user as the owner${NC}\n"
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

echo -e "${GREEN}[INFO] dowloading the source using the link..${NC}\n"
wget $link
tar -xvf `echo $link | gawk -F"/" '{print $NF}'`
mv `echo $link | gawk -F"/" '{split($NF, A, /[:alnum:]*\.tar/) ; print A[1]}'` $file_name

sudo cp $file_name/prometheus /usr/local/bin/
sudo cp $file_name/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool


sudo cp -r $file_name/consoles /etc/prometheus
sudo cp -r $file_name/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

echo "
global:
  scrape_interval: 10s

scrape_configs:
  # A unique name for one job.
  - job_name: 'prometheus'
    # How frequently to scraped targets from this job
    scrape_interval: 5s
    # Configure this target statically.
    # For a more dynamic configuration, take a look to other methods like <dns_sd_configs>, <file_sd_configs> or <openstack_sd_configs> 
    static_configs:
      - targets: ['localhost:9090'] 
" > /etc/prometheus/prometheus.yml

chown prometheus:prometheus /etc/prometheus/prometheus.yml

echo "Create the prometheus service File at /etc/systemd/system/"
echo "
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
 
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/prometheus.service

echo -e "${GREEN}[INFO] If you want to change your start configuration of prometheus, please check the prometheus.service at /etc/systemd/system/prometheus.service${NC}\n"

echo "reloading of the system service...\n"
sudo systemctl daemon-reload
sudo systemctl start prometheus

echo -e "${GREEN}Don't forget to check the prometheus service with: systemctl status prometheus${NC}\n"
systemctl status prometheus

if [[ $is_activated == "y"  ]]
then
	sudo systemctl enable prometheus
	echo -e "${GREEN}Prometheus service is enable${NC}\n"
fi
