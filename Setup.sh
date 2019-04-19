#!/bin/bash

if [ "root" != `whoami` ]
then
	echo "You're not in sudo mode, pls execute the scripts with correct privilege"
	exit 1
fi

while true;
do
	echo "
		# Install Prometheus #
			~ Menu ~
1) Install all basics (Grafana, node_exporter, Prometheus, AlertManager w/ rules.yml)
2) Install only Prometheus with basic settings
3) Uninstall
4) Exit menu 
	"
  
	read answer
	
	case $answer in
		[1]*)
			./InstallPrometheus.sh
			./InstallingNodeExporter.sh
			./AddNodeToConfig.sh
			./InstallGrafana.sh
			./InstallAlertmanager.sh	
			;;
		[2]*)
			./InstallPrometheus.sh
			;;
		[3]*)
			./Uninstall.pl
			;;
		[4]*)
			exit 0
			;;

		esac

		echo "Number not in the menu"
done