#!/bin/bash
cd ~/workspace \
  && git clone git@github.com:SilviaTerra/aux-stats.git \
  && git clone git@github.com:SilviaTerra/basemap.git \
  && git clone git@github.com:SilviaTerra/sequoia.git \
  && git clone git@github.com:SilviaTerra/stcore.git \
  && git clone git@github.com:SilviaTerra/strpy.git \
  && git clone git@github.com:SilviaTerra/st_cloud.git \
  && git clone git@github.com:SilviaTerra/st_fiadb.git \
  && git clone git@github.com:SilviaTerra/st_growth.git \
  && git clone git@github.com:SilviaTerra/tidyFIA.git

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository -u https://cli.github.com/packages
sudo apt install gh
