#!/bin/bash

# Скрипт требует прав администратора
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен с правами root!"
    exit 1
fi

# --- Настройки ---
LOG_FILE="/var/log/clean_update.log"
KEEP_KERNELS=2  # Количество последних версий ядер для хранения
DRY_RUN=false  # Режим "сухого запуска"
DEBUG=false    # Режим отладки

# --- Функции ---

# Функция для логирования сообщений
log_message() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$level] $message"
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Функция для обработки ошибок
handle_error() {
    local step="$1"
    local code="$2"
    log_message "ERROR" "Произошла ошибка на шаге: $step. Код возврата: $code"
    if $DEBUG; then
        echo "Выполнение команды: $BASH_COMMAND"
        exit 1
    fi
    exit 1
}

# Функция для проверки свободного места
check_free_space() {
    local threshold="$1"  # Минимальное свободное место в МБ
    local mount_point="$2" # Точка монтирования (например, "/")
    local free_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')
    if (( free_space < threshold )); then
        log_message "ERROR" "Недостаточно свободного места на $mount_point.  Свободно: $free_space МБ, Требуется: $threshold МБ"
        return 1
    else
        return 0
    fi
}

# --- Обработка аргументов командной строки ---

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--debug) DEBUG=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --keep-kernels) KEEP_KERNELS="$2"; shift 2 ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        *) echo "Неизвестный аргумент: $1"; exit 1 ;;
    esac
done

# --- Настройка отладки ---
if $DEBUG; then
    set -x  # Включить трассировку команд
    set -v  # Выводить строки ввода команд при их чтении
fi

# Включить автоматический выход при ошибках
set -e
trap 'handle_error "$BASH_COMMAND" $?' ERR

log_message "INFO" "=== Начало процесса очистки и обновления ==="

# --- Шаги ---

# Шаг 1: Очистка кэша DNF
if [[ "$1" == "" || "$1" == "--clean-dnf" ]]; then
    log_message "INFO" "Очистка кэша DNF..."
    dnf autoremove -y
    dnf clean packages  # Очистка только пакетов
    dnf clean metadata  # Очистка метаданных
    # rm -f /var/cache/dnf/fastestmirror.cache  # Не всегда нужно
    # pkcon refresh force -y # Удалено.  Избегаем дублирования с dnf
fi

# Шаг 2: Удаление старых ядер (кроме последних $KEEP_KERNELS версий)
if [[ "$1" == "" || "$1" == "--clean-kernels" ]]; then
    log_message "INFO" "Удаление старых ядер (кроме последних $KEEP_KERNELS версий)..."
    old_kernels=$(dnf repoquery --installonly --latest-limit=-$KEEP_KERNELS -q)
    if [ -n "$old_kernels" ]; then
        check_free_space 500 "/"  # Проверка 500 МБ свободного места
        if [ $? -eq 0 ]; then
            if $DRY_RUN; then
                log_message "INFO" "(Сухой запуск) Будут удалены старые ядра: $old_kernels"
            else
                dnf remove -y $old_kernels
            fi
        else
            log_message "WARNING" "Недостаточно свободного места для удаления ядер."
        fi
    else
        log_message "INFO" "Нет старых ядер для удаления"
    fi
fi

# Шаг 3: Очистка временных файлов
if [[ "$1" == "" || "$1" == "--clean-tmp" ]]; then
    log_message "INFO" "Очистка системных временных файлов..."
    # rm -rf /var/tmp/* # Опасно.  Заменено на find
    # rm -rf /tmp/* # Опасно.  Заменено на find
    find /var/tmp/ -type f -mtime +2 -delete
    find /tmp/ -type f -mtime +2 -delete
    journalctl --vacuum-time=2d
fi

# Шаг 4: Очистка кэша страниц памяти
#if [[ "$1" == "" || "$1" == "--clean-cache" ]]; then
#    log_message "INFO" "Очистка кэша страниц памяти..."
#    sync; echo 1 > /proc/sys/vm/drop_caches  #  Обычно не нужно
#fi

# Шаг 5: Обновление системы
if [[ "$1" == "" || "$1" == "--update-system" ]]; then
    log_message "INFO" "Обновление системы..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Будет выполнено dnf upgrade --refresh -y"
    else
        dnf upgrade --refresh -y
        dnf autoremove -y  # Еще раз после обновления
    fi
fi

# Шаг 6: Обновление Flatpak
if [[ "$1" == "" || "$1" == "--update-flatpak" ]]; then
    log_message "INFO" "Обновление Flatpak..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Будет выполнено flatpak update -y"
    else
        flatpak update -y
    fi
fi

# Шаг 7: Очистка неиспользуемых Flatpak-приложений
if [[ "$1" == "" || "$1" == "--clean-flatpak" ]]; then
    log_message "INFO" "Очистка неиспользуемых Flatpak-приложений..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Будет выполнено flatpak uninstall --unused -y"
    else
        flatpak uninstall --unused -y
    fi
fi

# Удаление пустых папок в кэше
if [[ "$1" == "" || "$1" == "--clean-cache" ]]; then
    log_message "INFO" "Удаление пустых папок в кэше..."
    find "$HOME/.cache/" -type d -empty -delete
fi

# Шаг 8: Проверка обновления ядра и пересборка модулей
if [[ "$1" == "" || "$1" == "--check-kernel" ]]; then
    log_message "INFO" "Проверка, обновилось ли ядро..."

    current_kernel=$(uname -r)
    latest_installed_kernel=$(rpm -q kernel | sort -V | tail -n 1 | sed 's/kernel-//')

    if [[ "$current_kernel" != "$latest_installed_kernel" ]]; then
        log_message "INFO" "Обнаружено обновление ядра: $current_kernel → $latest_installed_kernel"
        log_message "INFO" "Пересборка модулей ядра и initramfs..."
        if $DRY_RUN; then
            log_message "INFO" "(Сухой запуск) Будет выполнено akmods и dracut --all --force"
        else
            akmods --force  # Пересобрать модули
            dracut --regenerate-all --force # Пересоздать initramfs для всех ядер
        fi
    else
        log_message "INFO" "Ядро не обновлялось. Пересборка не требуется."
    fi
fi

log_message "INFO" "Рекомендуется выполнить перезагрузку системы"

# --- Уведомление о завершении ---
if command -v kdialog &> /dev/null; then
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Уведомление KDE: Все операции успешно завершены! Рекомендуется выполнить перезагрузку системы."
    else
        kdialog --title "Скрипт завершен" --msgbox "Все операции успешно завершены!\nРекомендуется выполнить перезагрузку системы."
    fi
elif command -v notify-send &> /dev/null; then
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Уведомление notify-send: Все операции успешно завершены! Рекомендуется выполнить перезагрузку системы."
    else
        notify-send "Скрипт завершен" "Все операции успешно завершены! Рекомендуется выполнить перезагрузку системы."
    fi
else
    log_message "WARNING" "Уведомление не может быть отправлено: kdialog или notify-send не установлены."
fi

log_message "INFO" "=== Завершение ==="

exit 0
