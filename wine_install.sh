#!/bin/bash

# Проверяем, является ли пользователь суперпользователем (root)
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами суперпользователя (root)." 
   exit 1
fi

# Добавляем репозиторий Wine
echo "Добавляем репозиторий Wine..."
dpkg --add-architecture i386 
wget -nc https://dl.winehq.org/wine-builds/winehq.key
apt-key add winehq.key
#apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ mantic main'
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/mantic/winehq-mantic.sources

# Обновляем список пакетов
echo "Обновляем список пакетов..."
apt-get update

# Устанавливаем Wine
echo "Устанавливаем Wine..."
apt-get install --install-recommends winehq-stable -y

# Печатаем сообщение об успешной установке
echo "Wine успешно установлен."

# Печатаем версию Wine
wine --version

# Завершаем скрипт
exit 0
