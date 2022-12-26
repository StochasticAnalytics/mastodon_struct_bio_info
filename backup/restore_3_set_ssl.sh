#!/bin/bash


domain_name="struct.bio"
admin_email="Benjamin.Himes@${domain_name}"

set -e

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi


echo -e "Important: did you remember to update the static nat to point to the new host and is the outbound rule also enabled? (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Continuing..."
else
    echo "Exiting..."
    exit 1
fi

# Could do this with awk, but for now just do it manually
echo "Remove ssl from the listening 443 and comment out the certificate paths"
nano /etc/nginx/sites-available/mastodon

systemctl reload nginx

certbot --nginx -d $domain_name
cp /home/mastodon/live/dist/mastodon-*.service /etc/systemd/system/

echo "Re-enable the ssl in the listening 443 and uncomment the certificate paths"
nano /etc/nginx/sites-available/mastodon
systemctl reload nginx

echo -e "\n\nFinished: please run (as root) build/setup_6_enable_services.sh\n\n"
