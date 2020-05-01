#!/bin/bash
sudo apt update
gpg --keyserver keys.gnupg.net --recv-keys 3F32EE77E331692F
sudo apt install gdebi-core
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.2.5042-amd64.deb
sudo gdebi rstudio-1.2.5042-amd64.deb
rm rstudio-1.2.5042-amd64.deb
