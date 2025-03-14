#!/usr/bin/bash

# Проверка наличия обновлений
updates=$(dnf5 check-upgrade | wc -l)

if [ $updates -gt 0 ]; then
  echo "Доступны обновления. Для установки запустите 'sudo dnf upgrade'." | kdialog --msgbox
fi
