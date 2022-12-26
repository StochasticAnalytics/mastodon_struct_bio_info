#!/bin/bash

function add_ip_tables_to_build {
    # Setup a software firewall
apt install -y iptables-persistent

tmp_iptables=$(mktemp)
{
echo '*filter'
echo ''
echo '#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that does not use lo0'
echo '-A INPUT -i lo -j ACCEPT'
echo '-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT'
echo ''
echo '#  Accept all established inbound connections'
echo '-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'
echo ''
echo '#  Allow all outbound traffic - you can modify this to only allow certain traffic'
echo '-A OUTPUT -j ACCEPT'
echo ''
echo '#  Allow HTTP and HTTPS connections from anywhere (the normal ports for websites and SSL).'
echo '-A INPUT -p tcp --dport 80 -j ACCEPT'
echo '-A INPUT -p tcp --dport 443 -j ACCEPT'
echo ''
echo '#  Allow SSH connections'
echo '#  The -dport number should be the same port number you set in sshd_config'
echo '-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT'
echo ''
echo '#  Allow ping'
echo '-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT'
echo ''
echo '# Allow destination unreachable messages, especially code 4 (fragmentation required) is required or PMTUD breaks'
echo '-A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT'
echo ''
echo '#  Log iptables denied calls'
echo '-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7'
echo ''
echo '#  Reject all other inbound - default deny unless explicitly allowed policy'
echo '-A INPUT -j REJECT'
echo '-A FORWARD -j REJECT'
echo ''
echo 'COMMIT'
} > $tmp_iptables

cat $tmp_iptables | tee /etc/iptables/rules.v4
rm $tmp_iptables

iptables-restore < /etc/iptables/rules.v4

# Rules for IPv6 as well
tmp_iptables=$(mktemp)
{
echo '*filter'
echo ''
echo '#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that does not use lo0'
echo '-A INPUT -i lo -j ACCEPT'
echo '-A INPUT ! -i lo -d ::1/128 -j REJECT'
echo ''
echo '#  Accept all established inbound connections'
echo '-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'
echo ''
echo '#  Allow all outbound traffic - you can modify this to only allow certain traffic'
echo '-A OUTPUT -j ACCEPT'
echo ''
echo '#  Allow HTTP and HTTPS connections from anywhere (the normal ports for websites and SSL).'
echo '-A INPUT -p tcp --dport 80 -j ACCEPT'
echo '-A INPUT -p tcp --dport 443 -j ACCEPT'
echo ''
echo '#  Allow SSH connections'
echo '#  The -dport number should be the same port number you set in sshd_config'
echo '-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT'
echo ''
echo '#  Allow ping'
echo '-A INPUT -p icmpv6 -j ACCEPT'
echo ''
echo '#  Log iptables denied calls'
echo '-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7'
echo ''
echo '#  Reject all other inbound - default deny unless explicitly allowed policy'
echo '-A INPUT -j REJECT'
echo '-A FORWARD -j REJECT'
echo ''
echo 'COMMIT'
} > $tmp_iptables

cat $tmp_iptables | tee /etc/iptables/rules.v6
rm $tmp_iptables

ip6tables-restore < /etc/iptables/rules.v6

}