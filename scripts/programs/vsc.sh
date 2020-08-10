#!/bin/bash

# Visual Studio Code
# https://code.visualstudio.com/docs/setup/linux
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt install -y apt-transport-https
sudo apt update
sudo apt install -y code
rm microsoft.gpg

# install extensions
code --install-extension ikuyadeu.r
code --install-extension reditorsupport.r-lsp
code --install-extension ms-azuretools.vscode-docker
code --install-extension github.vscode-pull-request-github
code --install-extension tht13.html-preview-vscode
code --install-extension ms-python.python
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension ivan-bocharov.stan-vscode
code --install-extension tomoki1207.pdf
code --install-extension eamodio.gitlens



# install radian terminal
pip install -U radian
