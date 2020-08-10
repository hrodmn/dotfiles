#!/bin/bash

# Python
sudo apt install -y python3-dev python3-venv python3-pip jupyter

# configure virtual environment
mkdir ~/.virtualenv
pip3 install virtualenv virtualenvwrapper ipykernel

# set up st_aws
mkvirtualenv st_aws
cd ~/workspace/st_aws
workon st_aws
pip install -r requirements/requirements.txt
python3 -m ipykernel install --user --name=st_aws

# set up sequoia
mkvirtualenv sequoia
cd ~/workspace/sequoia
workon sequoia
pip install -e . 