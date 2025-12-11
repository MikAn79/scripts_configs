#!/bin/bash

# Директория с изображениями
IMAGE_DIR="$HOME/Изображения/Wallpapers KDE Plasma 6"

# Имя итогового GIF-файла
OUTPUT_GIF="$HOME/Изображения/Wallpapers KDE Plasma 6/animated.gif"

# Задержка между кадрами в сотых долях секунды (100 = 1 секунда)
DELAY=50

# Создание GIF из всех изображений в директории
convert -delay $DELAY "$IMAGE_DIR"/*.* "$OUTPUT_GIF"

echo "GIF создан: $OUTPUT_GIF"



