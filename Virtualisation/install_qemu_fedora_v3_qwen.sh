#!/bin/bash
# Скрипт установки QEMU/KVM на Fedora
set -e

# Опционально: логирование (раскомментируйте, если нужно)
# exec > >(tee -a ~/kvm-install-$(date +%F_%H-%M).log) 2>&1

echo "=== Установка QEMU/KVM на Fedora ==="

# Проверка, что система — Fedora
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
    echo "⚠️ Этот скрипт предназначен для Fedora. Обнаружена другая ОС."
    exit 1
fi

# Определяем пользователя (даже если запущен через sudo)
USER=${SUDO_USER:-$(whoami)}
if [ "$USER" = "root" ]; then
    echo "⚠️ Не удалось определить обычного пользователя. Добавление в группы пропущено."
    ADD_TO_GROUPS=false
else
    ADD_TO_GROUPS=true
fi

# Выбор менеджера пакетов
if command -v dnf5 >/dev/null 2>&1; then
    DNF="dnf5"
else
    DNF="dnf"
fi

# Обновление системы
echo "🔄 Обновление системы..."
sudo $DNF upgrade -y

# Установка необходимых пакетов
echo "📦 Установка QEMU/KVM и зависимостей..."
sudo $DNF install -y \
    qemu-kvm \
    libvirt \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt-client \
    libguestfs-tools \
    cockpit-machines \
    libvirt-daemon-config-network  # гарантирует наличие default.xml

# Включение и запуск служб
echo "🔌 Включение и запуск служб libvirt..."
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd
sudo systemctl enable --now cockpit.socket

# Добавление пользователя в группы
if [ "$ADD_TO_GROUPS" = true ]; then
    echo "👥 Добавление пользователя '$USER' в группы libvirt и kvm..."
    sudo usermod -aG libvirt,kvm "$USER"
fi

# Настройка SELinux (безопасно)
echo "🛡️ Настройка SELinux для libvirt..."
for bool in virt_use_nfs virt_use_samba; do
    if sudo getsebool "$bool" >/dev/null 2>&1; then
        sudo setsebool -P "$bool" 1
    else
        echo "ℹ️ SELinux boolean '$bool' не найден — пропускаем."
    fi
done

# Настройка файервола (только если firewalld активен)
if systemctl is-active --quiet firewalld; then
    echo "🔥 Настройка firewalld для libvirt..."
    sudo firewall-cmd --permanent --add-service=libvirt
    sudo firewall-cmd --permanent --add-service=libvirt-tls
    sudo firewall-cmd --permanent --add-service=mdns
    sudo firewall-cmd --reload
else
    echo "ℹ️ firewalld не активен — настройка пропущена."
fi

# Создание сети по умолчанию (virbr0)
echo "🌐 Проверка сетевой сети по умолчанию (default)..."
if [ -f /usr/share/libvirt/networks/default.xml ]; then
    if ! sudo virsh net-list --all | grep -q "default"; then
        echo "Создание сети 'default'..."
        sudo virsh net-define /usr/share/libvirt/networks/default.xml
        sudo virsh net-autostart default
        sudo virsh net-start default
    else
        echo "Сеть 'default' уже существует."
    fi
else
    echo "⚠️ Файл default.xml отсутствует. Убедитесь, что установлен пакет libvirt-daemon-config-network."
fi

# Проверка модуля KVM
echo "🔍 Проверка загрузки модуля KVM..."
if lsmod | grep -q "kvm_"; then
    echo "✅ Модуль KVM загружен"
else
    echo "❌ Модуль KVM не загружен. Проверьте, включена ли виртуализация в BIOS/UEFI."
fi

# Проверка поддержки аппаратной виртуализации
echo "💻 Проверка поддержки аппаратной виртуализации..."
if grep -Eq "vmx|svm" /proc/cpuinfo; then
    echo "✅ Аппаратная виртуализация поддерживается"
else
    echo "❌ Аппаратная виртуализация не обнаружена"
fi

# Завершение
echo ""
echo "🎉 Установка завершена!"
if [ "$ADD_TO_GROUPS" = true ]; then
    echo "👉 Чтобы применить изменения групп, выполните:"
    echo "      newgrp libvirt"
    echo "   или перезагрузите систему."
fi
echo ""
echo "🛠️  Для управления ВМ используйте:"
echo "   - virt-manager (GUI)"
echo "   - virsh (CLI)"
echo "   - Cockpit Web UI: http://localhost:9090 → Machines"
echo ""
echo "💡 Совет: в среде Wayland запускайте virt-manager так:"
echo "      GDK_BACKEND=x11 virt-manager"