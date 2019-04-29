#!/bin/bash

############################
# Author: Clément Allavena #
############################

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
file_name=node_exporter

echo -e "${RED}[INFO]Make sure you execute this script in sudo mode"

if [ 'root' != `whoami` ]
then
	echo -e "${RED}You are not in sudo mode, pls execute the script with the correct privilege"
	exit 1
fi

useradd --no-create-home --shell /bin/false/ node_exporter

echo "Go to https://github.com/prometheus/node_exporter/releases/ and get the latest download link for Linux binary "

read link

echo "Is this the good link ? $link"
echo "[y/N]: "
read answer

if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 1
fi


echo -e "${GREEN}[INFO]dowloading the source using the link.."
wget $link                                                                                                                                                                           
tar -xvf `echo $link | gawk -F"/" '{print $NF}'`
mv `echo $link | gawk -F"/" '{split($NF, A, /[:alnum:]*\.tar/) ; print A[1]}'` $file_name

cp $file_name/node_exporter /usr/local/bin
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf $file_name

echo -e "${GREEN}[INFO]Making Node Exporter to run automaticaly on each boot..."
echo "
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/node_exporter.service

echo -e "${GREEN}[INFO]If you want to change the service file, go check in /etc/systemd/system"

sudo systemctl daemon-reload
sudo systemctl start node_exporter

echo -e "${GREEN}[INFO]Check if the status is alright "
sudo systemctl status node_exporter
echo -e "${GREEN}[INFO]do you want to enable the service ? [y/N]"
read answer


if [[ $answer =~ [nN].* ]] || [[ -z $answer ]]
then
  exit 1
fi

if [[ -z $answer  ]] || [[ $answer =~ [nN].* ]]
then
	echo -e "${GREEN}[INFO]The service is not enable"
	echo -e "${GREEN}[INFO]Don't forget to add a job_name: 'node_exporter' to the configuration file of prometheus! (cf README)"
	exit 0
fi

sudo systemctl enable node_exporter

echo -e "${GREEN}[INFO]Don't forget to add a job_name: 'node_exporter' to the configuration file of prometheus! (cf README)"
