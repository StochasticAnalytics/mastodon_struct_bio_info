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

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Okay, get rid of password based ssh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
awk '{if(/^#PasswordAuthentication / || /PasswordAuthentication /) print "PasswordAuthentication no" ; else print $0}' /etc/ssh/sshd_config.bak > /etc/ssh/sshd_config
systemctl restart ssh.service

# Update the system
apt update && apt upgrade -y

# Install fail2ban to prevent brute force attacks
apt install fail2ban -y
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
} > /etc/fail2ban/jail.local
systemctl restart fail2ban

# We are using a enterprise hardware firewall, so we will not be using iptables
use_softwall="n"
if [[ $use_softwall == "y" ]] ; then
    source add_iptables.sh
    add_ip_tables_to_build
fi


# On to installing the needed software

# First required packages
apt install -y curl wget gnupg apt-transport-https lsb-release ca-certificates

# Add the nodejs repo
curl -sL https://deb.nodesource.com/setup_16.x | bash -

wget -O /usr/share/keyrings/postgresql.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list

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

adduser --disabled-login mastodon

echo -e "\nFinished with the initial system setup. Please change to user mastodon and run setup_2_installRuby.sh\n"

# Now on to some setup work




