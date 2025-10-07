#!/bin/bash

# Скрипт настройки сети и проверки QEMU/KVM
set -e

echo "=== Настройка сети и проверка QEMU/KVM ==="

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт требует прав root. Запустите с sudo:"
    echo "sudo $0"
    exit 1
fi

# Функция для создания сетевого моста
create_bridge() {
    local BRIDGE_NAME=${1:-virbr0}
    local BRIDGE_IP=${2:-192.168.122.1}
    local NETMASK=${3:-255.255.255.0}
    local DHCP_START=${4:-192.168.122.2}
    local DHCP_END=${5:-192.168.122.254}
    
    echo "Создание сетевого моста: $BRIDGE_NAME"
    
    # Проверяем, существует ли уже мост
    if ip link show $BRIDGE_NAME >/dev/null 2>&1; then
        echo "Мост $BRIDGE_NAME уже существует"
        return 0
    fi
    
    # Создаем XML конфигурацию для моста
    cat > /tmp/bridge-network.xml << EOF
<network>
  <name>$BRIDGE_NAME</name>
  <forward mode="nat"/>
  <bridge name="$BRIDGE_NAME" stp="on" delay="0"/>
  <ip address="$BRIDGE_IP" netmask="$NETMASK">
    <dhcp>
      <range start="$DHCP_START" end="$DHCP_END"/>
    </dhcp>
  </ip>
</network>
EOF

    # Определяем и запускаем сеть
    virsh net-define /tmp/bridge-network.xml
    virsh net-autostart $BRIDGE_NAME
    virsh net-start $BRIDGE_NAME
    
    echo "Мост $BRIDGE_NAME создан и запущен"
}

# Функция проверки файервола
check_firewall() {
    echo "=== Проверка правил файервола ==="
    
    # Проверяем основные сервисы
    local SERVICES=("libvirt" "libvirt-tls" "mdns" "dhcp" "dns")
    
    for service in "${SERVICES[@]}"; do
        if firewall-cmd --query-service=$service >/dev/null 2>&1; then
            echo "✓ Сервис $service разрешен в файрволе"
        else
            echo "✗ Сервис $service не разрешен в файрволе"
            echo "Добавление сервиса $service..."
            firewall-cmd --permanent --add-service=$service
        fi
    done
    
    # Перезагружаем файервол
    firewall-cmd --reload
    echo "Правила файервола применены"
}

# Функция проверки сетевых настроек
check_network_settings() {
    echo "=== Проверка сетевых настроек ==="
    
    # Список сетей
    echo "Доступные сети:"
    virsh net-list --all
    
    # Информация о сетевых интерфейсах
    echo -e "\nСетевые интерфейсы:"
    ip link show
    
    # Проверка мостов
    echo -e "\nСетевые мосты:"
    brctl show 2>/dev/null || echo "brctl не установлен, используем ip:"
    ip link show type bridge
}

# Функция проверки состояния libvirt
check_libvirt_status() {
    echo "=== Проверка состояния libvirt ==="
    
    systemctl status libvirtd --no-pager -l
    echo -e "\nАктивные сети:"
    virsh net-list
}

# Основная логика скрипта
main() {
    # Создаем сетевой мост
    create_bridge "virbr0" "192.168.122.1" "255.255.255.0" "192.168.122.2" "192.168.122.254"
    
    # Проверяем файервол
    check_firewall
    
    # Проверяем сетевые настройки
    check_network_settings
    
    # Проверяем состояние libvirt
    check_libvirt_status
    
    echo -e "\n=== Настройка завершена ==="
    echo "Сетевой мост создан: virbr0 (192.168.122.1/24)"
    echo "DHCP диапазон: 192.168.122.2 - 192.168.122.254"
    echo "Правила файервола настроены"
}

# Запуск основной функции
main "$@"