#!/bin/bash

set -e

# This script will restore from a backup directory with a given structure (see create_full_backup.sh)
# Assuming we've run the setup scripts 1->5 and have stopped prior to initializing the database

# The path to the (decryted) ~/live/.env.production is required as the second argument

# It is not intended to be used regularly, where we'll prefer to grab the same data structure from rolling snapshots. TODO

# Make sure we are running as user mastodon
if [[ "x$(whoami)" != "xmastodon" ]]; then
   echo "This script must be run as user mastodon" 
   exit 1
fi

# Take the first argument as the backup directory after checking that it is passed
if [ -z "$1" ]
  then
    echo "No backup directory supplied"
    exit 1
else
    BACKUP_DIR=$1
fi

# Take the second argument as the path to the .env.production file
if [ -z "$2" ]
  then
    echo "No path to .env.production supplied"
    exit 1
else
    ENV_PRODUCTION_PATH=$2
fi



# Start the copy of user data in the background
mkdir -p ~/live/public/system/
rsync -avz --progress ${BACKUP_DIR}/public/system/ ~/live/public/system/ 

# create the empty database
createdb -T template0 mastodon_production

# now restore the database
pg_restore -Fc -U mastodon -n public --no-owner --role=mastodon \
  -d mastodon_production ${BACKUP_DIR}/backup.dump


cd ~/live
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production ./bin/tootctl feeds build

echo -e "\n\nFinished: please now configure the firewall, then run (as root)  restore_set_ssl.sh"




