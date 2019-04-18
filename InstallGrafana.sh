#!/bin/bash

if [ 'root' != `whoami` ]
then
	echo "You are not in sudo mode, pls execute the script with the correct privilege"
	exit 1
fi 

wget https://dl.grafana.com/oss/release/grafana-6.1.4-1.x86_64.rpm
sudo yum localinstall grafana-6.1.4-1.x86_64.rpm

sudo systemctl daemon-reload && sudo systemctl enable grafana-server && sudo systemctl start grafana-server

echo "Grafana 6.1.4 is now active \n Go to http://your.server.ip:3000. The default user and password is admin / admin."
