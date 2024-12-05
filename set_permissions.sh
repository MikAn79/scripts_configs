#!/bin/bash

# Путь к папке
TARGET_DIR="/mnt/Distr/В работе/2024"

# Проверка существования директории
if [ -d "$TARGET_DIR" ]; then
    echo "Проверка и установка прав в каталоге: $TARGET_DIR"

    # Установка прав доступа на папки: rwxr-xr-x
    find "$TARGET_DIR" -type d -exec chmod 755 {} \;
    echo "Права доступа на папки установлены."

    # Установка прав доступа на файлы: rw-r--r--
    find "$TARGET_DIR" -type f -exec chmod 644 {} \;
    echo "Права доступа на файлы установлены."

    echo "Настройка завершена."
else
    echo "Каталог $TARGET_DIR не существует. Проверьте путь."
fi
