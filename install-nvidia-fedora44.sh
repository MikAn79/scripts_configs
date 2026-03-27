#!/bin/bash
# Установка драйверов NVIDIA на Fedora 44 через RPM Fusion
# Запускать в консольном режиме (Ctrl+Alt+F2) — НЕ в графической среде!

set -e

# Проверка что скрипт запущен с sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Этот скрипт должен быть запущен с sudo"
    exit 1
fi

# Логирование (необязательно, но полезно)
exec > >(tee -a /root/nvidia-install-$(date +%F_%H-%M).log) 2>&1

echo "=== Установка драйверов NVIDIA на Fedora 44 ==="
echo "⚠️ ВАЖНО: Запустите этот скрипт в консольном режиме (Ctrl+Alt+F2)"
echo "   Графическая среда должна быть выключена!"

# Проверка, что это Fedora
if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
    echo "❌ Этот скрипт предназначен только для Fedora."
    exit 1
fi

# Проверка, не запущен ли X/Wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ "$XDG_SESSION_TYPE" = "x11" ] || [ -n "$DISPLAY" ]; then
    echo "❌ Скрипт запущен в графической среде. Переключитесь в TTY (Ctrl+Alt+F2) и повторите."
    exit 1
fi

# Проверка архитектуры
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    echo "❌ Поддерживаются только x86_64 системы."
    exit 1
fi

# Проверка наличия dnf5
if command -v dnf5 >/dev/null 2>&1; then
    DNF="dnf5"
else
    DNF="dnf"
fi

# Включение RPM Fusion
echo "🔄 Включение репозиториев RPM Fusion..."
sudo $DNF install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo $DNF install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Установка драйверов NVIDIA
echo "📦 Установка драйверов NVIDIA..."
sudo $DNF install -y \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-libs \
    xorg-x11-drv-nvidia-cuda  # опционально, если нужна CUDA
# Если нужен Vulkan:
# sudo $DNF install -y nvidia-vulkan-icd

# Отключение nouveau (если включён)
echo "🚫 Отключение драйвера nouveau..."
if lsmod | grep -q nouveau; then
    echo "Драйвер nouveau загружен — отключаем..."
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf >/dev/null
    sudo dracut --force
else
    echo "Драйвер nouveau не загружен — пропускаем."
fi

# Пересборка модулей ядра
echo "🔧 Пересборка модулей NVIDIA через akmods..."
sudo akmods --force

# Обновление initramfs
echo "📦 Обновление initramfs..."
sudo dracut --force

# Дополнительно: если Secure Boot включён — нужно подписать модули
if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
    echo "🔒 Secure Boot включён. Требуется подпись модуля NVIDIA:"
    echo "   1. После перезагрузки система запросит пароль MOK"
    echo "   2. Введите пароль и подтвердите подпись модуля"
    echo "   3. Или выполните: sudo mokutil --import /var/lib/dkms/nvidia/.../x86_64/.../nvidia.ko"
    echo "      (точный путь зависит от версии драйвера)"
else
    echo "✅ Secure Boot выключен — подпись не требуется."
fi

# Предупреждение о перезагрузке
echo ""
echo "🎉 Установка завершена!"
echo "📌 Обязательно перезагрузите систему:"
echo "      sudo reboot"
echo ""
echo "💡 После перезагрузки проверьте работу драйвера:"
echo "      nvidia-smi"
echo "      lspci | grep -i nvidia"
echo ""
echo "⚠️ Если после перезагрузки нет изображения — попробуйте:"
echo "   - Загрузиться в режиме восстановления (recovery mode)"
echo "   - Удалить файлы /etc/X11/xorg.conf (если есть)"
echo "   - Или использовать параметр ядра 'nomodeset' временно"

# Опционально: создание файла-флага для будущих скриптов
sudo touch /etc/.nvidia-installed