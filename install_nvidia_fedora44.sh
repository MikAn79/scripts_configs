#!/usr/bin/env bash

set -euo pipefail

# Fedora 44 + RPM Fusion NVIDIA installer for GeForce GTX 1080 Ti.
#
# This card is Pascal, so the script pins the RPM Fusion 580xx driver branch.
#
# Useful toggles:
#   INSTALL_32BIT_LIBS=0      Skip i686 OpenGL/Vulkan libraries for Steam/Wine.
#   SETUP_SECURE_BOOT=0       Do not prepare akmods Secure Boot signing key.
#   AUTO_REBOOT=1             Reboot without asking after successful install.

FEDORA_VERSION="44"
INSTALL_32BIT_LIBS="${INSTALL_32BIT_LIBS:-1}"
SETUP_SECURE_BOOT="${SETUP_SECURE_BOOT:-ask}"
AUTO_REBOOT="${AUTO_REBOOT:-ask}"

die() {
    echo "Ошибка: $*" >&2
    exit 1
}

run() {
    echo
    echo "==> $*"
    "$@"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local reply
    local suffix="[y/N]"

    if [[ "$default" == "y" ]]; then
        suffix="[Y/n]"
    fi

    read -r -p "$prompt $suffix " reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

require_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        die "запусти скрипт через sudo."
    fi
}

require_fedora_44() {
    local current

    [[ -r /etc/fedora-release ]] || die "это не похоже на Fedora."

    current="$(rpm -E %fedora)"
    [[ "$current" == "$FEDORA_VERSION" ]] || die "ожидалась Fedora $FEDORA_VERSION, сейчас rpm сообщает Fedora $current."
}

enable_rpmfusion() {
    run dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

    run dnf upgrade --refresh -y
}

install_prerequisites() {
    run dnf install -y \
        akmods \
        gcc \
        kernel-devel \
        kernel-headers \
        kmodtool \
        mokutil \
        openssl
}

install_nvidia_1080ti_driver() {
    local packages=(
        akmod-nvidia-580xx
        xorg-x11-drv-nvidia-580xx
        xorg-x11-drv-nvidia-580xx-cuda
    )

    if [[ "$INSTALL_32BIT_LIBS" == "1" ]]; then
        packages+=(xorg-x11-drv-nvidia-580xx-libs.i686)
    fi

    echo
    echo "Будут установлены пакеты NVIDIA для GTX 1080 Ti:"
    printf '  %s\n' "${packages[@]}"

    run dnf install -y "${packages[@]}"
}

secure_boot_enabled() {
    mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'
}

setup_secure_boot_signing() {
    if [[ "$SETUP_SECURE_BOOT" == "0" ]]; then
        echo
        echo "Secure Boot: настройка подписи пропущена по SETUP_SECURE_BOOT=0."
        return
    fi

    if ! secure_boot_enabled; then
        echo
        echo "Secure Boot выключен или недоступен, подпись akmods не требуется."
        return
    fi

    if [[ "$SETUP_SECURE_BOOT" == "ask" ]] && ! ask_yes_no "Secure Boot включен. Создать и импортировать ключ для подписи NVIDIA akmods?" "y"; then
        echo "Пропускаю настройку Secure Boot. Модуль NVIDIA может не загрузиться после перезагрузки."
        return
    fi

    if [[ ! -f /etc/pki/akmods/certs/public_key.der ]]; then
        run kmodgenca -a
    else
        echo
        echo "Ключ akmods уже существует: /etc/pki/akmods/certs/public_key.der"
    fi

    echo
    echo "Сейчас будет импорт ключа MOK. Задай временный пароль и введи его при следующей загрузке в синем меню MOK Manager."
    run mokutil --import /etc/pki/akmods/certs/public_key.der
}

rebuild_modules() {
    run akmods --force
    run dracut --force

    run systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
}

final_message() {
    cat <<'EOF'

Установка завершена.

После перезагрузки проверь:
  nvidia-smi
  modinfo -F version nvidia

Если Secure Boot включен, при первой перезагрузке подтверди ключ в MOK Manager.
EOF
}

main() {
    require_root
    require_fedora_44
    enable_rpmfusion
    install_prerequisites
    setup_secure_boot_signing
    install_nvidia_1080ti_driver
    rebuild_modules
    final_message

    case "$AUTO_REBOOT" in
        1|yes|y)
            run reboot
            ;;
        ask)
            if ask_yes_no "Перезагрузить сейчас?" "n"; then
                run reboot
            fi
            ;;
        *)
            echo "Автоперезагрузка отключена."
            ;;
    esac
}

main "$@"
