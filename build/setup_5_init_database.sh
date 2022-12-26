#!/bin/bash

set -e 


# Make sure we are running as user mastodon
if [[ "x$(whoami)" != "xmastodon" ]]; then
   echo "This script must be run as user mastodon" 
   exit 1
fi
# There will be a handful of options to set. The defaults are fine for now.
RAILS_ENV=production bundle exec rake mastodon:setup

echo "Finished: please return to root and run setup_6_nginx_and_ssl.sh"