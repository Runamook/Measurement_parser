#!/bin/bash

# Script launches USB modem in VRF using wvdial util

CFG="/etc/wvdial.conf.bk"
pon_wvdial="/usr/bin/pon.wvdial"
poff_wvdial="/usr/bin/poff.wvdial"
VRF="SBT"

PPPLOG=/var/log/ppp.log
LOGFILE=/var/log/beeline_checker.log
ip_netns="/sbin/ip netns exec $VRF"

TIMER=20
DATE=$(date +%s)

# Check if root

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


up() {
  $ip_netns sudo $pon_wvdial -C $CFG
  sleep $TIMER
}

down() {
  $ip_netns sudo $poff_wvdial
}


check_if_connected() {

  # Check 1st octet of ip address is "10"
  IP_ADDR=$($ip_netns ip -4 -br a | awk  ' /ppp/ {print $3}')
  OCTET_1=$($ip_netns ip -4 -br a | awk  ' /ppp/ {print $3}' | cut -d'.' -f 1)
  if [[ "$OCTET_1" -eq "10" ]]; then
    # Ok
    echo -e "$DATE::Assigned $IP_ADDR" > $LOGFILE
    RESULT="ok"
    echo 1
  else
    echo -e "$DATE::ERROR, no IP address found" > $LOGFILE
    $ip_netns ip a > $LOGFILE
    tail -30 $PPPLOG > $LOGFILE 
    echo -e "\n\n" > $LOGFILE
    RESULT="failed"
    echo 0
  fi

}

up
check_if_connected
down
