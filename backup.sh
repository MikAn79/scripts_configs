#!/bin/bash

# Папки для копирования
SOURCE1="/home/mikan/Документы"
SOURCE2="/home/mikan/Изображения"
SOURCE3="/home/mikan/Programs"
SOURCE4="/home/mikan/Yandex.Disk"
SOURCE5="/home/mikan/.config/yandex-browser-beta"
SOURCE6="/home/mikan/.config/yandex-disk"
SOURCE7="/home/mikan/.config/yd-tools"
SOURCE8="/home/mikan/.thunderbird"
SOURCE9="/home/mikan/.local/share/TelegramDesktop"

# Папка назначения для резервного копирования
DESTINATION="/mnt/sdb1/_Нужное/Backup/Linux_backup/111"

# Опции rsync
RSYNC_OPTS="-avzrch --delete --exclude=$EXCLUDE1 --exclude=$EXCLUDE2"

# Папки для исключения из архивации
EXCLUDE1="/home/mikan/.local/share/TelegramDesktop/tdata/user_data/cache/*"
EXCLUDE2="/home/mikan/.local/share/TelegramDesktop/tdata/user_data/media_cache/*"

# Функция для выполнения резервного копирования
backup() {
    echo "Начинается резервное копирование $1 ..."
    rsync $RSYNC_OPTS "$1" "$DESTINATION"
    if [ $? -eq 0 ]; then
        echo "Резервное копирование $1 завершено успешно!"
    else
        echo "Произошла ошибка при резервном копировании $1."
    fi
}

# Выполнение резервного копирования для каждой папки
backup "$SOURCE1"
backup "$SOURCE2"
backup "$SOURCE3"
backup "$SOURCE4"
backup "$SOURCE5"
backup "$SOURCE6"
backup "$SOURCE7"
backup "$SOURCE8"
backup "$SOURCE9"

# Уведомление о завершении
notify-send "Резервное копирование завершено" "Папки успешно скопированы на $DESTINATION"
