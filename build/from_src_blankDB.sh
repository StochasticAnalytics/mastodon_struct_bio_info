#!/bin/bash

# This script will build a mastodon server with blank database from the source code.
# This is to be used for migrating an existing database to a new server.

# Note that the iptables setup will still require

# In the future, a containerized approach would be sensible, but for now, this is a good start until I can understand the port forwarding and networking better.

# Prepared from https://docs.joinmastodon.org/admin/prerequisites/

# Assuming a clean Ubuntu 20.04 LTS install and a user with privileges added eg: user ALL=(ALL) NOPASSWD:ALL

# First make sure you are actually logging in to the server using keys and not via a password, otherwise this will lock you out. 
# Many hosting providers support uploading a public key and automatically set up key-based root login on new machines for you

# A few important defines
domain_name="struct.bio"
admin_email="Benjamin.Himes@${domain_name}"

set -e

echo -e "Important: are you sure you are set up for key based login? the next step will lock you out if you are not. (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Continuing..."
else
    echo "Exiting..."
    exit 1
fi

# Okay, get rid of password based ssh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
awk '{if(/^#PasswordAuthentication / || /PasswordAuthentication /) print "PasswordAuthentication no" ; else print $0}' /etc/ssh/sshd_config.bak | tee /etc/ssh/sshd_config
systemctl restart ssh.service

# Update the system
apt update && apt upgrade -y

# Install fail2ban to prevent brute force attacks
apt install fail2ban -y
tmp_fail2ban=$(mktemp)
{
echo '[DEFAULT]'
echo 'destemail = ${admin_email}'
echo 'sendername = Fail2Ban'
echo ''
echo '[sshd]'
echo 'enabled = true'
echo 'port = 22'
echo ''
echo '[sshd-ddos]'
echo 'enabled = true'
echo 'port = 22'
} > $tmp_fail2ban


cat $tmp_fail2ban | tee /etc/fail2ban/jail.local
rm $tmp_fail2ban

systemctl restart fail2ban

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


# On to installing the needed software

# First required packages
apt install -y curl wget gnupg apt-transport-https lsb-release ca-certificates

# Add the nodejs repo
curl -sL https://deb.nodesource.com/setup_16.x | bash -

wget -O /usr/share/keyrings/postgresql.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/postgresql.list

# More system packages

apt update
apt install -y \
     imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
     g++ libprotobuf-dev protobuf-compiler pkg-config nodejs gcc autoconf \
     bison build-essential libssl-dev libyaml-dev libreadline6-dev \
     zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
     nginx redis-server redis-tools postgresql postgresql-contrib \
     certbot python3-certbot-nginx libidn11-dev libicu-dev libjemalloc-dev

# Install yarn
corepack enable
yarn set version classic

# We will be using rbenv to manage Ruby versions, because it’s easier to get the right versions and to update once a newer release comes out. 
# rbenv must be installed for a single Linux user, therefore, first we must create the user Mastodon will be running as:

adduser --disabled-login mastodon

# Next, we want to do a few things as the mastodon user:
su -i -u mastodon bash << EOF
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 3.0.4
rbenv global 3.0.4
gem install bundler --no-document
EOF

# Now on to some setup work

# Create a DB user for Mastodon with ident authentication so mastodon can connect to the DB
su -u postgres psql << EOF
CREATE USER mastodon CREATEDB;
\q
EOF

# Mastodon setup as mastodon user
su -i -u mastodon bash << EOF
git clone https://github.com/mastodon/mastodon.git live && cd live
git checkout $(git tag -l | grep -v 'rc[0-9]*$' | sort -V | tail -n 1)
bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)
yarn install --pure-lockfile
RAILS_ENV=production bundle exec rake mastodon:setup
EOF

# Setup nginx

cp /home/mastodon/live/dist/nginx.conf /etc/nginx/sites-available/mastodon
ln -s /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon

mv /etc/nginx/sites-available/mastodon /etc/nginx/sites-available/mastodon.bak
awk -v WANTED_DOMAIN=$domain_name '{gsub("example.com",WANTED_DOMAIN)}{print $0}' /etc/nginx/sites-available/mastodon.bak | tee /etc/nginx/sites-available/mastodon

systemctl reload nginx

certbot --nginx -d $domain_name
cp /home/mastodon/live/dist/mastodon-*.service /etc/systemd/system/

#If you deviated from the defaults at any point, check that the username and paths are correct:
# This is vanilla af
# # $EDITOR /etc/systemd/system/mastodon-*.service

systemctl daemon-reload
systemctl enable --now mastodon-web mastodon-sidekiq mastodon-streaming

