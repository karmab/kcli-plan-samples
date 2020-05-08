OWNCLOUD_VERSION=latest
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=8080
yum -y install podman
podman create --name owncloud --net host --rm --security-opt label=disable -p $HTTP_PORT:$HTTP_PORT -e OWNCLOUD_VERSION=$OWNCLOUD_VERSION -e OWNCLOUD_DOMAIN=$OWNCLOUD_DOMAIN -e ADMIN_USERNAME=$ADMIN_USERNAME -e ADMIN_PASSWORD=$ADMIN_PASSWORD -e HTTP_PORT=$HTTP_PORT owncloud/server
podman start owncloud
