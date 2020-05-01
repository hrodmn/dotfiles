#!/bin/bash

wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add

sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'

sudo apt update

sudo apt install -y atom
apm install --packages-file atom-packages.txt
