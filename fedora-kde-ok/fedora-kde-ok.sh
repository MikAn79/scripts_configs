#!/bin/bash

dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

dnf update -y

dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel

dnf install -y lame\* --exclude=lame-devel

dnf group upgrade -y --with-optional Multimedia

dnf install -y dnfdragora hardinfo2 langpacks-ru audacious haruna vlc qbittorrent timeshift kolourpaint skanlite kamoso plasma-workspace-x11 mate-user-admin thunderbird

dnf remove -y dragon elisa-player  kaddressbook skanpage kmail akregator

dnf clean all

echo "Все операции выполнены. Теперь необходимо перезагрузить систему."
