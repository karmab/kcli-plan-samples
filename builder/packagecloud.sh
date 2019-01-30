apt-get -y install python3-stdeb ruby ruby-dev
gem install rake
gem install package_cloud
export DEB_BUILD_OPTIONS=nocheck debuild
wget http://pypi.python.org/packages/source/k/kcli/kcli-$VERSION.tar.gz
tar xzf kcli-$VERSION.tar.gz
cd kcli-$VERSION
python3 setup.py --command-packages=stdeb.command sdist_dsc --depends python3-dateutil,python3-prettytable,python3-flask,python3-netaddr,python3-libvirt,genisoimage bdist_deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/xenial deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/yakkety deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/zesty deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/artful deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/bionic deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/ubuntu/cosmic deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/debian/jessie deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/debian/stretch deb_dist/*deb
/usr/local/bin/package_cloud push {{ user }}/{{ package }}/debian/buster deb_dist/*deb
poweroff
