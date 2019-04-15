#!/bin/bash

# this install script will work on the AWS Ubuntu 18 image (ONLY)

# no need to sudo su, EC2 user-data scripts are run as root
# update the image gives prompts so skip for now
# apt-get update
# apt-get upgrade -y
# apt-get dist-upgrade -y
# apt-get autoremove -y
# apt-get autoclean -y

# install Java (OpenJDK 8)
add-apt-repository ppa:openjdk-r/ppa -y
apt-get install openjdk-8-jdk -y
# setup the app location and download the jar - runs Tomcat on 8080
mkdir /srv/app
curl -o /srv/app/app.jar https://s3.amazonaws.com/acg-cors.kevinbaynes.com/public-jars/simple-spring-data-jpa-h2-0.0.1.jar
curl -o /srv/app/app-onstartup.sh https://raw.githubusercontent.com/kbaynes/ec2-l2-java-mariadb/java-only/app-onstartup.sh
# make the ec2 user the owner of the app service folder
chown -R ubuntu: /srv/app
# map calls to port 80 on this machine to port 8080, where the java-app is listening
# otherwise, if we try to run java-app on port 80, it must be run as root (security problem)
# setup systemd unit file to run iptable mapping as a service (iptables are not persistent)
curl -o /etc/systemd/system/java-app-onstartup.service https://raw.githubusercontent.com/kbaynes/ec2-l2-java-mariadb/java-only/app-onstartup.service
systemctl enable java-app-onstartup
systemctl start java-app-onstartup
# setup systemd unit file to run spring boot app as a service
curl -o /etc/systemd/system/java-app.service https://raw.githubusercontent.com/kbaynes/ec2-l2-java-mariadb/java-only/app.service
systemctl enable java-app
systemctl start java-app
