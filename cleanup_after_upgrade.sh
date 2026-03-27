#!/usr/bin/env bash

# Скрипт для пост‑релизной очистки Fedora после перехода на следующий релиз.
# Выполняет стандартные действия: чистит кеш dnf, удаляет старые ядра и
# ненужные пакеты, очищает временные каталоги и, если установлен,
# обслуживает Flatpak.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен запускаться с правами root." >&2
    exit 1
fi

log_file="/var/log/cleanup_after_upgrade.log"
keep_kernels=2

date >> "$log_file" && echo "=== Начинаем очистку после обновления ===" | tee -a "$log_file"

# Функция для записи логов
log() {
    local lvl="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$lvl" "$*" | tee -a "$log_file"
}

# Очистка кеша DNF и автоснятие
log INFO "Очистка кеша DNF и автоснятие неиспользуемых пакетов"
dnf autoremove -y | tee -a "$log_file"
dnf clean all | tee -a "$log_file"

# Удаление старых ядер — сохраняем последние $keep_kernels
log INFO "Удаление старых ядер (сохраняем $keep_kernels последних)"
old_kerns=$(dnf repoquery --installonly --latest-limit=-$keep_kernels -q || true)
if [[ -n "$old_kerns" ]]; then
    log INFO "Удаляем: $old_kerns"
    dnf remove -y $old_kerns | tee -a "$log_file"
else
    log INFO "Нет старых ядер для удаления"
fi

# Очистка временных файлов
log INFO "Очистка /tmp и /var/tmp (файлы старше 2 дней)"
find /tmp /var/tmp -depth -mindepth 1 -mtime +2 -exec rm -rf {} + 2>/dev/null || true
journalctl --vacuum-time=2d --quiet

# Обслуживание Flatpak (если присутствует)
if command -v flatpak &>/dev/null; then
    log INFO "Обновление Flatpak и удаление "unused""
    flatpak update -y --noninteractive | tee -a "$log_file"
    flatpak uninstall --unused -y --noninteractive | tee -a "$log_file"
else
    log INFO "Flatpak не установлен, пропускаем шаг";
fi

log INFO "Очистка завершена"

echo "Готово. см. $log_file для подробностей."