#!/bin/bash
#Script made for SENSU-CLIENT Installtion...
#Author: Vinod.N K
#Usage: Sensu-Client, ruby, ruby-gems, perl, sensu-plugins
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
# Dependencies
echo "Installing dependencies..."
yum install newt -y
sudo yum install ruby* -y 
sudo yum install ruby-rdoc ruby-shadow rubygems curl openssl-devel python-pip -y
sudo yum install ruby-ri* -y
pip install pymongo
yum install perl* --skip-broken -y
yum install perl-Time-HiRes -y

whiptail --title " SENSU CLIENT INSTALLATION !! " --msgbox "Starting installation of Sensu Client... Choose Ok to continue." 10 60
echo '[sensu]
name=sensu
baseurl=http://sensu.global.ssl.fastly.net/yum/$basearch/
gpgcheck=0
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo
sudo yum install sensu -y
gem install sensu-plugin addressable bundler descendants_tracker faraday github_api hashie highline httpclient json jwt  launchy mixlib-cli multi_json multi_xml multipart-post  nayutaya-msgpack-pure  oauth2 psych  rack rdoc rdoc-data sensu-plugin solano tddium_client  thor thread_safe

if (whiptail --title "Test Yes/No Box" --yesno "Do you want to add this User to Sudoer(Yes/No)?" 10 60)
  then
           sudo sed -i "95 i sensu   ALL=(ALL)       NOPASSWD: ALL" /etc/sudoers
else
    exit
fi

mkdir -p /etc/sensu/conf.d
mkdir -p /etc/sensu/ssl

#I uploaded my SSL key created in Sensu Server copy to AWS S3 for Sensu Client.
cd /etc/sensu/ssl/
sudo wget https://s3-us-west-1.amazonaws.com/sensu-client-key/client_cert.pem
sudo wget https://s3-us-west-1.amazonaws.com/sensu-client-key/client_key.pem


SENSUIP=$(whiptail --title " SENSU CLIENT INSTALLATION !!" --inputbox "Please Enter IPADDRESS of the Sensu-Server ?" 10 60 IPADDRESS 3>&1 1>&2 2>&3)
echo "{
  \"rabbitmq\": {
    \"ssl\": {
      \"cert_chain_file\": \"/etc/sensu/ssl/client_cert.pem\",
      \"private_key_file\": \"/etc/sensu/ssl/client_key.pem\"
    },
    \"host\": \"$SENSUIP\",
    \"port\": \"5671\",
    \"vhost\": \"/sensu\",
    \"user\": \"sensu\",
    \"password\": \"xxx\"
  }
}" >> /etc/sensu/conf.d/rabbitmq.json


host=$(whiptail --title " SENSU CLIENT INSTALLATION !!" --inputbox "Please Enter HOSTNAME of the SENSU-CLIENT ?" 10 60 HOSTNAME 3>&1 1>&2 2>&3)
IPADD=$(whiptail --title " SENSU CLIENT INSTALLATION !!" --inputbox "Please Enter IPADDRESS of the SENSU-CLIENT ?" 10 60 IPADDRESS 3>&1 1>&2 2>&3)
SUBS=$(whiptail --title " SENSU CLIENT INSTALLATION !!" --inputbox "Please Enter Subscription Name of the SENSU-CLIENT ?" 10 60 Subscription 3>&1 1>&2 2>&3)
echo "{
  \"client\": {
    \"name\": \"$host\",
    \"address\": \"$IPADD\",
    \"subscriptions\": [ \"$SUBS\" ]
  }
}" >>  /etc/sensu/conf.d/client.json

cd /etc/sensu/
sudo  rm -rf /etc/sensu/plugins
sudo wget https://s3-eu-west-1.amazonaws.com/plugins.zip
sudo unzip plugins.zip
sudo chmod 755 /etc/sensu/plugins
sudo rm -rf /etc/sensu/plugins.zip
sudo /etc/init.d/sensu-client restart

echo "Thanx for using Sensu-client"
