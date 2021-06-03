#!/bin/bash

# Python
sudo apt install -y python3-dev python3-venv python3-pip jupyter

# configure virtual environment
mkdir ~/.virtualenv
pip3 install virtualenv virtualenvwrapper ipykernel

# set up st_cloud
mkvirtualenv st_cloud
cd ~/workspace/st_cloud
workon st_cloud
pip install -r requirements/requirements.txt
python3 -m ipykernel install --user --name=st_cloud

# set up sequoia
mkvirtualenv sequoia
cd ~/workspace/sequoia
workon sequoia
pip install -e . 
python3 -m ipykernel install --user --name=sequoia

# set up larger ST virtualenv
mkvirtualenv qgis
pip install st_storage --extra-index-url $PYPI_URL
