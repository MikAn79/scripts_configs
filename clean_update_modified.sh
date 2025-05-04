#!/bin/bash

# Скрипт требует прав администратора
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен с правами root!"
    exit 1
fi

# Функция для обработки ошибок
handle_error() {
    echo "Произошла ошибка на шаге: $1"
    exit 1
}

# Включить автоматический выход при ошибках
set -e

trap 'handle_error "$BASH_COMMAND"' ERR

echo "=== Начало процесса очистки и обновления ==="

# Шаг 1: Очистка кэша DNF
echo "Очистка кэша DNF..."
dnf autoremove -y
dnf clean all
rm -f /var/cache/dnf/fastestmirror.cache
pkcon refresh force -y

# Шаг 2: Удаление старых ядер (кроме 2 последних версий)
echo "Удаление старых ядер (кроме 2 последних версий)..."
old_kernels=$(dnf repoquery --installonly --latest-limit=-2 -q)
if [ -n "$old_kernels" ]; then
    dnf remove -y $old_kernels
else
    echo "Нет старых ядер для удаления"
fi

# Шаг 3: Очистка временных файлов
echo "Очистка системных временных файлов..."
rm -rf /var/tmp/*
rm -rf /tmp/*
journalctl --vacuum-time=2d

# Шаг 4: Очистка кэша страниц памяти
echo "Очистка кэша страниц памяти..."
sync; echo 1 > /proc/sys/vm/drop_caches

# Шаг 5: Обновление системы
echo "Обновление системы..."
dnf upgrade --refresh -y

# Шаг 6: Обновление Flatpak
echo "Обновление Flatpak..."
flatpak update -y

# Шаг 7: Очистка неиспользуемых Flatpak-приложений
echo "Очистка неиспользуемых Flatpak-приложений..."
flatpak uninstall --unused -y

# Удаление пустых папок в кэше
find ~/.cache/ -type d -empty -delete

# Шаг 8: Проверка обновления ядра и пересборка модулей
echo "Проверка, обновилось ли ядро..."

current_kernel=$(uname -r)
latest_installed_kernel=$(rpm -q kernel | sort -V | tail -n 1 | sed 's/kernel-//')

if [[ "$current_kernel" != "$latest_installed_kernel" ]]; then
    echo "Обнаружено обновление ядра: $current_kernel → $latest_installed_kernel"
    echo "Пересборка модулей ядра и initramfs..."
    akmods --force
    dracut --force
else
    echo "Ядро не обновлялось. Пересборка не требуется."
fi

echo "Рекомендуется выполнить перезагрузку системы"

# Уведомление о завершении через KDE
if command -v kdialog &> /dev/null; then
    kdialog --title "Скрипт завершен" --msgbox "Все операции успешно завершены!\nРекомендуется выполнить перезагрузку системы."
else
    echo "Уведомление KDE не может быть отправлено: kdialog не установлен."
fi

echo "Рекомендуется выполнить перезагрузку системы"
