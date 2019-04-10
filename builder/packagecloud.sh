export HOME=/root
export VERSION=`grep Version: /root/package.spec  | cut -d":" -f2 | xargs`
apt-get update 
apt-get -y install python3-stdeb ruby ruby-dev wget python-all
gem install rake package_cloud
export DEB_BUILD_OPTIONS=nocheck debuild
wget https://pypi.python.org/packages/source/k/kcli/kcli-$VERSION.tar.gz
tar xzf kcli-$VERSION.tar.gz
cd kcli-$VERSION
find . -name *pyc -exec rm {} \;
python3 setup.py --command-packages=stdeb.command sdist_dsc --depends python3-dateutil,python3-prettytable,python3-flask,python3-netaddr,python3-libvirt,genisoimage bdist_deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/xenial deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/yakkety deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/zesty deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/artful deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/bionic deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/ubuntu/cosmic deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/debian/jessie deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/debian/stretch deb_dist/*deb
/usr/local/bin/package_cloud push karmab/kcli/debian/buster deb_dist/*deb && poweroff
