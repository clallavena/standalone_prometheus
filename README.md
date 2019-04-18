# README

### This setup are made for all system on a RedHat OS. Make sure execute these scripts in sudo mode.

---


## **InstallPrometheus**
InstallPrometheus is a bash script that install a basic configuration of Prometheus. The script is dynamic and do not depend on a special version of prometheus.
The user has to get the latest version on [the Prometheus Github](https://prometheus.io/download) for Linux binary. Then the script will create a user with no home and no shell name prometheus.
The prometheus executables files are copied in **/usr/local/bin** , that mean that the downloaded files are no longer needed.
The prometheus consoles files are copied in **/etc/prometheus** .
The prometheus user is set the owner of this files.

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


