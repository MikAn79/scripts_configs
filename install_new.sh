#!/bin/sh

echo ""
echo "| Привет! Опять ставим систему заново? Ладно, дело ваше ... Давайте установим необходимый софт!"

echo ""
echo "| Итак, приступимс милорд:"

#Обновление системы после установки:


sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt autoremove && sudo apt clean && sudo apt autoclean && sudo apt autoremove --purge

# CURL

sudo apt-get install curl -y

# установка Flatpak

sudo apt install flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Установка софта

# preload

sudo apt install preload -y

# Conky

sudo apt install conky-all -y

# Sensors

sudo apt install lm-sensors psensor -y

# Synaptic

sudo apt install synaptic -y

# Чистильщик Bleachbit

sudo apt install bleachbit -y

# MC

sudo apt install mc -y

# Google Earth  # Google Chrome

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt update -y
sudo apt install google-chrome-stable -y
sudo apt install google-earth-pro-stable -y


# neofetch

sudo apt install neofetch -y

# Htop

sudo apt install htop -y
sudo apt install btop -y

# Mainline

sudo add-apt-repository ppa:cappelikan/ppa -y
sudo apt update -y
sudo apt install mainline -y

#Joplin

wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash

#VLC Media Player

#echo "Installing VLC Media Player"
sudo apt install vlc -y


# VS CODE

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update -y
sudo apt install code -y

# Установка Anydesk

sudo flatpak install anydesk -y
echo ""
echo ">>> Anydesk успешно установлен и настроен."

# GIT config

git config --global user.email mikan979@gmail.com
git config --global user.name "MikAn79"

# Grub Customizer. Настройка меню груб

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt update -y
sudo apt install grub-customizer -y

# Установка Qemu/KVM

sudo apt install qemu-kvm virt-manager virtinst libvirt-clients bridge-utils libvirt-daemon-system -y  &&
sudo systemctl enable --now libvirtd &&
sudo systemctl start libvirtd &&
sudo usermod -aG kvm $USER &&
sudo usermod -aG libvirt $USER &&

# Очистка после установки

sudo apt autoremove && sudo apt clean && sudo apt autoclean && sudo apt autoremove --purge

echo 'Все готово/ Система настроена. Рекомендуется перезагрузка '

# Конец установки
