#!/bin/sh
set -e

INSTALL_PATH=/usr/local/dredger

sudo mkdir -p $INSTALL_PATH
sudo wget https://github.com/outeredge/dredger/archive/master.tar.gz -qO - | sudo tar -zxf - -C $INSTALL_PATH --strip=1
sudo ln -sf $INSTALL_PATH/dredger /usr/local/bin/dredger
sudo ln -sf $INSTALL_PATH/autocomplete.sh /etc/bash_completion.d/dredger

echo "Dredger installed successfully!"
