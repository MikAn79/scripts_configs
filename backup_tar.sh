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
BACKUP_DIR="/mnt/sdb1/_Нужное/Backup/Linux_backup"

# Имя и путь для общего архива
ARCHIVE="$BACKUP_DIR/linux_backup_$(date +'%Y-%m-%d').tar.gz"

# Опции rsync
RSYNC_OPTS="-avh --delete --exclude=$EXCLUDE1 --exclude=$EXCLUDE2"

# Максимальное количество архивов
MAX_ARCHIVES=1

# Папки для исключения из архивации и rsync
EXCLUDE1="/home/mikan/.local/share/TelegramDesktop/tdata/user_data/cache"
EXCLUDE2="/home/mikan/.local/share/TelegramDesktop/tdata/user_data/media_cache"



# Автоматическое добавление всех переменных, начинающихся на "SOURCE", в массив
SOURCES=()
for var in $(compgen -v | grep '^SOURCE'); do
    SOURCES+=("${!var}")
done

# Проверка, добавлены ли папки в массив
if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "Нет папок для архивации."
    exit 1
fi

# Функция для удаления старых архивов
cleanup_old_archives() {
    echo "Проверка количества архивов в папке $BACKUP_DIR ..."
    
    # Находим архивы с шаблоном linux_backup_*.tar.gz
    archives=($(ls -1t "$BACKUP_DIR"/linux_backup_*.tar.gz 2>/dev/null))
    
    # Считаем количество архивов
    archive_count=${#archives[@]}
    
    # Если архивов больше, чем MAX_ARCHIVES, удаляем самые старые
    if [ "$archive_count" -gt "$MAX_ARCHIVES" ]; then
        echo "Найдено больше $MAX_ARCHIVES архивов. Удаление старых архивов..."
        
        # Удаляем самые старые архивы
        for ((i = $MAX_ARCHIVES; i < $archive_count; i++)); do
            echo "Удаление архива: ${archives[$i]}"
            rm -f "${archives[$i]}"
        done
        
        echo "Удаление старых архивов завершено."
    else
        echo "Количество архивов не превышает лимит ($MAX_ARCHIVES)."
    fi
}
# Удаление старых архивов перед созданием нового
cleanup_old_archives

# Создание общего архива для всех указанных папок, исключая указанные папки
echo "Создается общий архив для всех указанных папок: ${SOURCES[@]}, исключая: $EXCLUDE1, $EXCLUDE2 ..."
tar --exclude="$EXCLUDE1" --exclude="$EXCLUDE2" -czf "$ARCHIVE" "${SOURCES[@]}"
if [ $? -eq 0 ]; then
    echo "Общий архив успешно создан: $ARCHIVE"
else
    echo "Произошла ошибка при создании общего архива."
    exit 1
fi

# Копирование архива на внешний диск с исключением папок
echo "Начинается резервное копирование архива $ARCHIVE, исключая кеши Telegram..."
rsync $RSYNC_OPTS "$ARCHIVE" "$BACKUP_DIR"
if [ $? -eq 0 ]; then
    echo "Резервное копирование архива завершено успешно!"
else
    echo "Произошла ошибка при резервном копировании архива."
fi

# Уведомление о завершении
notify-send "Резервное копирование завершено" "Общий архив успешно создан и скопирован на $BACKUP_DIR"
