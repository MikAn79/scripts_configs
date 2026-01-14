#!/bin/bash

# Скрипт требует прав администратора
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен с правами root!" >&2
    exit 1
fi

# --- Настройки по умолчанию ---
LOG_FILE="/var/log/clean_update.log"
KEEP_KERNELS=2
DRY_RUN=false
DEBUG=false
QUIET=false

# По умолчанию выполняем все шаги
CLEAN_DNF=true
CLEAN_KERNELS=true
CLEAN_TMP=true
UPDATE_SYSTEM=true
UPDATE_FLATPAK=true
CLEAN_FLATPAK=true
CLEAN_USER_CACHE=false  # опционально
CHECK_KERNEL=true

# --- Функции ---

log_message() {
    local level="$1"; shift
    local message="$*"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local line="$timestamp [$level] $message"
    if [[ "$QUIET" == false ]]; then
        echo "$line"
    fi
    echo "$line" >> "$LOG_FILE"
}

handle_error() {
    local cmd="$BASH_COMMAND"
    local code="$?"
    log_message "ERROR" "Команда завершилась с ошибкой: '$cmd' (код $code)"
    exit "$code"
}

# --- Разбор аргументов ---
TEMP_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            cat <<EOF
Использование: $0 [ОПЦИИ]

Опции:
  --clean-dnf            Очистка кэша DNF (вкл. по умолчанию)
  --no-clean-dnf         Пропустить очистку DNF
  --clean-kernels        Удаление старых ядер (вкл.)
  --no-clean-kernels     Пропустить удаление ядер
  --clean-tmp            Очистка /tmp и /var/tmp (вкл.)
  --no-clean-tmp         Пропустить очистку временных файлов
  --update-system        Обновление системы (вкл.)
  --no-update-system     Пропустить обновление
  --update-flatpak       Обновление Flatpak (вкл.)
  --no-update-flatpak    Пропустить обновление Flatpak
  --clean-flatpak        Удаление неиспользуемых Flatpak (вкл.)
  --no-clean-flatpak     Пропустить очистку Flatpak
  --clean-user-cache     Удалить пустые папки в ~/.cache всех пользователей
  --keep-kernels N       Сколько ядер сохранять (по умолчанию: $KEEP_KERNELS)
  --log-file FILE        Файл лога (по умолчанию: $LOG_FILE)
  --dry-run              Показать действия без выполнения
  --debug                Включить отладочную трассировку
  --quiet                Не выводить сообщения на терминал
  --help                 Эта справка
EOF
            exit 0
            ;;
        --clean-dnf) CLEAN_DNF=true; shift ;;
        --no-clean-dnf) CLEAN_DNF=false; shift ;;
        --clean-kernels) CLEAN_KERNELS=true; shift ;;
        --no-clean-kernels) CLEAN_KERNELS=false; shift ;;
        --clean-tmp) CLEAN_TMP=true; shift ;;
        --no-clean-tmp) CLEAN_TMP=false; shift ;;
        --update-system) UPDATE_SYSTEM=true; shift ;;
        --no-update-system) UPDATE_SYSTEM=false; shift ;;
        --update-flatpak) UPDATE_FLATPAK=true; shift ;;
        --no-update-flatpak) UPDATE_FLATPAK=false; shift ;;
        --clean-flatpak) CLEAN_FLATPAK=true; shift ;;
        --no-clean-flatpak) CLEAN_FLATPAK=false; shift ;;
        --clean-user-cache) CLEAN_USER_CACHE=true; shift ;;
        --keep-kernels) KEEP_KERNELS="$2"; shift 2 ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --debug) DEBUG=true; shift ;;
        --quiet) QUIET=true; shift ;;
        *) echo "Неизвестный аргумент: $1" >&2; exit 1 ;;
    esac
done

# --- Настройка отладки ---
if $DEBUG; then
    set -x
fi

# Ловим ошибки (но не ставим set -e глобально — будем проверять вручную)
trap 'handle_error' ERR

log_message "INFO" "=== Начало процесса очистки и обновления ==="

# --- Шаг 1: Очистка DNF ---
if $CLEAN_DNF; then
    log_message "INFO" "Очистка кэша DNF..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Выполнены бы: dnf autoremove, dnf clean packages/metadata"
    else
        dnf autoremove -y
        dnf clean packages
        dnf clean metadata
    fi
fi

# --- Шаг 2: Удаление старых ядер ---
if $CLEAN_KERNELS; then
    log_message "INFO" "Поиск старых ядер для удаления (сохраняется: $KEEP_KERNELS)..."
    if $DRY_RUN; then
        # Имитируем вывод
        log_message "INFO" "(Сухой запуск) Выполнение: dnf repoquery --installonly --latest-limit=-$KEEP_KERNELS"
        old_kernels=$(dnf repoquery --installonly --latest-limit=-$KEEP_KERNELS -q 2>/dev/null || echo "kernel-old-1 kernel-old-2")
        log_message "INFO" "(Сухой запуск) Будут удалены старые ядра: $old_kernels"
    else
        old_kernels=$(dnf repoquery --installonly --latest-limit=-$KEEP_KERNELS -q 2>/dev/null)
        if [[ -n "$old_kernels" ]]; then
            log_message "INFO" "Удаление старых ядер: $old_kernels"
            dnf remove -y $old_kernels
        else
            log_message "INFO" "Нет старых ядер для удаления"
        fi
    fi
fi

# --- Шаг 3: Очистка временных файлов ---
if $CLEAN_TMP; then
    log_message "INFO" "Очистка временных файлов в /tmp и /var/tmp..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Удаление файлов старше 2 дней в /tmp и /var/tmp"
    else
        find /tmp /var/tmp -depth -mindepth 1 -mtime +2 \( -type f -o -type d -empty \) -delete 2>/dev/null || true
        journalctl --vacuum-time=5d --quiet
    fi
fi

# --- Шаг 4: Обновление системы ---
if $UPDATE_SYSTEM; then
    log_message "INFO" "Обновление системы..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Выполнено бы: dnf upgrade --refresh -y && dnf autoremove -y"
    else
        dnf upgrade --refresh -y
        dnf autoremove -y
    fi
fi

# --- Шаг 5 и 6: Flatpak ---
if command -v flatpak >/dev/null 2>&1; then
    if $UPDATE_FLATPAK; then
        log_message "INFO" "Обновление Flatpak-приложений..."
        if $DRY_RUN; then
            log_message "INFO" "(Сухой запуск) Выполнено бы: flatpak update -y"
        else
            flatpak update -y --noninteractive
        fi
    fi

    if $CLEAN_FLATPAK; then
        log_message "INFO" "Очистка неиспользуемых Flatpak-пакетов..."
        if $DRY_RUN; then
            log_message "INFO" "(Сухой запуск) Выполнено бы: flatpak uninstall --unused -y"
        else
            flatpak uninstall --unused -y --noninteractive
        fi
    fi
else
    if $UPDATE_FLATPAK || $CLEAN_FLATPAK; then
        log_message "INFO" "Flatpak не установлен — пропускаем шаги Flatpak"
    fi
fi

# --- Шаг 7: Очистка пустых папок в кэше пользователей (опционально) ---
if $CLEAN_USER_CACHE; then
    log_message "INFO" "Очистка пустых папок в ~/.cache всех пользователей..."
    if $DRY_RUN; then
        log_message "INFO" "(Сухой запуск) Поиск и удаление пустых директорий в /home/*/\.cache"
    else
        for user_home in /home/*; do
            cache_dir="$user_home/.cache"
            if [[ -d "$cache_dir" ]]; then
                find "$cache_dir" -depth -type d -empty -delete 2>/dev/null || true
            fi
        done
    fi
fi

# --- Шаг 8: Проверка ядра и пересборка initramfs ---
if $CHECK_KERNEL; then
    log_message "INFO" "Проверка обновления ядра..."
    current_kernel=$(uname -r)
    latest_kernel_pkg=$(rpm -q kernel | sort -V | tail -n1)
    if [[ -z "$latest_kernel_pkg" ]]; then
        log_message "WARNING" "Не найдено установленных пакетов kernel"
    else
        latest_kernel_ver=${latest_kernel_pkg#kernel-}
        if [[ "$current_kernel" == "$latest_kernel_ver" ]]; then
            log_message "INFO" "Ядро не обновлялось. Пересборка не требуется."
        else
            log_message "INFO" "Обнаружено новое ядро: $current_kernel → $latest_kernel_ver"
            if $DRY_RUN; then
                log_message "INFO" "(Сухой запуск) Выполнено бы: akmods --force && dracut --force --kver $latest_kernel_ver"
            else
                if command -v akmods >/dev/null; then
                    akmods --force
                fi
                dracut --force --kver "$latest_kernel_ver"
            fi
        fi
    fi
fi

log_message "INFO" "Рекомендуется выполнить перезагрузку системы"

# --- Уведомление ---
notify_msg="Все операции успешно завершены!\nРекомендуется выполнить перезагрузку системы."
if $DRY_RUN; then
    log_message "INFO" "(Сухой запуск) Уведомление не отправлено"
else
    if command -v kdialog &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        kdialog --title "Скрипт завершён" --msgbox "$notify_msg"
    elif command -v notify-send &>/dev/null; then
        notify-send "Скрипт завершён" "$notify_msg"
    else
        log_message "WARNING" "Уведомление не отправлено: нет kdialog или notify-send"
    fi
fi

log_message "INFO" "=== Завершение ==="
exit 0
