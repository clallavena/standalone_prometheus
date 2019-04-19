#!/bin/bash

############################
# Author: Clément Allavena #
###########################

if [ 'root' != `whoami` ]
then
	echo "Please execute the script with the right privilige"
	exit 1
fi

echo "Updating the system..."
sudo yum update -y || sudo dnf update || sudo apt update

echo "Go to https://prometheus.io/download/ and get the latest download link for Linux binary "

read link

echo "Is this the good link ? $link"
echo "[y/N]: "
read answer

if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 1
fi


echo "Creation of a Prometheus user and required directories, and make user as the owner"
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

echo "dowloading the source using the link.."
wget $link
tar -xvf `echo $link | gawk -F"/" '{print $NF}'`
mv `echo $link | gawk -F"/" '{split($NF, A, /[:alnum:]*\.tar/) ; print A[1]}'` prometheus-files

sudo cp prometheus-files/prometheus /usr/local/bin/
sudo cp prometheus-files/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool


sudo cp -r prometheus-files/consoles /etc/prometheus
sudo cp -r prometheus-files/console_libraries /etc/prometheus
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

echo "If you want to change your start configuration of prometheus, please check the prometheus.service at /etc/systemd/system/prometheus.service"

echo "reloading of the system service..."
sudo systemctl daemon-reload
sudo systemctl start prometheus

echo "Don't forget to check the prometheus service with: systemctl status prometheus"
systemctl status prometheus

echo "Do you want to enable the prometheus service ? [y/N]"
read answer

if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 1
fi

sudo systemctl enable prometheus
"Prometheus service is enable"
