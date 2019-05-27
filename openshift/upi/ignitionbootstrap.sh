yum -y install httpd
cp /root/bootstrap.ign /var/www/html/bootstrap
sed -i "s/Listen 80/Listen 8081/" /etc/httpd/conf/httpd.conf
systemctl start httpd
