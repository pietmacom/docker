#!/bin/bash -ex

echo "Please make sure that keyrings are initialized correctly!"
echo
echo "ARM: pacman-key --init && pacman-key --populate archlinuxarm"
echo "x86_64: pacman-key --init && pacman-key --populate archlinux"
echo
read -p "Press [Enter] key to continue..."

echo 
echo -n "Hostname Prefix (like dsrvbuild): "
read HOSTNAMEPREFIX

HOSTNAME="${HOSTNAMEPREFIX}$(uname -m | sed 's|[^a-zA-Z0-9]||')"
echo "New hostname: ${HOSTNAME}"

echo
echo -n "Password: "
read -s PASSWORD

echo
echo -n "Working Drive (like /dev/sda): "
read WORKDRIVE

# initialize system
pacman-key --init
pacman-key --populate archlinuxarm

# update basesystem
pacman --noconfirm -Syu

pacman -S git
/bin/sh -c 'cd /etc && git init && git config --global user.email "you@example.com" && git config --global user.name "Your Name" && git add -A  && git commit -a -m "init after system upgrade"'

## timedatectl set-timezone "$(curl --fail https://ipapi.co/timezone)"
## set to german
echo LANG=de_DE.UTF-8 > /etc/locale.conf
echo KEYMAP=de-latin1-nodeadkeys > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
timedatectl set-local-rtc 0
sed -i 's|^\([A-Za-z].*\)|#\1|' /etc/locale.gen
sed -i 's|^#\(de_DE.UTF-8.*\)$|\1|' /etc/locale.gen
sed -i 's|^#\(de_CH.UTF-8.*\)$|\1|' /etc/locale.gen
sed -i 's|^#\(de_AT.UTF-8.*\)$|\1|' /etc/locale.gen
sed -i 's|^#\(en_DK.UTF-8.*\)$|\1|' /etc/locale.gen
locale-gen
/bin/sh -c 'cd /etc && git add -A && git commit -m "set timezone"'

## maintenance/tracing
pacman --noconfirm  -S etckeeper mc bash-completion iotop iftop
/bin/sh -c 'cd /etc && git add -A && git commit -m "install system utils"'

########################################################
# BASESYSTEN
#
echo "${HOSTNAME}" > /etc/hostname
/bin/sh -c 'cd /etc && git add -A && git commit -m "set hostname"'

## password
(echo "$PASSWORD" ; echo "$PASSWORD") | passwd alarm
(echo "$PASSWORD" ; echo "$PASSWORD") | passwd root
/bin/sh -c 'cd /etc && git add -A && git commit -m "set user passwords for alarm and root"'

# has to happen first - most top
echo "tmpfs /var/tmp tmpfs nodev,nosuid 0 0" >> /etc/fstab
echo "tmpfs /var/log tmpfs nodev,nosuid 0 0" >> /etc/fstab
/bin/sh -c 'cd /etc && git add -A && git commit -m "add tmpfs to /var/tmp and /var/log"'

if [ -e "/etc/resolvconf.conf" ];
then
	sed -i 's|resolv_conf=.*|resolv_conf=/var/tmp/resolv.conf|' /etc/resolvconf.conf
else
	echo 'resolv_conf=/var/tmp/resolv.conf' > /etc/resolvconf.conf
fi
sed -i 's|#Storage=auto|Storage=volatile|' /etc/systemd/journald.conf
/bin/sh -c 'cd /etc && git add -A && git commit -m "prepare systemd for readonly filesystem"'

systemctl mask logrotate.timer
systemctl mask man-db.timer
systemctl mask shadow.timer
systemctl disable logrotate || true
systemctl disable man-db || true
systemctl disable shadow || true
systemctl disable systemd-random-seed || true
systemctl disable etckeeper.timer
/bin/sh -c 'cd /etc && git add -A && git commit -m "disable services in read only filesystem"'

# Raspberry pi
if [ -e "/boot/cmdline.txt" ]; then sed -i 's| rw | ro |' /boot/cmdline.txt; fi
# Odroid Xu4
if [ -e "/boot/boot.ini" ]; then sed -i 's| rw | ro |' /boot/boot.ini; fi
# Odroid u3
if [ -e "/boot/boot.txt" ]; then (cd /boot && sed -i 's| rw | ro |' boot.txt && pacman --noconfirm -S uboot-tools && ./mkscr) ; fi
# EFI (64)
if [ -e "/boot/loader/entries/arch-uefi.conf" ];
then
	sed -i 's| rw| ro|' /boot/loader/entries/arch-uefi.conf
	sed -i 's|^\(.*/.*\s\)rw\(.*\)$|\1ro\2|' /etc/fstab
	sed -i 's|^\(.*/boot.*\s\)rw\(.*\)$|\1ro\2|' /etc/fstab
fi

echo "mount -o remount,rw /" > ~/writeenable.sh
echo "mount -o remount,ro /" > ~/readonly.sh
chmod 500 ~/writeenable.sh
chmod 500 ~/readonly.sh



########################################################
# Devel System
#

## Base-Devtools
pacman --noconfirm -S arch-install-scripts base-devel devtools

## docker
pacman --noconfirm -S docker
mkdir -p /var/lib/docker
chmod 700 /var/lib/docker


## jenkins slave
useradd -r jenkins -d /var/lib/jenkins -m
usermod -aG docker jenkins
if [ ! -z "$(find . -maxdepth 1 -name "jdk*")"];
then
	# Install jdk from local pkg, when available
	pacman --noconfirm -U jdk*.pkg.tar.xz
else
	pacman --noconfirm -S jdk8-openjdk
fi

## partitioning
pacman --noconfirm -S parted

if [ ! -z "$(parted -m ${WORKDRIVE} print 2> /dev/nul | tail -n +3)" ];
then
	read -p "CAREFULL! Harddrive is not emtpy. All partitions will be deleted! Press [Enter] key to continue..."
	dd if=/dev/zero of=${WORKDRIVE} bs=1M count=100 status=progress
fi

parted -s ${WORKDRIVE} mklabel gpt # 100MiB GPT
parted -s ${WORKDRIVE} mkpart primary ext4 100MiB 20580MiB # 20GB base
parted -s ${WORKDRIVE} mkpart primary linux-swap 20580MiB 28772MiB # 8GB swap
parted -s ${WORKDRIVE} mkpart primary ext4 28772MiB 45156MiB # 16GB tmp
parted -s ${WORKDRIVE} mkpart primary ext4 45156MiB 100% # base-overlay
parted -s ${WORKDRIVE} print

mkfs.ext4 ${WORKDRIVE}1

mkdir -p /media/base
mkdir -p /media/base-overlay
mkdir -p /media/data

## crypttab
echo "swap $(find -L /dev/disk/by-id -samefile ${WORKDRIVE}2 | head -n 1) /dev/urandom swap,discard,cipher=aes-cbc-essiv:sha256,size=256,no-read-workqueue,no-write-workqueue" >> /etc/crypttab
echo "tmp $(find -L /dev/disk/by-id -samefile ${WORKDRIVE}3 | head -n 1) /dev/urandom tmp,discard,cipher=aes-cbc-essiv:sha256,size=256,no-read-workqueue,no-write-workqueue" >> /etc/crypttab
echo "base-overlay $(find -L /dev/disk/by-id -samefile ${WORKDRIVE}4 | head -n 1) /dev/urandom tmp,discard,cipher=aes-cbc-essiv:sha256,size=256,no-read-workqueue,no-write-workqueue" >> /etc/crypttab


## fstab
echo "$(find -L /dev/disk/by-id -samefile ${WORKDRIVE}1 | head -n 1) /media/base ext4 ro 0 2" >> /etc/fstab
echo "/dev/mapper/swap none swap defaults 0 0" >> /etc/fstab
echo "/dev/mapper/tmp /tmp ext4 rw,noinit_itable,noexec,nosuid,nodev,discard 0 0" >> /etc/fstab
echo "/dev/mapper/base-overlay /media/base-overlay ext4 rw,noinit_itable,noatime,nodiratime,discard 0 0" >> /etc/fstab
echo "/media/data/var/lib/jenkins /var/lib/jenkins none bind,noauto" >> /etc/fstab
echo "/media/base-overlay/docker /var/lib/docker none bind,noauto" >> /etc/fstab
echo "/media/base-overlay/containerd /var/lib/containerd none bind,noauto" >> /etc/fstab


## prepare base
mount ${WORKDRIVE}1 /media/base

## Jenkins slave
mkdir -p /media/base/var/lib/jenkins
chmod 700 /media/base/var/lib/jenkins
chown -R jenkins:jenkins /media/base/var/lib/jenkins
## create login sshkey
mount --bind /media/base/var/lib/jenkins /var/lib/jenkins 
su - jenkins -s /bin/bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh  && ssh-keygen -C '$(whoami)@$(hostname)-$(date -I)' -b 4096 -N '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
umount /var/lib/jenkins


## Docker remote access
mkdir -p /media/base/var/lib/docker/.ssh
chmod 700 /media/base/var/lib/docker

# Docker Engine / Server CA, Key and Certificate for 3650days / 10years
CA_ISSUER="/C=DE/ST=Province/L=City/O=Organisation"

openssl genrsa -passout pass:"$PASSWORD" -aes256  -out /media/base/var/lib/docker/.ssh/ca-key.pem 4096
openssl req -passout pass:"$PASSWORD" -passin pass:"$PASSWORD" -new -x509 -days 3650 -key /media/base/var/lib/docker/.ssh/ca-key.pem -sha256 -out /media/base/var/lib/docker/.ssh/ca.pem -subj "$CA_ISSUER/CN=Certificate Authority"

openssl genrsa -out /media/base/var/lib/docker/.ssh/server-key.pem 4096
openssl req -subj "$CA_ISSUER/CN=$(hostname)" -sha256 -new -key /media/base/var/lib/docker/.ssh/server-key.pem -out /media/base/var/lib/docker/.ssh/server.csr

echo "subjectAltName = DNS:$(hostname)$(ip addr | grep -oE 'inet [0-9.]*' | sed 's|inet |,IP:|' | tr -d '\n')" >> /media/base/var/lib/docker/.ssh/extfile.cnf
echo "extendedKeyUsage = serverAuth" >> /media/base/var/lib/docker/.ssh/extfile.cnf
openssl x509 -passin pass:"$PASSWORD" -req -days 3650 -sha256 -in /media/base/var/lib/docker/.ssh/server.csr -CA /media/base/var/lib/docker/.ssh/ca.pem -CAkey /media/base/var/lib/docker/.ssh/ca-key.pem -CAcreateserial -out /media/base/var/lib/docker/.ssh/server-cert.pem -extfile /media/base/var/lib/docker/.ssh/extfile.cnf

# Docker Client
openssl genrsa -out /media/base/var/lib/docker/.ssh/client-key.pem 4096
openssl req -subj "$CA_ISSUER/CN=client" -new -key /media/base/var/lib/docker/.ssh/client-key.pem -out /media/base/var/lib/docker/.ssh/client.csr
echo "extendedKeyUsage = clientAuth" > /media/base/var/lib/docker/.ssh/extfile-client.cnf
openssl x509 -passin pass:"$PASSWORD" -req -days 365 -sha256 -in /media/base/var/lib/docker/.ssh/client.csr -CA /media/base/var/lib/docker/.ssh/ca.pem -CAkey /media/base/var/lib/docker/.ssh/ca-key.pem -CAcreateserial -out /media/base/var/lib/docker/.ssh/client-cert.pem -extfile /media/base/var/lib/docker/.ssh/extfile-client.cnf

chmod -v 0400 /media/base/var/lib/docker/.ssh/ca-key.pem /media/base/var/lib/docker/.ssh/client-key.pem /media/base/var/lib/docker/.ssh/server-key.pem
chmod -v 0444 /media/base/var/lib/docker/.ssh/ca.pem /media/base/var/lib/docker/.ssh/server-cert.pem /media/base/var/lib/docker/.ssh/client-cert.pem
rm -v /media/base/var/lib/docker/.ssh/client.csr /media/base/var/lib/docker/.ssh/server.csr /media/base/var/lib/docker/.ssh/extfile.cnf /media/base/var/lib/docker/.ssh/extfile-client.cnf

## Trustet Certificate Authorities for Docker registry access
if [ -e "./ca"  ];
then
    # Extrac CA and trust
    trust anchor ./ca/*
    update-ca-trust
fi

# Create Drop-In to replace ExecStart
mkdir -p /etc/systemd/system/docker.service.d
echo "[Service]" > /etc/systemd/system/docker.service.d/tcp.conf 
echo "ExecStart=" >> /etc/systemd/system/docker.service.d/tcp.conf 
echo 'ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/media/data/var/lib/docker/.ssh/ca.pem --tlscert=/media/data/var/lib/docker/.ssh/server-cert.pem --tlskey=/media/data/var/lib/docker/.ssh/server-key.pem -H 0.0.0.0:2376 -H fd://' >> /etc/systemd/system/docker.service.d/tcp.conf 

## etc
mkdir -p /media/base/etc

## prepare base-overlay
function overlay-service() {
	echo "[Unit]"
	echo "Requires=systemd-cryptsetup@base-overlay.service"
	echo "After=systemd-cryptsetup@base-overlay.service"
	echo "[Service]"
	
	# With overlayfs kernel module its impossible to run docker container as
	# non-rootuser, when docker-home is settled on an overlayfs

	echo "ExecStartPre=mkdir -p /media/base-overlay/work /media/base-overlay/upper /media/base-overlay/docker /media/base-overlay/containerd"
	echo "ExecStart=mount -t overlay overlay -olowerdir=/media/base,upperdir=/media/base-overlay/upper,workdir=/media/base-overlay/work /media/data"
	echo "ExecStartPost=/usr/bin/sh -c \"grep 'noauto' /etc/fstab | cut -d' ' -f2 | xargs -L 1 mount\""
	echo "[Install]"
	echo "WantedBy=multi-user.target"
}
overlay-service >> /etc/systemd/system/overlay-media-data.service
systemctl daemon-reload
systemctl enable overlay-media-data.service

## enable services for development
systemctl enable docker

## links

# https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt
# https://wiki.archlinux.org/index.php/Overlay_filesystem
# https://docs.docker.com/storage/storagedriver/overlayfs-driver/

