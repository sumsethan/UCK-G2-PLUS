#!/bin/sh
#This script is for UniFi Cloud Key Model: UCK-G2-PLUS
#This script will disable or remove most UniFi packages, the device will no longer function as a Cloud Key for UniFi devices, but Emergency Recovery UI still works.
#+----------------------------------------------------------------------------------------------------+
#|****It is highly recommended to factory reset the Cloud Key before running script the first time****|
#|Factory reset Cloud Key: sudo ubnt-systool reset2defaults                                           |
#|Do initial setup from Web UI                                                                        |
#|--Proceed Without a UI Account                                                                      |
#|--Applications - Disable Auto Updates for UniFi OS and Applications and Uninstall Network App       |
#|--Console Settings - Enable SSH                                                                     |
#+----------------------------------------------------------------------------------------------------+
#Default SSH user: root
#Download script: sudo https://raw.githubusercontent.com/meokgo/UCK-G2-PLUS/refs/heads/main/1-Upgrade.sh
#Make script executable: sudo chmod +x 1-Upgrade.sh
#Run script: sudo ./1-Upgrade.sh
(
#Set timezone to CST
  echo '\033[0;36m'"\033[1m$(date): Setting timezone to CST...\033[0m"
  timedatectl set-timezone America/Chicago
echo "$(date): Script started." >> 1-Upgrade.log
#Check if script is run as root
  echo '\033[0;36m'"\033[1mChecking if script is run as root...\033[0m"
  if ! [ $(id -u) = 0 ]; then
    echo '\033[0;31m'"\033[1mMust run script as root.\033[0m"
    exit 1
  fi
#Check for valid kernel version
  echo '\033[0;36m'"\033[1m$(date): Checking kernel version...\033[0m"
  Kernel_Version=$(uname -r)
  echo '\033[0;36m'"\033[1mKernel version: $Kernel_Version\033[0m"
  case $Kernel_Version in
    3.18.44-ui-qcom ) echo '\033[0;36m'"\033[1mValid kernel.\033[0m";;
    * ) echo '\033[0;31m'"\033[1mInvalid kernel. Script only works on kernel 3.18.44-ui-qcom.\033[0m"
      exit 1;;
  esac
#Remove postgresql
  pkill -u postgres
  rm /var/lib/dpkg/info/postgresql-14.postinst
  mkdir -p /usr/share/postgresql/9.6/man/man1 /usr/share/postgresql/14/man/man1 /usr/share/postgresql/16/man/man1
  touch /usr/share/postgresql/9.6/man/man1/psql.1.gz /usr/share/postgresql/14/man/man1/psql.1.gz /usr/share/postgresql/16/man/man1/psql.1.gz
  DEBIAN_FRONTEND=noninteractive apt -y --purge remove postgresql\* -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  rm -r /etc/postgresql
#Remove unnecessary packages
  DEBIAN_FRONTEND=noninteractive apt -y --purge autoremove libpython2-stdlib python2 python2-minimal ubnt-archive-keyring ubnt-unifi-setup ubnt-systemhub unifi libcups2 libxml2 rfkill bluez nginx node* mongo* -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  DEBIAN_FRONTEND=noninteractive apt -y purge ~c -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  DEBIAN_FRONTEND=noninteractive apt -y clean ~c -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  echo '\033[0;36m'"\033[1m$(date): Removal complete.\033[0m"
#Start upgrade
  sed -i 's|deb https://apt.artifacts.ui.com/ bullseye release|#deb https://apt.artifacts.ui.com/ bullseye release|g' /etc/apt/sources.list.d/ubiquiti.list
  echo '\033[0;36m'"\033[1mDeleting old source list...\033[0m"
    rm /etc/apt/sources.list
  echo '\033[0;36m'"\033[1mCreating new source list...\033[0m"
    echo "deb https://deb.debian.org/debian bullseye main contrib non-free
deb-src https://deb.debian.org/debian bullseye main contrib non-free
deb https://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src https://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb https://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src https://deb.debian.org/debian bullseye-updates main contrib non-free
deb https://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src https://deb.debian.org/debian bullseye-backports main contrib non-free" > /etc/apt/sources.list
  echo '\033[0;36m'"\033[1m$(date): Installing updates...\033[0m"
    apt update
    DEBIAN_FRONTEND=noninteractive apt -y upgrade --without-new-pkgs -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  echo '\033[0;36m'"\033[1m$(date): Updates complete.\033[0m"
#Update NTP servers
  echo '\033[0;36m'"\033[1m$(date): Updating NTP servers...\033[0m"
  sed -i "s|0.ubnt.pool.ntp.org ||g" /etc/systemd/timesyncd.conf
  sed -i "s|1.ubnt.pool.ntp.org ||g" /etc/systemd/timesyncd.conf
  sed -i "s|2.ubnt.pool.ntp.org ||g" /etc/systemd/timesyncd.conf
  sed -i "s|3.ubnt.pool.ntp.org ||g" /etc/systemd/timesyncd.conf
  systemctl restart systemd-timesyncd
  timedatectl
#Update locale
  cp /etc/default/locale /etc/default/locale.bak
  echo "LANG=C
LC_ALL=C.UTF-8" > /etc/default/locale
  source ~/.bashrc
#Update motd
  rm /etc/update-motd.d/90-fwversion
  echo '\033[0;36m'"\033[1m$(date): Updating motd...\033[0m"
  wget -O /etc/motd https://raw.githubusercontent.com/meokgo/UCK-G2-PLUS/refs/heads/main/etc/motd
  echo '#!/bin/sh
cat /etc/motd' > /etc/update-motd.d/10-motd
  mv /etc/update-motd.d/10-uname /etc/update-motd.d/20-uname
  echo '#!/bin/sh
uname -nmo' > /etc/update-motd.d/20-uname
  echo '#!/bin/sh
echo "Date: " $(date)
echo "Logged in users: " $(who)
echo "Use shhlog to view SSH history."
echo "Uptime: " $(uptime -p)
ip -c -f inet addr show eth0 | awk '\''/inet / {print "eth0 IP: " $2}'\''
ip -c -f inet addr show tailscale0 | awk '\''/inet / {print "tailnet IP: " $2}'\''' > /etc/update-motd.d/30-stats
  chmod +x /etc/update-motd.d/10-motd /etc/update-motd.d/30-stats
  sed -i 's|^session    optional     pam_motd.so noupdate|#session    optional     pam_motd.so noupdate|g' /etc/pam.d/sshd
  #Display motd
    run-parts /etc/update-motd.d
#Move storage using symlink
  echo '\033[0;36m'"\033[1m$(date): Moving cache and temp storage using symlink...\033[0m"
  mkdir -p /data/var/lib
  mv /var/cache /data/var/cache
  ln -s /data/var/cache /var/cache
  mv /var/log /data/var/log
  ln -s /data/var/log /var/log
  mv /var/lib/apt /data/var/lib/apt
  ln -s /data/var/lib/apt /var/lib/apt
  mv /var/lib/dpkg /data/var/lib/dpkg
  ln -s /data/var/lib/dpkg /var/lib/dpkg
#Move /etc/pihole using symlink
  mkdir -p /etc/pihole /data/etc
  mv /etc/pihole /data/etc
  ln -s /data/etc/pihole /etc/pihole
#Create global alias for ls to show more detail
  echo "
#Global alias for ls to show more detail
alias ls='ls -hAlF --color=auto'" >> /etc/bash.bashrc
#Update root user alias for ls to show more detail
  sed -i "s|alias ls='ls -F --color=auto'|alias ls='ls -hAlF --color=auto'|g" /root/.bashrc
#Create global alias for ssh logs
  echo "
#Global alias for ssh logs
alias sshlog='echo "Last 10 successful logins:" && last -10 && echo "Last 10 failed logins:" && lastb -10'" >> /etc/bash.bashrc
#Update color settings from 8 to 256
  echo '\033[0;36m'"\033[1m$(date): Update color settings from 8 to 256...\033[0m"
  echo "
TERM=xterm-256color" >> /etc/bash.bashrc
#Set LED to blue after finished booting
  echo '\033[0;36m'"\033[1m$(date): Updating LED settings...\033[0m"
  cp /etc/rc.local /etc/rc.local.bak
  echo '#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

echo none > /sys/class/leds/blue/trigger
echo none > /sys/class/leds/white/trigger
echo 60 > /sys/class/leds/blue/brightness

exit 0' >> /etc/rc.local
  chmod +x /etc/rc.local
  systemctl daemon-reload
  systemctl start rc-local
#Disable ipv6
  if grep -Fxq "#Disable ipv6 for all interfaces" /etc/sysctl.conf
  then
    echo '\n\033[0;35m'"\033[1mipv6 is already disabled.\033[0m"
  else
    echo "#Disable ipv6 for all interfaces
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6" = 1 >> /etc/sysctl.conf
  fi
  sysctl -p
#Free port 53 and 5355
  cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
  echo "[Resolve]
DNS = 1.1.1.1
FallbackDNS = 8.8.8.8 8.8.4.4
#Domains = 
LLMNR = no
#MulticastDNS = no
#DNSSEC = no
#DNSOverTLS = no
#Cache = no
DNSStubListener = no
#ReadEtcHosts = yes" > /etc/systemd/resolved.conf
  ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
  systemctl restart systemd-resolved
  echo "#*****************************
#To set static IP change DHCP to no.
#Uncomment #Address #Gateway #DNS.
#Update with static IP info.
#*****************************
[Match]
Name = eth0
[Address]
#Address = 192.168.1.100/24
[Route]
#Gateway = 192.168.1.1
[Network]
DHCP = ipv4
LLMNR = no
#DNS = 8.8.4.4 8.8.8.8" > /etc/systemd/network/eth0.network
  systemctl restart systemd-networkd
#Option to run 2-Device-Config.sh
  while : ; do
    read -p "$(echo '\033[0;106m'"\033[30mRun 2-Device-Config.sh (set static IP, hostname, harden SSH, etc.)? (y/n)\033[0m ")" yn
    case $yn in
      [yY]) wget https://raw.githubusercontent.com/meokgo/UCK-G2-PLUS/refs/heads/main/2-Device-Config.sh && chmod +x 2-Device-Config.sh && ./2-Device-Config.sh
        break;;
      [nN]) echo '\033[0;35m'"\033[1mNot running config.\033[0m";
        break;;
      *) echo '\033[0;31m'"\033[1mInvalid response.\033[0m";
    esac
  done
#Option to install tools using 3-Install-Tools.sh
  while : ; do
    read -p "$(echo '\033[0;106m'"\033[30mRun 3-Install-tools.sh (install useful tools like tailscale, ncdu, iperf3, etc.)? (y/n)\033[0m ")" yn
    case $yn in
      [yY]) wget https://raw.githubusercontent.com/meokgo/UCK-G2-PLUS/refs/heads/main/3-Install-Tools.sh && chmod +x 3-Install-Tools.sh && ./3-Install-Tools.sh
        break;;
      [nN]) echo '\033[0;35m'"\033[1mNot installing tools.\033[0m";
        break;;
      *) echo '\033[0;31m'"\033[1mInvalid response.\033[0m";
    esac
  done
echo "$(date): Script finished" >> 1-Upgrade.log
) 2>&1 | tee -a 1-Upgrade.log
#Option to reboot device
  while : ; do
    read -p "$(echo '\033[0;106m'"\033[30mDevice must be rebooted. Reboot now? (y/n)\033[0m ")" yn
    case $yn in
      [yY]) echo '\033[0;32m'"\033[1m$(date): Rebooting in 5 seconds...\033[0m"
        sleep 5
        reboot
        break;;
      [nN]) echo '\033[0;35m'"\033[1mExiting...\033[0m";
        exit;;
      *) echo '\033[0;31m'"\033[1mInvalid response.\033[0m";
    esac
  done
