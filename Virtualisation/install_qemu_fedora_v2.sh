#!/bin/bash
# Скрипт установки QEMU/KVM на Fedora 43
set -e

echo "=== Установка QEMU/KVM на Fedora 43 ==="

# Проверка наличия dnf5
if command -v dnf5 >/dev/null 2>&1; then
    DNF="dnf5"
else
    DNF="dnf"
fi

# Обновление системы
echo "Обновление системы..."
sudo $DNF upgrade -y

# Установка необходимых пакетов
echo "Установка QEMU/KVM и зависимостей..."
sudo $DNF install -y \
    qemu-kvm \
    libvirt \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt-client \
    libguestfs-tools \
    guestfs-tools \
    cockpit-machines

# Включение и запуск служб
echo "Включение и запуск служб libvirt..."
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd
sudo systemctl enable --now cockpit.socket

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

# Создание сетевого моста по умолчанию (virbr0)
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
if grep -Eq "vmx|svm" /proc/cpuinfo; then
    echo "✓ Аппаратная виртуализация поддерживается"
else
    echo "✗ Аппаратная виртуализация не поддерживается"
fi

echo "=== Установка завершена ==="
echo "Перезагрузите систему или выполните 'newgrp libvirt' для применения изменений групп"
echo "Для управления виртуальными машинами используйте:"
echo "  - virt-manager (GUI, устаревающий)"
echo "  - virsh (CLI)"
echo "  - Cockpit Web UI (http://localhost:9090, модуль Machines)"
