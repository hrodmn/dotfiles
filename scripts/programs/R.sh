#!/bin/bash
sudo apt update
# from https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-20-04
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
sudo apt install -y r-base
