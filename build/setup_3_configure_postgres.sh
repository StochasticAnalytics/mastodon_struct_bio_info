#!/bin/bash

set -e 

# Make sure run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# I grabbed these from PGTUNE for masto-server-1. These may need to be tuned manually. I have some bookmarks to revisit

{
echo "# DB Version: 15"
echo "# OS Type: linux"
echo "# DB Type: web"
echo "# Total Memory (RAM): 16 GB"
echo "# CPUs num: 8"
echo "# Data Storage: ssd"
echo ""
echo "max_connections = 200"
echo "shared_buffers = 4GB"
echo "effective_cache_size = 12GB"
echo "maintenance_work_mem = 1GB"
echo "checkpoint_completion_target = 0.9"
echo "wal_buffers = 16MB"
echo "default_statistics_target = 100"
echo "random_page_cost = 1.1"
echo "effective_io_concurrency = 200"
echo "work_mem = 5242kB"
echo "min_wal_size = 1GB"
echo "max_wal_size = 4GB"
echo "max_worker_processes = 8"
echo "max_parallel_workers_per_gather = 4"
echo "max_parallel_workers = 8"
echo "max_parallel_maintenance_workers = 4"
} >> /etc/postgresql/15/main/postgresql.conf
systemctl restart postgresql

# Create a DB user for Mastodon with ident authentication so mastodon can connect to the DB
sudo -u postgres psql << "EOF"
CREATE USER mastodon CREATEDB;
\q
EOF

echo -e "\nFinished: please return to user mastodon and run setup_4_install_mastodon.sh\n"