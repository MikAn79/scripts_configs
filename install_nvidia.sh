#!/bin/bash

# Проверка на выполнение от суперпользователя
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт требует прав администратора. Запустите с sudo!"
    exit 1
fi

# Обновление системы
echo "Обновление системы..."
dnf upgrade -y

# Добавление репозиториев RPMFusion
echo "Добавление RPMFusion репозиториев..."
dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Установка драйверов NVIDIA
echo "Установка драйверов NVIDIA и зависимостей..."
dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-power

# Включение multilib (32-битные пакеты)
echo "Включение поддержки 32-битных архитектур..."
dnf install xorg-x11-drv-nvidia-libs.i686

# Пересборка модулей ядра
echo "Пересборка модулей ядра..."
akmods --force

# Обновление initramfs
echo "Обновление initramfs..."
dracut --force

# Активируем systemd-юниты для корректной работы ждущего и спящего режимов:

systemctl enable nvidia-{suspend,resume,hibernate}

# Завершение
echo "Установка завершена! Для применения изменений требуется перезагрузка."
echo "После перезагрузки проверьте драйверы командой: nvidia-smi"

# Опционально: автоматическая перезагрузка
read -p "Перезагрузить сейчас? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi#!/bin/bash
