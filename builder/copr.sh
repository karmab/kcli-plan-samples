mkdir -p /root/.config
mv /root/copr /root/.config
dnf -y install wget rpm-build python2-devel copr-cli gcc gcc-c++ rpm-build jq libstdc++-devel
export HOME=/root
export VERSION=`grep Version: /root/package.spec  | cut -d":" -f2 | xargs`
export RELEASE=`grep Release: /root/package.spec  | cut -d":" -f2 | xargs`
export SOURCE=`grep Source: /root/package.spec | sed "s/Source\\://" | sed "s/%{version}/$VERSION/" | xargs`
wget -P /root ${SOURCE}
export SHORT=${SOURCE##*/}
mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mv /root/${SHORT} /root/rpmbuild/SOURCES
rpmbuild -bs /root/package.spec
copr-cli build kcli /root/rpmbuild/SRPMS/kcli-${VERSION}-${RELEASE}.src.rpm && poweroff
