#!/bin/bash
###############################################################################
#Script Name    : script asterisk 20                       
#Description    : Scripts cài đặt asterisk trên Ubuntu & Debian              
#Author         : Mr.Kien Le    
################################################################################

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
#Update system & reboot
sudo apt update && sudo apt -y upgrade
sudo reboot
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
#Install Asterisk 20 LTS dependencies
sudo apt -y install git curl wget libnewt-dev libssl-dev libncurses5-dev subversion  libsqlite3-dev build-essential libjansson-dev libxml2-dev  uuid-dev

#Add universe repository and install subversio
sudo add-apt-repository universe
sudo apt update && sudo apt -y install subversion

#Download Asterisk 20 LTS tarball
# sudo apt policy asterisk
cd /usr/src/
sudo curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

#Extract the file
sudo tar xvf asterisk-20-current.tar.gz
cd asterisk-20*/

#download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

#Ensure all dependencies are resolved
sudo contrib/scripts/install_prereq install

#Run the configure script to satisfy build dependencies
sudo ./configure

#Setup menu options by running the following command:
sudo make menuselect

#On Add-ons select chan_ooh323 and format_mp3 .
#On Core Sound Packages, select the formats of Audio packets. Music On Hold, select 'Music onhold file package'
# select Extra Sound Packages
#Enable app_macro under Applications menu
#Change other configurations as required

#Build Asterisk
sudo make

#Install Asterisk by running the command:
sudo make install

#Install documentation(Optionally)
sudo make progdocs

#Install configs and samples
sudo make samples
sudo make config

#Create a separate user and group to run asterisk services:
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk
sudo chown -R asterisk.asterisk /etc/asterisk
sudo chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk.asterisk /usr/lib/asterisk

#Set Asterisk default user to asterisk:
sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf
echo -e "\e[32m asterisk Install OK!\e[m"

#Restart asterisk service
sudo systemctl restart asterisk

#Enable asterisk service to start on system  boot
sudo systemctl enable asterisk

#Test to see if it connect to Asterisk CLI
sudo asterisk -rvv

#open http ports and ports 5060,5061 in ufw firewall
sudo ufw allow proto tcp from any to any port 5060,5061
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
