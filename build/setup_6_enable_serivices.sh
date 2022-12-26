#!/bin/bash


set -e

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi


systemctl daemon-reload
systemctl enable --now mastodon-web mastodon-sidekiq mastodon-streaming