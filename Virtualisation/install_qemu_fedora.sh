#!/bin/bash

# Скрипт установки QEMU/KVM на Fedora 43
set -e

echo "=== Установка QEMU/KVM на Fedora 43 ==="

# Обновление системы
echo "Обновление системы..."
sudo dnf update -y

# Установка необходимых пакетов
echo "Установка QEMU/KVM и зависимостей..."
sudo dnf install -y \
    qemu-kvm \
    libvirt \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt-client \
    bridge-utils \
    libguestfs-tools \
    guestfs-tools

# Включение и запуск служб
echo "Включение и запуск служб libvirt..."
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd

# Добавление пользователя в группы
echo "Добавление текущего пользователя в группы libvirt и kvm..."
USER=$(whoami)
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Настройка SELinux
echo "Настройка SELinux для libvirt..."
sudo setsebool -P virt_use_nfs 1
sudo setsebool -P virt_use_samba 1

# Настройка файервола для libvirt
echo "Настройка файервола для libvirt..."
sudo firewall-cmd --permanent --add-service=libvirt
sudo firewall-cmd --permanent --add-service=libvirt-tls
sudo firewall-cmd --permanent --add-service=mdns
sudo firewall-cmd --reload

# Создание сетевого моста по умолчанию
echo "Проверка сетевого моста по умолчанию..."
if ! sudo virsh net-list --all | grep -q "default"; then
    echo "Создание сети по умолчанию..."
    sudo virsh net-define /usr/share/libvirt/networks/default.xml
    sudo virsh net-autostart default
    sudo virsh net-start default
fi

# Проверка установки
echo "Проверка установки KVM..."
if lsmod | grep -q kvm; then
    echo "✓ Модуль KVM загружен"
else
    echo "✗ Модуль KVM не загружен"
fi

echo "Проверка возможности виртуализации..."
if [ $(grep -c "vmx\|svm" /proc/cpuinfo) -gt 0 ]; then
    echo "✓ Аппаратная виртуализация поддерживается"
else
    echo "✗ Аппаратная виртуализация не поддерживается"
fi

echo "=== Установка завершена ==="
echo "Перезагрузите систему или выполните 'newgrp libvirt' для применения изменений групп"
echo "Для управления виртуальными машинами используйте:"
echo "  - virt-manager (GUI)"
echo "  - virsh (командная строка)"