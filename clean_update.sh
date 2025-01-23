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
dnf clean all

# Шаг 2: Удаление старых ядер (оставляем последние 2 версии)
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

# Шаг 4: Очистка кэша страниц
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

# Шаг 8: Обновление прошивок (опционально, с проверкой наличия fwupdmgr)
#echo "Проверка обновлений прошивок..."
#if command -v fwupdmgr &> /dev/null; then
#    echo "Обновление прошивок через fwupdmgr..."
#    # Игнорируем ошибку, если метаданные уже обновлены
#    fwupdmgr refresh || echo "Метаданные уже обновлены, продолжение..."
#    # Проверяем наличие обновлений
#    updates_available=$(fwupdmgr get-updates --json | jq -r '.Devices | length')
#    if [ "$updates_available" -gt 0 ]; then
#        echo "Найдены обновления прошивок. Установка..."
#        fwupdmgr update -y
#    else
#        echo "Нет доступных обновлений прошивок."
#    fi
#else
#    echo "Утилита fwupdmgr не установлена. Пропуск обновления прошивок."
#fi

echo "Рекомендуется выполнить перезагрузку системы"

# Уведомление о завершении через KDE
if command -v kdialog &> /dev/null; then
    kdialog --title "Скрипт завершен" --msgbox "Все операции успешно завершены!\nРекомендуется выполнить перезагрузку системы."
else
    echo "Уведомление KDE не может быть отправлено: kdialog не установлен."
fi

echo "Рекомендуется выполнить перезагрузку системы"
