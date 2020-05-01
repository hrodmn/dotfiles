#!/bin/bash
sudo apt update

sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable
sudo apt install -y --allow-unauthenticated libudunits2-dev libgdal-dev libgeos-dev libproj-dev grass qgis
