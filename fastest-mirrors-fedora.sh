#!/bin/bash

set -e

REPO_DIR="/etc/yum.repos.d"
FEDORA_REPOS="fedora fedora-updates fedora-updates-testing"
RPMFUSION_REPOS="rpmfusion-free rpmfusion-free-updates rpmfusion-free-updates-testing rpmfusion-nonfree rpmfusion-nonfree-updates rpmfusion-nonfree-updates-testing"

# Получить список .repo файлов только Fedora и RPM Fusion
get_repo_files() {
    ls "$REPO_DIR" | grep -E '^(fedora|rpmfusion-).+\.repo$'
}

# Меню
show_menu() {
    echo "Выберите действие:"
    echo "1) Установить зеркала Fedora от Яндекс"
    echo "2) Ввести зеркало Fedora вручную"
    echo "3) Установить зеркала RPM Fusion от Яндекс"
    echo "4) Ввести зеркало RPM Fusion вручную"
    echo "5) Автовыбор самого быстрого зеркала Fedora"
    echo "6) Восстановить metalink (по умолчанию)"
    echo "0) Выход"
    echo
}

# Подменить baseurl
replace_urls() {
    local repos="$1"
    local baseurl="$2"
    for repo in $repos; do
        local file="$REPO_DIR/$repo.repo"
        if [ -f "$file" ]; then
            cp "$file" "$file.bak"

            sed -i \
                -e 's|^metalink=.*|#&|' \
                -e 's|^#baseurl=.*|baseurl='"$baseurl"'|' \
                -e 's|^baseurl=.*|baseurl='"$baseurl"'|' \
                "$file"

            echo "✅ Обновлено зеркало в $file"
        fi
    done
}

# Восстановить metalink
restore_metalink() {
    for file in $(get_repo_files); do
        file="$REPO_DIR/$file"
        cp "$file" "$file.bak"

        sed -i \
            -e 's|^#metalink=|metalink=|' \
            -e 's|^baseurl=|#baseurl=|' \
            "$file"
        echo "🔄 Восстановлено: $file"
    done
}

# Найти самое быстрое зеркало Fedora
detect_fastest_url() {
    echo "🔍 Поиск самого быстрого зеркала Fedora..."
    temp_file=$(mktemp)

    curl -s "https://mirrors.fedoraproject.org/metalink?repo=fedora-$(rpm -E %fedora)&arch=$(uname -m)" |
        grep -oP '(?<=<url protocol="http">).*?(?=</url>)' > "$temp_file"

    echo "⏳ Замер скорости зеркал..."

    fastest_url=""
    fastest_time=999999

    while read -r url; do
        test_url="$url/repodata/repomd.xml"
        start=$(date +%s%3N)
        curl -s --max-time 2 --output /dev/null "$test_url"
        end=$(date +%s%3N)
        elapsed=$((end - start))
        echo "$elapsed ms → $url"

        if [ "$elapsed" -lt "$fastest_time" ]; then
            fastest_time=$elapsed
            fastest_url=$url
        fi
    done < "$temp_file"

    rm -f "$temp_file"

    if [ -n "$fastest_url" ]; then
        echo "✅ Самое быстрое зеркало: $fastest_url"
        replace_urls "$FEDORA_REPOS" "$fastest_url"
    else
        echo "❌ Не удалось определить зеркало"
    fi
}

# Основной цикл
main() {
    while true; do
        show_menu
        read -rp "Выберите номер: " choice
        echo

        case "$choice" in
            1)
                replace_urls "$FEDORA_REPOS" "http://mirror.yandex.ru/fedora/linux/releases/\$releasever/Everything/\$basearch/os/"
                replace_urls "fedora-updates" "http://mirror.yandex.ru/fedora/linux/updates/\$releasever/Everything/\$basearch/"
                ;;
            2)
                read -rp "Введите URL зеркала для Fedora: " url
                replace_urls "$FEDORA_REPOS" "$url"
                ;;
            3)
                replace_urls "rpmfusion-free" "http://mirror.yandex.ru/fedora/rpmfusion/free/fedora/releases/\$releasever/Everything/\$basearch/os/"
                replace_urls "rpmfusion-free-updates" "http://mirror.yandex.ru/fedora/rpmfusion/free/fedora/updates/\$releasever/\$basearch/"
                replace_urls "rpmfusion-nonfree" "http://mirror.yandex.ru/fedora/rpmfusion/nonfree/fedora/releases/\$releasever/Everything/\$basearch/os/"
                replace_urls "rpmfusion-nonfree-updates" "http://mirror.yandex.ru/fedora/rpmfusion/nonfree/fedora/updates/\$releasever/\$basearch/"
                ;;
            4)
                read -rp "Введите URL зеркала для RPM Fusion: " url
                replace_urls "$RPMFUSION_REPOS" "$url"
                ;;
            5)
                detect_fastest_url
                ;;
            6)
                restore_metalink
                ;;
            0)
                echo "Выход."
                exit 0
                ;;
            *)
                echo "❌ Неверный выбор"
                ;;
        esac

        echo
    done
}

main
