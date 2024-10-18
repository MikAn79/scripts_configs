#!/bin/bash

# Папка, где находятся архивы резервного копирования
BACKUP_DIR="/mnt/sdb1/_Нужное/Backup/Linux_backup"

# Функция для выбора архива
choose_archive() {
    echo "Выбор архива для восстановления..."

    # Проверяем наличие утилиты dialog для графического интерфейса выбора
    if command -v dialog &> /dev/null; then
        # Получаем список архивов
        archives=($(ls -1t "$BACKUP_DIR"/linux_backup_*.tar.gz 2>/dev/null))

        # Проверка наличия архивов
        if [ ${#archives[@]} -eq 0 ]; then
            echo "Нет доступных архивов для восстановления."
            exit 1
        fi

        # Формируем список архивов для выбора
        archive_list=()
        for i in "${!archives[@]}"; do
            archive_list+=("$i" "${archives[$i]}")
        done

        # Выбор архива через диалог
        dialog --menu "Выберите архив для восстановления" 15 60 4 "${archive_list[@]}" 2> /tmp/restore_choice.txt

        # Чтение выбранного архива
        choice=$(< /tmp/restore_choice.txt)
        ARCHIVE="${archives[$choice]}"
    else
        # Если dialog недоступен, выводим список архивов для текстового выбора
        echo "Доступные архивы:"
        select archive in "$BACKUP_DIR"/linux_backup_*.tar.gz; do
            if [ -n "$archive" ]; then
                ARCHIVE="$archive"
                break
            else
                echo "Неверный выбор. Попробуйте снова."
            fi
        done
    fi

    echo "Выбран архив: $ARCHIVE"
}

# Функция для восстановления данных
restore_data() {
    echo "Начинается процесс восстановления данных из архива: $ARCHIVE"

    # Восстановление данных по исходным путям
    tar -xzf "$ARCHIVE" -C /

    if [ $? -eq 0 ]; then
        echo "Восстановление данных успешно завершено!"
    else
        echo "Произошла ошибка при восстановлении данных."
        exit 1
    fi
}

# Вызов функции выбора архива
choose_archive

# Подтверждение перед восстановлением
read -p "Вы уверены, что хотите восстановить данные из архива $ARCHIVE? Это перезапишет существующие файлы. (y/n): " confirmation
if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
    restore_data
else
    echo "Восстановление отменено."
    exit 0
fi

# Уведомление о завершении
notify-send "Восстановление завершено" "Данные успешно восстановлены из архива $ARCHIVE"
