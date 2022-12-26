#!/bin/bash

set -e

# This script will backup *everything* we need to restore the instance on a new physical server
# except ~/live/.env.production which contains secrets and is backed up separately in an encrypted file

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

# Make the directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Stop the server
systemctl stop mastodon-*.service

# Get the nginx config
cp -pL /etc/nginx/sites-available/default $BACKUP_DIR
cp -pL /etc/nginx/sites-available/mastodon $BACKUP_DIR
cp -pL /etc/nginx/nginx.conf $BACKUP_DIR

# Get the mastodon config
cp /etc/systemd/system/mastodon-*.service $BACKUP_DIR

# /etc/pgbouncer (we'lre not using this yet)

pg_dump -Fc mastodon_production -f ${BACKUP_DIR}/backup.dump

mkdir -p ${BACKUP_DIR}/public/system
rsync -avz ~/live/public/system/ ${BACKUP_DIR}/public/public/system/




