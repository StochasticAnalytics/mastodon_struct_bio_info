#!/bin/bash


domain_name="struct.bio"
admin_email="Benjamin.Himes@${domain_name}"

set -e

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi





awk -v WANTED_DOMAIN=$domain_name '{gsub("example.com",WANTED_DOMAIN)}{print $0}' /home/mastodon/live/dist/nginx.conf > /etc/nginx/sites-available/mastodon
ln -s /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon
systemctl reload nginx

certbot --nginx -d $domain_name
cp /home/mastodon/live/dist/mastodon-*.service /etc/systemd/system/

#If you deviated from the defaults at any point, check that the username and paths are correct:
# This is vanilla af
# # $EDITOR /etc/systemd/system/mastodon-*.service

echo "Setup is finished. Please confirm that the ssl cert is working and all firewall settings are good. Then run the final setup_6_enable_services.sh"

