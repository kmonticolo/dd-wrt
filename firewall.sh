#!/bin/bash
# Personal note : add rules to /etc/rc.local file so they will be loaded after booting up
# Change modemif to your network interface value

modemif=br0

iptables -t mangle -N ack
iptables -t mangle -A ack -m tos ! --tos Normal-Service -j RETURN
iptables -t mangle -A ack -p tcp -m length --length 0:128 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A ack -p tcp -m length --length 128: -j TOS --set-tos Maximize-Throughput
iptables -t mangle -A ack -j RETURN
 
iptables -t mangle -A POSTROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK ACK -j ack

iptables -t mangle -N tosfix
iptables -t mangle -A tosfix -p tcp -m length --length 0:512 -j RETURN
#allow screen redraws under interactive SSH sessions to be fast:
iptables -t mangle -A tosfix -m hashlimit --hashlimit 20/sec --hashlimit-burst 20 \
--hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name minlat -j RETURN
iptables -t mangle -A tosfix -j TOS --set-tos Maximize-Throughput
iptables -t mangle -A tosfix -j RETURN
 
iptables -t mangle -A POSTROUTING -p tcp -m tos --tos Minimize-Delay -j tosfix

# Set high-priority class and relevant protocls whch uses it
iptables -t mangle -A POSTROUTING -o $modemif -p tcp -m tos --tos Minimize-Delay -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 53 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 53 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 80 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 80 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 443 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 443 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 22 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 22 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 137 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 137 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 138 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 138 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --sport 139 -j CLASSIFY --set-class 1:10
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 139 -j CLASSIFY --set-class 1:10

#Apply priority using tc
tc qdisc add dev $modemif root handle 1: htb default 12
tc class add dev $modemif parent 1: classid 1:1 htb rate 29700kbit ceil 29700kbit burst 10k
tc class add dev $modemif parent 1:1 classid 1:10 htb rate 5000kbit ceil 25000kbit prio 1 burst 10k
tc class add dev $modemif parent 1:1 classid 1:12 htb rate 1000kbit ceil 1000kbit prio 2
tc filter add dev $modemif protocol ip parent 1:0 prio 1 u32 match ip protocol 0x11 0xff flowid 1:10
tc qdisc add dev $modemif parent 1:10 handle 20: sfq perturb 10
tc qdisc add dev $modemif parent 1:12 handle 30: sfq perturb 10
