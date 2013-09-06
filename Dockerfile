# Ceph monitor
#
# VERSION 0.0.1

FROM ubuntu:precise
MAINTAINER Patrick McGarry "patrick@inktank.com"

# Make sure base repository info is there
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

# Fix initctl
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# Install required packages
RUN apt-get update && apt-get install -y wget sudo openssh-server

# Set resolveable hostname
RUN echo "127.0.0.1 cephmona" > /etc/hosts

# Add required directories
RUN mkdir -p /var/run/sshd /dev/fuse /root/.ssh /etc/ceph /var/lib/ceph/mon.a/store.db
RUN chmod 0755 /etc/ceph

# Fix initctl
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# Add ceph repository
RUN /usr/bin/wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
RUN echo "deb http://ceph.com/debian-dumpling/ precise main" > /etc/apt/sources.list.d/ceph.list
RUN apt-get update

# Install Ceph
RUN apt-get install -y ceph

# Open SSH
EXPOSE 22

# Add pub key
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCn0TDI582HLyWJedaD1KeKfgJg9QerjKcD7F4zcn5rYkrr0qmH1bI4YYOGX9MFitEDXvcBHtY8JMOduVh+hlL8ko4mRy1bmYKxqi1/aSTnWMU0lmT6uvKzk/VmFVmWnvc9YMrHLHj+iQplhILeVlz6Y8ApmKhnGsmwysII6cKTHTPcTMBB8KpDMjljlXAa3q3O0jUgUfd+QDjCWPAoZqnt1ick1M+vP3nHfzIvp+C0VIte4Wkve7+KCU3lj61d/GiXCZivZF2jO+f22SjlYoA1z49fR8jZn06kHPsGJOMJ+rW+FQXY7wba3D21A1YaPHDvzJEUvKk33Kc6AjFfA7Sf root@localhost" > /root/.ssh/authorized_keys

# Bootstrap mon
RUN echo "[global]\nauth supported = cephx\nkeyring = /etc/ceph/keyring\n\n[mon]\nlog file = /var/log/ceph/mon.a.log\ndebug mon = 20\ndebug ms = 1\nosd crush chooseleaf type = 0" > /etc/ceph/ceph.conf
RUN chmod 0644 /etc/ceph/ceph.conf

RUN ceph-authtool --create-keyring /etc/ceph/keyring --gen-key -n client.admin
RUN ceph-authtool /etc/ceph/keyring --gen-key -n mon.
RUN chmod 0644 /etc/ceph/keyring

RUN monmaptool --create --clobber --add a cephmona:6789 --print
RUN ceph-authtool --gen-key --name=client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *'

RUN ceph-mon -c /etc/ceph/ceph.conf -i a --mkfs --monmap mm --mon-data /var/lib/ceph/mon.a -k /etc/ceph/keyring
RUN ceph-mon -c /etc/ceph/ceph.conf -i a --mon-data /var/lib/ceph/mon.a
RUN ceph -c /etc/ceph/ceph.conf -k /etc/ceph/keyring --monmap mm health

CMD ["/usr/sbin/sshd","-D"]
