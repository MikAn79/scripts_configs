#!/bin/sh


sudo apt update -y &&
sudo apt install qemu-kvm virt-manager virtinst libvirt-clients bridge-utils libvirt-daemon-system -y  &&
sudo systemctl enable --now libvirtd &&
sudo systemctl start libvirtd &&
sudo usermod -aG kvm $USER &&
sudo usermod -aG libvirt $USER &&

sudo virt-manager
