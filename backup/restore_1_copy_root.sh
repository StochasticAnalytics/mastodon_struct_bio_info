#!/bin/bash

set -e

# This script will restore from a backup directory with a given structure (see create_full_backup.sh)
# Assuming we've run the setup scripts 1->5 and have stopped prior to initializing the database

# The path to the (decryted) ~/live/.env.production is required as the second argument

# It is not intended to be used regularly, where we'll prefer to grab the same data structure from rolling snapshots. TODO

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
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

# Get the nginx config
cp $BACKUP_DIR/default /etc/nginx/sites-available/default 
cp $BACKUP_DIR/mastodon /etc/nginx/sites-available/mastodon 
cp $BACKUP_DIR/nginx.conf /etc/nginx/nginx.conf
ln -sf /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon

# Get the mastodon config
cp $BACKUP_DIR/mastodon-*.service /etc/systemd/system/

# /etc/pgbouncer (we'lre not using this yet)

cp $ENV_PRODUCTION_PATH ~mastodon/live/.env.production
chown mastodon:mastodon  ~mastodon/live/.env.production


echo -e "\n\nFinished: please change to user mastodon and run restore_2_set_db.sh"




