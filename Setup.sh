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
2) Install Prometheus with Grafana
3) Install only Prometheus with basic settings
4) Install AlertManager and add to configuration ( need Prometheus install ! )
5) Uninstall
6) Exit menu 
	"
  
	read answer
	
	case $answer in
		[1]*)
			./Scripts/InstallPrometheus.sh
			./Scripts/InstallingNodeExporter.sh
			./Scripts/AddNodeToConfig.sh
			./Scripts/InstallGrafana.sh
			./Scripts/InstallAlertmanager.sh	
			;;
		[2]*)
			./Scripts/InstallPrometheus.sh
			./Scripts/InstallGrafana.sh
			;;
		[3]*)
			./Scripts/InstallPrometheus.sh
			;;
		[4]*)
			./Scripts/InstallAlertmanager.sh
			;;
		[5]*)
			./Scripts/Uninstall.pl
			;;
		[6]*)
			exit 0
			;;

		esac

		echo "Number not in the menu"
done
