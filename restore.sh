#!/bin/bash

# Папки назначения для восстановления
DEST1="/home/mikan/Документы"
DEST2="/home/mikan/Изображения"
DEST3="/home/mikan/Programs"
DEST4="/home/mikan/Yandex.Disk"
DEST5="/home/mikan/.config/yandex-browser-beta"
DEST6="/home/mikan/.config/yandex-disk"
DEST7="/home/mikan/.config/yd-tools"
DEST8="/home/mikan/.thunderbird"
DEST9="/home/mikan/.local/share/TelegramDesktop"
# Папка с резервной копией
BACKUP_SOURCE="/mnt/sdb1/_Нужное/Backup/Linux_backup/111"

# Опции rsync
RSYNC_OPTS="-avzrch --delete"

# Функция для выполнения восстановления
restore() {
    echo "Начинается восстановление $1 из $2 ..."
    rsync $RSYNC_OPTS "$2" "$1"
    if [ $? -eq 0 ]; then
        echo "Восстановление $1 завершено успешно!"
    else
        echo "Произошла ошибка при восстановлении $1."
    fi
}

# Выполнение восстановления для каждой папки
restore "$DEST1" "$BACKUP_SOURCE/Документы/"
restore "$DEST2" "$BACKUP_SOURCE/Изображения/"
restore "$DEST3" "$BACKUP_SOURCE/Programs/"
restore "$DEST4" "$BACKUP_SOURCE/Yandex.Disk/"
restore "$DEST5" "$BACKUP_SOURCE/yandex-browser-beta/"
restore "$DEST6" "$BACKUP_SOURCE/yandex-disk/"
restore "$DEST7" "$BACKUP_SOURCE/yd-tools/"
restore "$DEST8" "$BACKUP_SOURCE/.thunderbird/"
restore "$DEST9" "$BACKUP_SOURCE/TelegramDesktop/"

# Уведомление о завершении
notify-send "Восстановление завершено" "Папки успешно восстановлены из $BACKUP_SOURCE"
