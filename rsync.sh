#!/bin/bash

rsync -avzrc --delete /home/mikan/Документы /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/Programs /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/Yandex.Disk /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/.config/yandex-browser-beta /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/.config/yandex-disk /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/.config/yd-tools /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/.thunderbird /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/.local/share/TelegramDesktop /mnt/sdb1/_Нужное/Backup/Linux_backup/
rsync -avzrc --delete /home/mikan/Изображения /mnt/sdb1/_Нужное/Backup/Linux_backup/
notify-send "Резервное копирование завершено"
