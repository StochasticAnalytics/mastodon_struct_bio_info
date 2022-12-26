#!/bin/bash

set -e 


# Make sure we are running as user mastodon
if [[ "x$(whoami)" != "xmastodon" ]]; then
   echo "This script must be run as user mastodon" 
   exit 1
fi

#TODO should set this to a specific version. At the time, it is 4.0.2

git clone https://github.com/mastodon/mastodon.git live && cd live
git checkout $(git tag -l | grep -v 'rc[0-9]*$' | sort -V | tail -n 1)
bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)
yarn install --pure-lockfile



echo "Finished: please now run setup_5_init_database.sh"

# 
