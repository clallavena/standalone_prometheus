#!/bin/bash

############################
# Author: Clément Allavena #
############################

## Return 1 if you're not in sudo mode
## Return 2 if a files is missing
## Return 3 if a directory is missing
## Return 4 if empty string
## Return 5 if Unknown option error

# <dependence>: #

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
file_name=node_exporter
link="https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz"
is_activated="y"

echo -e "${RED}[INFO]Make sure you execute this script in sudo mode"

if [ 'root' != `whoami` ]
then
	echo -e "${RED}You are not in sudo mode, pls execute the script with the correct privilege"
	exit 1
fi

display_help(){
	cat <<EOF 
usage: ${0##*/} [-h | --help] [-l | --link] <link> [-n | --not-activated]	[-f | --file-name] <new-file-name> 
	-h | --help
		Show all the option available.
	-l | --link <link>
		Download the version that match with <link>. Default: download the latest version of the module.
	-n | --not-activated
		If this option is on, the script don't activate the service. Default: the service is enabled.
	-f | --file-name <new-file-name>
		If this option is on, <new-file-name> will be the new file name of your downloaded files. Default: node_exporter
EOF
}

while [ $# -ne 0]
do
	case "$1" in
		-h | --help)
			display_help
			exit 0
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
		-*)
			echo "Error: Unknow option:$1" >&2
			display_help
			exit 5
			;;
	esac
done

useradd --no-create-home --shell /bin/false/ node_exporter

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

if [[ $is_activated == "y" ]]
then
	sudo systemctl enable node_exporter
fi

