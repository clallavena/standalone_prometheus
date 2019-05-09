# README

### This setup are made for all system on a RedHat OS. Make sure execute these scripts in sudo mode.

---
For each script:
* Return 1: if you're not in sudo mode
* Return 2: if a files is missing
* Return 3: if a directory is missing
* Return 4: if empty string
* Return 5: if Unknown option error

[Default port allocations](https://github.com/prometheus/prometheus/wiki/Default-port-allocations)

## **InstallPrometheus**
InstallPrometheus is a bash script that install a basic configuration of Prometheus.
The script can be dynamic, that mean that's the script can be dynamic with option, it is no longer interactive, because of the automatization of the installation with Ansible we have dropped the interactive version for made this version with option.
A prometheus user is created and his the owner of /etc/prometheus; /var/lib/prometheus (datastorage)

Here is the help view of the option for InstallPrometheus script.
```
usage: InstallPrometheus.sh [-h | --help] [-l | --link] <link> [-n | --not-activated]	[-s | --smtp-host] <new-smtp-host>  [-f | --file-name] <new-file-name> [-r | --receiver] <receiver>
	-h | --help
		Show all the option available.
	-l | --link <link>
		Download the version that match with <link>. Default: download the latest version of the module.
	-n | --not-activated
		If this option is on, the script don't activate the service. Default: the service is enabled.
	-f | --file-name <new-file-name>
		If this option is on, <new-file-name> will be the new file name of your downloaded files. Default: prometheus-files
```
The script install by default a  basic configuration file thus the user can change it as he want.

A basic static configuration are set in **/etc/prometheus/prometheus.yml**\. This look like this:
```yaml
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
```

That means that your prometheus is set statically in localhost:9090.

For more information, look at: [Configuration Documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

A service is created for prometheus at **/etc/systemd/system/prometheus.service**

## **InstallingNodeExporter**
InstallingNodeExporter is a bash script that install node\_exporter which is an exporter provide by [github.com/prometheus](https://github.com/prometheus/), it allow to have metrics for hardware and OS.
A node\_exporter user is created and it has the own of /usr/local/bin/node-exporter-files (default).

A service is created for Node Exporter at /etc/systemd/system/node\_exporter.service
The AddNodeToConfig.sh script add the node exporter to the prometheus config

## **AddNoteToConfig**
That script add to the prometheus configuration a static configuration of node exporter:
```yaml
- job_name: 'node_exporter'
   scrape_interval: 5s
   static_configs:
     - targets: ['localhost:9100']
```
in /etc/prometheus/prometheus.yml

The metrics of your node Exporter are available in the 9100 ports in the localhost machine. (default)

## **InstallGrafana**
That script install the latest stable version (6.1.4) at this day (April 2019)

## **InstallAlertManager**
That script install the AlertManager plugin for prometheus. It established a email alert only available in the intranet of the DSI. With the option you are able to change the smtp host and the receiver if you want. **Check ./InstallAlertManager.sh -h for more information**
A  basic configuration of alertmanager is created at /etc/alertmanager/alertmanager.yml

```yml
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
```
Check the link for an example and the documentation for fill this file.

A basic rules files is created at /etc/prometheus/rules.yml

```yml
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
```
That's a rule that check if the instances on prometheus are down for more than 1 minutes, if they are, firing an alert on alertmanager.


## Uninstall
The uninstall program, uninstall all of the files that have been install with the previous scripts. Disable, stop and remove all of services linked to prometheus.

## Setup
The setup program is a menu that allow to user to install the scripts they want without having access to the source program.
