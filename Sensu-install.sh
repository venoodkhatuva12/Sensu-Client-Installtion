rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum -y install erlang
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
rpm -Uvh http://www.rabbitmq.com/releases/rabbitmq-server/v2.7.1/rabbitmq-server-2.7.1-1.noarch.rpm
rabbitmq-plugins enable rabbitmq_management
chkconfig rabbitmq-server on
/etc/init.d/rabbitmq-server start
rabbitmqctl add_vhost /sensu
rabbitmqctl add_user sensu mypass
rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

yum -y install redis
chkconfig redis on
/etc/init.d/redis start

cat > /etc/yum.repos.d/sensu.repo << EOM
[sensu]
name=sensu-main
baseurl=http://repos.sensuapp.org/yum/el/6/x86_64/
gpgcheck=0
enabled=1
EOM

yum -y install sensu
chkconfig sensu-server on
chkconfig sensu-api on
chkconfig sensu-client on
chkconfig sensu-dashboard on

/etc/init.d/sensu-server start
/etc/init.d/sensu-api start
/etc/init.d/sensu-client start
/etc/init.d/sensu-dashboard start
