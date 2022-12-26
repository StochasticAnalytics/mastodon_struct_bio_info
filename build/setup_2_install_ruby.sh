#!/bin/bash

set -e

# Make sure we are running as user mastodon
if [[ "x$(whoami)" != "xmastodon" ]]; then
   echo "This script must be run as user mastodon" 
   exit 1
fi

# Start in the home directory
cd $HOME



git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc

echo "Please remove lines blocking non-interactive shells from ~/.bashrc"
nano ~/.bashrc
source ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 3.0.4
rbenv global 3.0.4

gem install bundler --no-document

echo -e "\nFinished: please return to root and run setup_3_configure_postgres.sh\n"

