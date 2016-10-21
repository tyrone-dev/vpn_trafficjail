# VPN Traffic Jail

Ensures all Internet traffic is only routed through VPN. Updates iptables accordingly. Allows local network traffic regardless.

Assumes you're running OpenVPN.

Edit vpn_traffic_jail.sh to include 
* a mask for your ISP IP address
* updated location for log file
* an programs to terminate when VPN goes down (and to bring up again)
* your LAN address

## Usage
```
sudo bash vpn_traffic_jail.sh your_openvpn_file.ovpn
```


Suggest to add to crontab. This, for example, performs a check every 1 minute.

```
*/1 * * * * cd /usr/vpn_trafficjail && sudo bash vpn_traffic_jail.sh [your_openvpn_file.ovpn]
'''
