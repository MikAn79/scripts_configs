#!/bin/bash
# Скрипт установки QEMU/KVM и Cockpit на Fedora
set -e

# Опционально: логирование (раскомментируйте при необходимости)
# exec > >(tee -a ~/kvm-install-$(date +%F_%H-%M).log) 2>&1

echo "=== Установка QEMU/KVM и Cockpit на Fedora ==="

# Проверка, что система — Fedora
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
    echo "⚠️  Этот скрипт предназначен только для Fedora."
    exit 1
fi

# Определяем пользователя (даже если запущен через sudo)
USER=${SUDO_USER:-$(whoami)}
if [ "$USER" = "root" ]; then
    echo "⚠️  Запущено от root — пропускаем добавление в группы."
    ADD_TO_GROUPS=false
else
    ADD_TO_GROUPS=true
fi

# Определяем менеджер пакетов (dnf5 или dnf)
if command -v dnf5 >/dev/null 2>&1; then
    DNF="dnf5"
else
    DNF="dnf"
fi

# Обновление системы
echo "🔄 Обновление системы..."
sudo $DNF upgrade -y

# Установка необходимых пакетов
echo "📦 Установка QEMU/KVM, libvirt и Cockpit..."
sudo $DNF install -y \
    qemu-kvm \
    libvirt \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt-client \
    libguestfs-tools \
    cockpit \
    cockpit-machines \
    spice-vdagent \
    spice-webdavd \
    spice-glib \
    spice-server \
    libvirt-daemon-config-network  # гарантирует наличие default.xml

# Включение и запуск служб
echo "🔌 Включение и запуск служб..."
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd
sudo systemctl enable --now cockpit.socket

# Добавление пользователя в группы
if [ "$ADD_TO_GROUPS" = true ]; then
    echo "👥 Добавление пользователя '$USER' в группы libvirt и kvm..."
    sudo usermod -aG libvirt,kvm "$USER"
fi

# Настройка SELinux
echo "🛡️ Настройка SELinux..."
for bool in virt_use_nfs virt_use_samba cockpit_can_remote_network_connect; do
    if sudo getsebool "$bool" >/dev/null 2>&1; then
        sudo setsebool -P "$bool" 1
    else
        echo "ℹ️  SELinux boolean '$bool' не найден — пропускаем."
    fi
done

# Настройка firewalld (если запущен)
if systemctl is-active --quiet firewalld; then
    echo "🔥 Настройка firewalld..."
    sudo firewall-cmd --permanent --add-service=libvirt
    sudo firewall-cmd --permanent --add-service=libvirt-tls
    sudo firewall-cmd --permanent --add-service=mdns
    sudo firewall-cmd --permanent --add-service=cockpit
    sudo firewall-cmd --reload
else
    echo "ℹ️  firewalld не активен — настройка пропущена."
fi

# Проверка сети по умолчанию
echo "🌐 Проверка сети 'default'..."
if [ -f /usr/share/libvirt/networks/default.xml ]; then
    if ! sudo virsh net-list --all | grep -q "default"; then
        echo "Создание сети 'default'..."
        sudo virsh net-define /usr/share/libvirt/networks/default.xml
        sudo virsh net-autostart default
        sudo virsh net-start default
    else
        if sudo virsh net-list --inactive | grep -q "default"; then
            sudo virsh net-start default
        fi
        echo "Сеть 'default' уже существует."
    fi
else
    echo "⚠️  Файл default.xml отсутствует. Проверьте пакет libvirt-daemon-config-network."
fi

# Проверка загрузки модуля KVM
echo "🔍 Проверка модуля KVM..."
if lsmod | grep -q "kvm_"; then
    echo "✅ Модуль KVM загружен."
else
    echo "❌ Модуль KVM не загружен. Проверьте настройки BIOS/UEFI (VT-x/AMD-V)."
fi

# Проверка поддержки аппаратной виртуализации
echo "💻 Проверка поддержки виртуализации..."
if grep -Eq "vmx|svm" /proc/cpuinfo; then
    echo "✅ Аппаратная виртуализация поддерживается."
else
    echo "❌ Виртуализация не обнаружена (проверьте BIOS/UEFI)."
fi

# Финал
echo ""
echo "🎉 Установка завершена!"
if [ "$ADD_TO_GROUPS" = true ]; then
    echo "👉 Чтобы применить изменения групп, выполните:"
    echo "      newgrp libvirt"
    echo "   или просто перезагрузите систему."
fi
echo ""
echo "🛠️  Управление виртуальными машинами:"
echo "   - virt-manager (GUI)"
echo "   - virsh (CLI)"
echo "   - Cockpit Web UI: https://localhost:9090 → Раздел 'Виртуальные машины'"
echo ""
echo "💡 Совет: в Wayland используйте:"
echo "      GDK_BACKEND=x11 virt-manager"
