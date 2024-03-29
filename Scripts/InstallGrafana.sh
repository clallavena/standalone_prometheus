#!/bin/bash

## Return 1 if you're not in sudo mode
## Return 2 if a files is missing
## Return 3 if a directory is missing

# <dependence>: #

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


if [ 'root' != `whoami` ]
then
	echo -e "${RED}You are not in sudo mode, pls execute the script with the correct privilege${NC}"
	exit 1
fi 

wget https://dl.grafana.com/oss/release/grafana-6.1.4-1.x86_64.rpm
sudo yum localinstall grafana-6.1.4-1.x86_64.rpm

sudo systemctl daemon-reload && sudo systemctl enable grafana-server && sudo systemctl start grafana-server

echo "${GREEN}Grafana 6.1.4 is now active \n Go to http://your.server.ip:3000. The default user and password is admin / admin.${NC}"
