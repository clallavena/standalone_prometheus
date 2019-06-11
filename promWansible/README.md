This part of the project, allow you to install prometheus and node exporter with ansible.

## Getting started

First of all, you have to copy/add **handler/** and **group\_vars/** directories to you **/etc/ansible/** files.

In these diretories, you can find the variable of each tasks (group\_vars) and the handler for catching end of tasks (handler)

## How to add an exporter ?

You have to add in group\_vars of your /etc/ansible, the new exporter that you want to add. And you have to name it by the same name as in your **host** file.
In your host file, add a group of host that you want to have this exporter.

Then in your variable file in your group\_vars directory you have to complete this variable:

```yml
name: ''
gitAuthor: ''
port: ''
serviceName: ''
groupId: ''
userId: ''
exec_command: 
version: ''
```

Example for apache\_exporter:

```yml
name: 'apache'
gitAuthor: 'Lusitaniae'
port: '9117'
serviceName: 'apache_exporter'
groupId: 'apache_exporter'
userId: 'apache_exporter'
exec_command: /usr/local/bin/apache_exporter
version: '0.6.0'
```

After that, you will have to play the **global\_exporter** playbook.
Make sure that the **host** in your playbook is the exporter that you want to install

After all add of exporters make sure to modify the configuration template of Prometheus in the **templates/** directories. And add or remove what you want to scrape in prometheus. After modifying this file, play the **config-check** playbook, it check and reload the configuration of prometheus without stoping the service.

### Add Lamp
Playbook are available for the installation of lamp, **lamp\-install** install all the necessary packets for Lamp and allow the server status.

### Scripts in details

**prometheus-playbook.yml**: is a playbook ansible that install and configure grafana and prometheus in you main server. For the configuration, look at the template prometheus.conf.j2 at template/.

**node-playbook.yml**: is a playbook ansible that install and configure node explorer on hosts that you want.

**config-check.yml**: is a playbook ansible that check if the actual configuration of prometheus is matching the template. If not, changed it for matching the template. Then reload the configuration without stoping the service.

**check.yml**: is a playbook ansible that you should launch first. It allowed you to check and install the correct packages for your installation (ansible, epel for yum etc...)

**global\_exporter**: is a playbook ansible that can install any exporter. (cf. [How to add an exporter?](https://gitlab.dsi.uca.fr/infra-sys/monitoring/tree/master/promWansible#how-to-add-an-exporter-))

**init-check**: is a playbook ansible that check if the daemon has been modified. If it has, reload it.
