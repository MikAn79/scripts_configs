#!/bin/bash

# Определение доступных форматов
declare -A FORMATS
FORMATS[1]="jpg"
FORMATS[2]="png"
FORMATS[3]="gif"
FORMATS[4]="bmp"
FORMATS[5]="tiff"
FORMATS[6]="webp"
FORMATS[7]="svg"
FORMATS[8]="heic"
FORMATS[9]="pnm"
FORMATS[10]="pdf"
FORMATS[11]="многостраничный pdf"

# Печать списка форматов
echo "Выберите формат для конвертации изображений:"
for i in "${!FORMATS[@]}"; do
    echo "$i) ${FORMATS[$i]}"
done

# Считывание выбора пользователя
read -p "Введите номер формата (1-${#FORMATS[@]}): " FORMAT_CHOICE

# Проверка корректности выбора
if ! [[ $FORMAT_CHOICE =~ ^[1-9]$ || $FORMAT_CHOICE -eq ${#FORMATS[@]} ]]; then
    echo "Неверный выбор. Пожалуйста, запустите скрипт снова."
    exit 1
fi

# Получение выбранного формата
if [[ $FORMAT_CHOICE -eq ${#FORMATS[@]} ]]; then
    FORMAT="pdf"
    OUTPUT_FILE="new_files/multi_page.pdf"
else
    FORMAT=${FORMATS[$FORMAT_CHOICE]}
    OUTPUT_DIR="new_files"
    mkdir -p "$OUTPUT_DIR"
fi

# Создание многостраничного PDF
if [[ $FORMAT == "pdf" ]]; then
    # Папка с изображениями
    IMAGE_FILES=(*.jpg *.jpeg *.png *.gif *.bmp *.tiff *.webp *.svg *.heic *.pnm)

    # Проверка наличия изображений
    if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
        echo "Нет изображений для конвертации в многостраничный PDF."
        exit 1
    fi

    # Конвертация изображений в многостраничный PDF с изображением на каждой странице
    convert "${IMAGE_FILES[@]}" -quality 100 "$OUTPUT_FILE"
    echo "Создан многостраничный PDF: $OUTPUT_FILE"
else
    # Цикл по всем изображениям в текущей папке
    for FILE in *.*; do
        # Проверка, является ли файл изображением
        if [[ $FILE == *.jpg || $FILE == *.jpeg || $FILE == *.png || $FILE == *.gif || $FILE == *.bmp || $FILE == *.tiff || $FILE == *.webp || $FILE == *.svg || $FILE == *.heic || $FILE == *.pnm ]]; then
            # Определение имени выходного файла
            BASENAME=$(basename "$FILE")
            OUTPUT_FILE="$OUTPUT_DIR/${BASENAME%.*}.$FORMAT"

            # Конвертация файла
            convert "$FILE" "$OUTPUT_FILE"
            echo "Конвертировано: $FILE -> $OUTPUT_FILE"
        fi
    done
fi

echo "Конвертация завершена."
