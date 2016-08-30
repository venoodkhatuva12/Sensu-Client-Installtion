#!/bin/bash
#Script made for SENSU-SERVER Client Addintion...
#Author: Vinod.N K
#Usage: Sensu-Server Client Addition.
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
host=$(whiptail --title " MySQL Installation " --inputbox "Please Enter Hostname of Sensu-ClientServer ?" 10 60 sensuclient 3>&1 1>&2 2>&3)

#common Check for all Server...

sudo sed -i "s/],/, \"$host\"],/g" /etc/sensu/conf.d/checks/all_checks/check_disk.json
sudo sed -i "s/],/, \"$host\"],/g" /etc/sensu/conf.d/checks/all_checks/check_load.json
sudo sed -i "s/],/, \"$host\"],/g" /etc/sensu/conf.d/checks/all_checks/check_memory.json
sudo sed -i "s/],/, \"$host\"],/g" /etc/sensu/conf.d/checks/all_checks/check_disk_app.json

mkdir -p /etc/sensu/conf.d/checks/$host

echo "{
  \"checks\": {
    \"Check_Memcached_$host\": {
      \"command\": \"/etc/sensu/plugins/check_memcache -H localhost -p 11211\",
      \"subscribers\": [\"$host\"],
      \"interval\": 60
    }
  }
}" >> /etc/sensu/conf.d/checks/$host/check_memcache_$host.json

echo "{
  \"checks\": {
    \"Check_MongConn_$host\": {
      \"command\": \"/etc/sensu/plugins/check_mongodb.py  -u user -p pasword -A connections -P 27017 -W 10 -C 20\",
      \"subscribers\": [\"$host\"],
      \"interval\": 30
    }
  }
}" >> /etc/sensu/conf.d/checks/$host/check_mongconn_$host.json
echo "{
  \"checks\": {
    \"Check_MongMem_$host\": {
      \"command\": \"/etc/sensu/plugins/check_mongodb.py  -u user -p password  -A memory -P 27017 -W 10 -C 20\",
      \"subscribers\": [\"$host\"],
      \"interval\": 30
    }
  }
}" >> /etc/sensu/conf.d/checks/$host/check_mongmem_$host.json

portalurl=$(whiptail --title " Sesnu-Server Client Add " --inputbox "Please Enter URL-Portal of Sensu-ClientServer ?" 10 60 portal 3>&1 1>&2 2>&3)

echo "{
        \"checks\": {
          \"Check_URL_$host\": {
            \"command\": \"/etc/sensu/plugins/check-http.rb -u $portalurl\",
            \"interval\": 60,
            \"subscribers\": [\"$host\"],
            \"handlers\": [\"debug\", \"email\", \"remediator\"],
            \"remediation\": {
              \"Portal_reme_$host\": {
                \"occurrences\": [5],
                \"severities\": [2]

              }

            }
          }
        }
}" >> /etc/sensu/conf.d/checks/$host/check_URL_$host.json


prtpath=$(whiptail --title " Sesnu-Server Client ADD " --inputbox "Please Enter PATH for Service restart for portal-URL of Sensu-Client Server?" 10 60 path 3>&1 1>&2 2>&3)

echo "{
        \"checks\": {
          \"Portal_reme_$host\": {
            \"command\": \"sudo service httpd restart\",
            \"handlers\": [\"debug\", \"email\"],
            \"subscribers\": [\"$host\"],
            \"standalone\": false,
            \"publish\": false
          }
        }
}" >> /etc/sensu/conf.d/checks/$host/Portal_reme_$host.json

sudo redis-cli flushall
sudo /etc/init.d/rabbitmq-server restart
sudo /etc/init.d/redis restart
sudo /etc/init.d/sensu-server restart && sudo /etc/init.d/sensu-api restart 
sudo /etc/init.d/uchiwa restart
