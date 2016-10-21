#!/bin/bash

# Script to ensure VPN is running with kill switch functionality

DEBUG_MODE=true
DEBUG_PATH=/usr/vpn_trafficjail/vpn_log.txt

VPN_DIR=/etc/openvpn
ISP_IP='' # set your ISP IP - mask is fine i.e. 171. or 171.2.
# takes opvn file as cli argument
VPN=$1

restartVPN()
{

if [ "$DEBUG_MODE" = true ] ; then echo "Restarting VPN..." >> $DEBUG_PATH ; fi
# add kill commands here

# flush iptables to allow all connections to reconnect to VPN
iptables -F
iptables -A INPUT -j ACCEPT
iptables -A OUTPUT -j ACCEPT
cd $VPN_DIR
openvpn $VPN &
sleep 15

# Get VPN IP
VPN_IP=$(wget http://ipinfo.io/ip -qO -)

# check that the IP address is NOT from your ISP
if [ $VPN_IP == *'169'*]
then
    if [ "$DEBUG_MODE" = true ] ; then echo "ISP subnet detected . . . Will try again" >> $DEBUG_PATH ; fi
    exit 1
fi

if [ "$DEBUG_MODE" = true ] ; then echo "Updating iptables..." >> $DEBUG_PATH ; fi
# Configure and apply the iptables policy based on new VPN address
iptables -F
iptables -A INPUT -i lo -j ACCEPT # Loopback.
iptables -A OUTPUT -o lo -j ACCEPT # Loopback.
iptables -A INPUT -s 100.0.10.0/16 -d 10.0.10.0/16 -j ACCEPT # Private local addresses.
iptables -A OUTPUT -s 100.0.10.0/16 -d 10.0.10.0/16 -j ACCEPT # Private local addresses.
iptables -A INPUT -i tun+ -j ACCEPT # Incoming tunnel traffic.
iptables -A OUTPUT -o tun+ -j ACCEPT # Outgoing tunnel traffic.
iptables -A INPUT -p udp --sport 1194 -s $VPN_IP -j ACCEPT # Incoming VPN server traffic.
iptables -A OUTPUT -p udp --dport 1194 -d $VPN_IP -j ACCEPT # Outgoing VPN server traffic.
iptables -A INPUT -j DROP # Block all other incoming packets.
iptables -A OUTPUT -j DROP # Block all other outgoing packets.
if [ "$DEBUG_MODE" = true ] ; then echo "Now only allowing traffic through the VPN server at $VPN_IP." >> $DEBUG_PATH ; fi

# add revival commands here
}

if [ "$DEBUG_MODE" = true ] ; then date >> $DEBUG_PATH ; fi
VPN_RUNNING=$(ps -e | grep openvpn)
if [ $? -eq 0 ]
then
    VPN_IP=$(wget http://ipinfo.io/ip -qO -)
	if [ "$DEBUG_MODE" = true ] ; then echo "VPN is running -- IP address: $VPN_IP" >> $DEBUG_PATH ; fi
else
	if [ "$DEBUG_MODE" = true ] ; then echo "VPN is NOT running" >> $DEBUG_PATH ; fi
    pkill openvpn
	restartVPN
fi
