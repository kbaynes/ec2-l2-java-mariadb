# Setup Spring Boot & MariaDB on Amazon EC2 Linux 2 AMI

## Overview

This project provides easy setup of an AWS EC2 Linux 2 AMI instance, which runs a Java Spring Boot jar which connects to a MariaDB instance running the same server. The EC2 instance can be up and running in less than 5 minutes, and works with the [simple-spring-data-jpa-mysql](https://github.com/kbaynes/simple-spring-data-jpa-mysql) project, which provides a RESTful interface to a table on the DB. To get started fast, skip to the *EC2 Setup* section.

## Branch Master
The master branch sets up MariaDB and runs the jar. The Java-only branch does not set up MariaDB and only runs the jar.

## Goal

The goal of this project is to demonstrate how to quickly (less than 5 minutes) launch an Amzazon Linux 2 AMI instance and configure it to run a Spring Boot executable JAR and MariaDB (MySQL).

## Motivation

The motivation is to have tested code to use as a basis for quickly turning up server instances for speedy production of Web and API applications.

## Setup Overview

Setup is performed via setup.sh, used during EC2 instance launching at Configure Instance Details > Advanced Details > User Data. The file can be uploaded directly, or copied and pasted as text into the input field. This script updates the image, installs MariaDB and Java, and then sets up some services. [MariaDB](https://aws.amazon.com/rds/mariadb/) is used because it is a drop in replacement for MySQL and is easy to install on the Linux 2 AMI and provides a clear path to move the data layer to other AWS services such as [Aurora](https://aws.amazon.com/rds/aurora/). [Amazon Corretto](https://aws.amazon.com/corretto/) is used because it is a no-cost OpenJDK build used and supported by Amazon, and is easily installable.

Setup downloads four files: app.service, app-onstartup.service, app-onstartup.sh, and the [HelloWorld](https://github.com/kbaynes/docker-springboot-helloworld) Spring Boot application jar. It creates a /srv/app directory and downloads all files into that directory.

The app.service unit file runs the HelloWorld jar on startup.

The app-onstartup.service runs the app-onstartup.sh shell script on startup. The onstartup portion is necessary to avoid running the HelloWorld jar as root. They can be omitted, if the app.service user is set to root, rather than ec2-user. The app-onstartup.sh script simply creates an iptables route that maps all calls on port 80 to port 8080, which is where the HelloWorld application is listening. This allows the ec2-user to run the application at startup, because to run the app on port 80 requires the root user. This configuration is a bit more elaborate, but is more secure. Theoretically, it is possible to persist the iptables by loading them with a crontab @reboot, or a line in rc.local, but the systemd unit solution is simple and robust on systemd (modern) systems.

Using the app-onstartup script it should be simple to map calls on alternate ports to the ssh (22) and mysql (3306) ports, then configure the security group to expose the alternate ports rather than the standard ports, for a bit of extra security.

Setup also secures MariaDB by setting the root user (MariaDB root user, not system root user) user password, and limiting root access to localhost. It then removes the test user and test DB, and creates a DB called 'app_db', and a user called 'app_user', which has full access to app_db. It then creates a table called 'notes' and inserts some notes. Keep the passwords as defined or the application will fail to connect.

## EC2 Setup

To use this setup script on Amazon EC2:
- Click Launch Instance and select the Amazon Linux 2 AMI instance (tested with 64-bit x86)
- Select a type (tested with t2.micro: Variable ECUs, 1 vCPUs, 2.5 GHz, Intel Xeon Family, 1 GiB memory, EBS only), click Next
- On Configure Instance Details, expand the Advanced Details section at the bottom, copy the contents of setup.sh into the User Data input field or select 'as file' and select the setup.sh file, then keep clicking Next
- On Configure Security Group: Do not use 'Default Security Group' because it does not have any open ports. Create a Security Group in EC2 and open ports 80 (web), 22 (ssh) and 3306 (mysql). The wizard on this page makes it easy if you do not already have a Security Group for these types of instances. I use MyDefaultDMZ security group which has these ports open by default.
- Click Review and Launch, then Launch. It's easiest if you have a default SSH key pair configured so you can simply select it from the dropdown.

Initial setup until the app was running was about 2 minutes.

Confirm that the instance is running by connecting to the IP of the instance in a browser. You should see the 'Hello World!' screen.

Confirm that the app is running as a service by stopping the instance, confirming that the webapp no longer responds, then re-start the instance and confirm that the webapp responds again.

By my tests, the server rebooted and the app was running again in about 30 seconds.

Confirm that you can SSH into the instance by clicking the Connect button and using the given SSH command. Once connected, confirm that MariaDB is running by typing 'mysql' and that you get the mysql > prompt.

If you have Security Group configured and default SSH keys configured, then it should be possible have a running applicaition server in less than 5 minutes.

Once you're done, be sure to stop or terminate the instance so you don't run up your AWS bill!

## Using and Testing the Application

Once you have the application running and connecting to the DB, then use the browser or PostMan to use the API.

Visit the site directly in the browser at : http://<your_instance_address>/. For example: http://ec2-34-239-101-47.compute-1.amazonaws.com.

Make sure that you have the PostMan application installed, then import the NotesRepo.postman_collection.json file into PostMan, which will have test requests pre-configured. You will need to modify the request URLs to use your AWS server address and not 'localhost:8080'. For example: 'ec2-34-239-101-47.compute-1.amazonaws.com' (the application reponds on port 80, so no ':8080' is needed). You will find requests which demonstrate CRUD operations on the DB via HATEOAS calls: ListAll, Create, Delete, Update and Get First Note.

### Notes

Good [StackOverflow answer](https://stackoverflow.com/questions/21503883/spring-boot-application-as-a-service/22121547#22121547) for setting up a systemd unit file.
