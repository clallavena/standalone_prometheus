This part of the project, allow you to install prometheus and node exporter with ansible.

## Getting started

First of all, you have to copy/add handler/ and group\_vars/ directories to you /etc/ansible/ files.

In these diretories, you can find the variable of each tasks (group\_vars) and the handler for catching end of tasks (handler)

### Scripts in details

**prometheus-playbook.yml**: is a playbook ansible that install and configure grafana and prometheus in you main server. For the configuration, look at the template prometheus.conf.j2 at template/.

**node-playbook.yml**: is a playbook ansible that install and configure node explorer on hosts that you want.

**config-check.yml**: is a playbook ansible that check if the actual configuration of prometheus is matching the template. If not, changed it for matching the template. Then reload the configuration without stoping the service.

**check.yml**: is a playbook ansible that you should launch first. It allowed you to check and install the correct packages for your installation (ansible, epel for yum etc...)
