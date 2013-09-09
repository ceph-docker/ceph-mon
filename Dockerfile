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
# >>> Figure out hostname 
RUN echo "127.0.0.1 $hostname" > /etc/hosts

# UUID Generation
??

# Add required directories
RUN mkdir -p /var/run/sshd /dev/fuse /root/.ssh

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
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4DAGxSpi4azGGW8R6FzcOjT/Av8ripkJs1SiP0SyDQ4ZcqjFHoVmU3ckzpvDtH+wb0AtjYqBce7/O7FZf7joYgwf8FMUJhRcVu5lZSbvf9F1oq6hWZ8UM7J+ZjnqZu6cCMLpnWuVzZ/LHrhUI+80l+0FUw/Pf0c6Z3QRyWhfCrN0SBvQ9py2o8LtHyfwNIgu25OZVynICHtFHftEVYwAEBK6GYUm5Rp9IjQ9IkUwtT3L8VmhLNFXjoSn4IUEQugIvJ9CWku6a1UJHLpGowbuUqjDH0ONlCaH4o4nPYnG4bM4x65XSq/W1bFM9u318OzTHBIhiu7GoXAbPEVb14YUR root@docker-ceph" > /root/.ssh/authorized_keys

# Bootstrap mon
RUN echo "[global]\nfsid = $uuid\ndebug mon = 20\ndebug ms = 1\nosd crush chooseleaf type = 0" > /etc/ceph/ceph.conf
RUN chmod 0644 /etc/ceph/ceph.conf

RUN ceph-authtool /etc/ceph/temp.keyring --gen-key --cap mon 'allow *' -n mon.
RUN chmod 0644 /etc/ceph/temp.keyring

RUN monmaptool --create --clobber --add $hostname --fsid $uuid $hostname:6789 --print 

RUN mkdir /var/lib/ceph/mon/ceph-$hostname
RUN ceph-mon -i $hostname --mkfs --monmap mm -k /etc/ceph/temp.keyring
RUN ceph-mon -i $hostname --mon-data /var/lib/ceph/ceph-$hotmame
RUN ceph health
ceph-create-keys -i -v $hostname

CMD ["/usr/sbin/sshd","-D"]
