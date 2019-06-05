yum -y install httpd
sed -i "s/^Listen .*/Listen 8080/" /etc/httpd/conf/httpd.conf
#sleep 600
sleep 300
curl -kL https://{{ bootstrap_ip}}:22623/config/master -o /var/www/html/master
curl -kL https://{{ bootstrap_ip}}:22623/config/worker -o /var/www/html/worker
systemctl enable --now httpd
