#!/bin/bash

set -euo pipefail

echo
echo "| Привет! Установим необходимый софт на Fedora 44."

echo
echo "| Начинаем обновление и настройку репозиториев..."

echo
echo "| Обновляем систему:"

sudo dnf upgrade --refresh -y
sudo dnf install -y dnf-plugins-core

echo
echo "| Настраиваем RPM Fusion и Flatpak:"

sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

sudo dnf install -y flatpak plasma-discover-backend-flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo
echo "| Устанавливаем базовый набор приложений:"

sudo dnf install -y \
    curl \
    conky \
    lm_sensors \
    psensor \
    bleachbit \
    mc \
    neofetch \
    htop \
    btop \
    vlc

echo
echo "| Устанавливаем Google Chrome и Google Earth Pro:"

sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo dnf install -y https://dl.google.com/linux/direct/google-earth-pro-stable_current_x86_64.rpm || true

echo
echo "| Устанавливаем Visual Studio Code:"

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf check-release-update || true
sudo dnf install -y code

echo
echo "| Устанавливаем Anydesk (через RPM):"

sudo dnf install -y https://download.anydesk.com/linux/anydesk-6.4.0-1.el8.x86_64.rpm || true

echo
echo ">>> Anydesk установлен (или пропущен, если RPM не доступен)."

echo
echo "| Настраиваем GIT:"

git config --global user.email "mikan979@gmail.com"
git config --global user.name "MikAn79"

echo
echo "| Устанавливаем QEMU/KVM и libvirt:"

sudo dnf install -y qemu-kvm libvirt virt-install virt-manager bridge-utils libguestfs-tools
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd
sudo usermod -aG kvm,libvirt "$USER"

echo
echo "| Очищаем систему после установки:"

sudo dnf autoremove -y
sudo dnf clean all

echo
echo "Все готово. Рекомендуется перезагрузить систему."

# Конец установки
