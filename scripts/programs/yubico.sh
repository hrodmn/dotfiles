sudo add-apt-repository ppa:yubico/stable && sudo apt-get update

sudo apt install yubikey-manager yubikey-personalization-gui

# disable otp
ykman config usb --disable otp

