#!/bin/bash
###############################################################################
#Script Name    : script asterisk 16                       
#Description    : Building asterisk system on Centos7              
#Author         : Mr.Kien Le    
################################################################################

eval `date "+day=%d; month=%m; year=%Y"`
INSTFIL="$year-$month-$day"
IPTABLES=/sbin/iptables
IPTABLES_SAVE=/sbin/iptables-save

# Disabling SeLinux for installation(Remains disabled untill reboot ar manual enable). 
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

#update timzone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

CHOICE=-1
function menu {
   echo ""
   echo -e "\e[2;32m    Option 1: Ensure all required packages are installed  \e[0m"
   echo -e "\e[2;33m    Option 2: In1stall Asterisk                           \e[0m"
   echo -e "\e[2;32m    Option 0: Exit without taking any actions             \e[0m"
   echo "" 
   echo -en "\e[2;33m  Selection: \e[0m"

   read CHOICE
}

function update {
# Updating packages
yum -y update

# Installing needed tools and packages
yum -y groupinstall core base "Development Tools"

#Installing additional required dependencies
yum -y install automake gcc gcc-c++ ncurses-devel openssl-devel libxml2-devel unixODBC-devel libcurl-devel libogg-devel libvorbis-devel speex-devel spandsp-devel freetds-devel net-snmp-devel iksemel-devel corosynclib-devel newt-devel popt-devel libtool-ltdl-devel lua-devel sqlite-devel radiusclient-ng-devel portaudio-devel neon-devel libical-devel openldap-devel gmime-devel mysql-devel bluez-libs-devel jack-audio-connection-kit-devel gsm-devel libedit-devel libuuid-devel jansson-devel libsrtp-devel git subversion libxslt-devel kernel-devel audiofile-devel gtk2-devel libtiff-devel libtermcap-devel ilbc-devel bison php php-mysql php-process php-pear php-mbstring php-xml php-gd tftp-server httpd sox tzdata mysql-connector-odbc mariadb mariadb-server fail2ban jwhois xmlstarlet ghostscript libtiff-tools python-devel patch

# Enabling and starting MariaDB
systemctl enable mariadb.service
systemctl start mariadb

# Install $IPTABLES
systemctl stop firewalld
systemctl disable firewalld
yum -y install iptables-services
systemctl start iptables
systemctl enable iptables

echo -en "\e[2;32m                 Now you need reboot to take effect (y/n):\e[0m"
   read value
   echo ""
   case $value in
        y) reboot ;;
        yes) reboot ;;
        n) exit ;;
        no) exit ;;
        *) echo -e  "\e[2;320mINVALID OPTION\e[0m" ;;
   esac
   function reboot {
   	reboot -h now
   }

}

function install_asterisk {

# Compiling and Installing jansson
cd /usr/src
wget -O jansson.zip https://codeload.github.com/akheron/jansson/zip/master
unzip jansson.zip
rm -f jansson.zip
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

#Compile and install DAHDI if needed

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-2.10.2+2.10.2.tar.gz
tar zxvf dahdi-linux-complete-2.10*
cd /usr/src/dahdi-linux-complete-2.10*/
make all && make install && make config
systemctl restart dahdi 
echo -e "\e[32mDAHDI Install OK!\e[m"

#Compile and install Libpri if needed
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
tar xvfz libpri-current.tar.gz
cd /usr/src/libpri-*
make
make install
echo -e "\e[32mLibpri Install OK!\e[m"

# Create Asterisk usser for system
adduser asterisk -m -c "Asterisk User"

# Downloading Asterisk source files.
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz

# Compiling and installing Asterisk
cd /usr/src
tar xvfz asterisk-16-current.tar.gz
rm -f asterisk-16-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh

# Making some configuration of installation options, modules, etc. After selecting 'Save & Exit' you can then continue
make menuselect

# Installation itself
make
make install
make samples
make config
ldconfig
systemctl start asterisk
systemctl enable asterisk

# Setting Asterisk ownership permissions.
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/
sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf
echo -e "\e[32m asterisk Install OK!\e[m"

# Alow porrt access asterisk and drop scan asterisk amonymous
$IPTABLES_SAVE > /usr/local/etc/iptables.last-$INSTFIL.log
$IPTABLES -P INPUT ACCEPT
$IPTABLES -X
$IPTABLES -Z
$IPTABLES -A INPUT -s 127.0.0.1 -j ACCEPT
$IPTABLES -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A INPUT -p udp -m tcp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -j ACCEPT
$IPTABLES -A INPUT -p udp -m udp --dport 10000:20000 -j ACCEPT
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "sipvicious" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "sipsak" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "iWar" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "sundayddr" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "sip-scan" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -m udp --dport 5060 -m string --string "friendly-scanner" --algo bm --to 65535 -j DROP
$IPTABLES -A INPUT -p udp -j DROP
$IPTABLES -A INPUT -p tcp -j DROP

service iptables save
}

menu 

while [  $CHOICE -ne "0" ]; do
   case "$CHOICE" in
      "0")
         exit 0
         CHOICE=0;;
      "1")
         update
         CHOICE=0;;
	  "2")
	     install_asterisk
         CHOICE=0;;
	*)echo -e  "\e[2;330mYou have entered an invalid option...\e[0m"
         echo ""
         menu
	esac
done	
echo -e "\e[2;32m                  INSTALL SCUCESSFULLY ASTERISK                            \e[0m"
echo ""
echo -e "\e[2;32m ------------------------- MISSION COMPLETE! -----------------------------\e[0m"
echo ""
