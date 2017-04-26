#!/bin/sh
set -e

INSTALL_PATH=/usr/local/dredger

mkdir -p $INSTALL_PATH /etc/bash_completion.d
wget https://github.com/outeredge/dredger/archive/master.tar.gz -qO - | tar -zxf - -C $INSTALL_PATH --strip=1
ln -sf $INSTALL_PATH/dredger /usr/local/bin/dredger
ln -sf $INSTALL_PATH/autocomplete.sh /etc/bash_completion.d/dredger

echo "Dredger installed successfully!"
