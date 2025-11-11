#!/bin/bash
# ============================================================================
#  Fedora Workstation "Things To Do!" Setup Script
#  Interactive Edition — v2.5 (2025-10)
# ============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Ensure run as root ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# --- Variables ---
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/fedora_things_to_do.log"
trap 'handle_error "Unexpected error on line $LINENO"' ERR

# --- Functions ---
get_timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

log_message() {
    local msg="$1"
    echo "$(get_timestamp) - $msg" | tee -a "$LOG_FILE"
}

handle_error() {
    local msg="$1"
    log_message "ERROR: $msg"
    exit 1
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        log_message "Backed up $file"
    fi
}

install_app() {
    local name="$1"
    shift
    log_message "Installing $name..."
    "$@" >> "$LOG_FILE" 2>&1
    log_message "$name installed successfully."
}

prompt_reboot() {
    sudo -u "$ACTUAL_USER" bash -c 'read -p "Reboot now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        log_message "Rebooting..."
        reboot
    else
        log_message "Reboot canceled."
    fi
}

# ============================================================================
# PACKAGE LISTS
# ============================================================================
ESSENTIAL_APPS=(
  mc btop htop rsync inxi fastfetch unzip unrar git wget curl syncthing qbittorrent
  dnf-plugins-core dnf-automatic papirus-icon-theme openssh-server gcc kernel-headers kernel-devel langpacks-ru man-pages-ru libreoffice-langpack-ru glibc-langpack-ru dkms

)

FLATPAK_APPS=(
  "md.obsidian.Obsidian"
  "org.videolan.VLC"
  "com.rustdesk.RustDesk"
  "com.anydesk.Anydesk"
  "io.missioncenter.MissionCenter"
  "org.telegram.desktop"
)

FONT_PACKS=("Microsoft Fonts" "Google Fonts" "Adobe Fonts")

# ============================================================================
# INTERACTIVE PREVIEW
# ============================================================================
clear
echo ""
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                  Fedora Post-Install Setup — Interactive v2.5               ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will install the following software:"
echo ""

echo "📦 DNF packages:"
printf '  - %s\n' "${ESSENTIAL_APPS[@]}"
echo ""
echo "🧩 Flatpak applications:"
printf '  - %s\n' "${FLATPAK_APPS[@]}"
echo ""
echo "🔠 Fonts:"
printf '  - %s\n' "${FONT_PACKS[@]}"
echo ""

read -p "Would you like to modify these lists before installation? (y/n): " edit_choice
if [[ "$edit_choice" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Editing mode — you can remove or add items."
    echo "Type names separated by spaces. Leave blank to keep defaults."
    echo ""

    read -p "DNF packages (current: ${ESSENTIAL_APPS[*]}): " new_dnf
    [ -n "$new_dnf" ] && read -a ESSENTIAL_APPS <<< "$new_dnf"

    read -p "Flatpak apps (current: ${FLATPAK_APPS[*]}): " new_flatpak
    [ -n "$new_flatpak" ] && read -a FLATPAK_APPS <<< "$new_flatpak"

    read -p "Fonts (current: ${FONT_PACKS[*]}): " new_fonts
    [ -n "$new_fonts" ] && read -a FONT_PACKS <<< "$new_fonts"

    echo ""
    echo "✅ Updated configuration:"
    echo "  DNF: ${ESSENTIAL_APPS[*]}"
    echo "  Flatpak: ${FLATPAK_APPS[*]}"
    echo "  Fonts: ${FONT_PACKS[*]}"
    echo ""
    read -p "Proceed with installation? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
else
    echo ""
    read -p "Proceed with installation as listed? (y/n): " proceed
    [[ "$proceed" =~ ^[Yy]$ ]] || exit 0
fi
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
# ============================================================================
# SYSTEM SETUP
# ============================================================================
log_message "===== STARTING FEDORA SETUP ====="
dnf upgrade -y

# ============================================================================
# REPOSITORY CONFIGURATION
# ============================================================================
log_message "Checking and enabling RPM Fusion repositories..."

FREE_REPO="/etc/yum.repos.d/rpmfusion-free.repo"
NONFREE_REPO="/etc/yum.repos.d/rpmfusion-nonfree.repo"

if [ ! -f "$FREE_REPO" ] || [ ! -f "$NONFREE_REPO" ]; then
    log_message "RPM Fusion repositories not detected. Enabling..."
    dnf install -y \
      "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    log_message "RPM Fusion repositories successfully enabled."
else
    log_message "RPM Fusion repositories are already enabled."
fi

# DNF optimization and auto updates
backup_file "/etc/dnf/dnf.conf"
grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf || echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf

dnf install -y --refresh dnf-plugins-core
dnf install -y dnf-automatic
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer

# ============================================================================
# MULTIMEDIA CODECS (RPM Fusion)
# ============================================================================
log_message "Configuring multimedia codecs from RPM Fusion..."

# Disable Cisco openh264 repo and remove limited codecs
if [ -f /etc/yum.repos.d/fedora-cisco-openh264.repo ]; then
    log_message "Disabling Cisco openh264 repository..."
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-openh264.repo
fi

log_message "Removing OpenH264 packages..."
dnf remove -y openh264 mozilla-openh264 gstreamer1-plugin-openh264 || true
flatpak mask org.freedesktop.Platform.openh264 || true
dnf swap *\openh264\* noopenh264  --allowerasing

# Replace ffmpeg-free with full ffmpeg version
log_message "Swapping ffmpeg-free with full ffmpeg..."
dnf swap -y ffmpeg-free ffmpeg --allowerasing

# Install and update multimedia groups
log_message "Installing multimedia and sound/video codec groups..."
dnf groupupdate -y core
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf update -y @sound-and-video

log_message "Multimedia codec setup complete."

# ============================================================================
# INSTALL DNF & FLATPAK PACKAGES
# ============================================================================
log_message "Installing DNF packages..."
dnf install -y "${ESSENTIAL_APPS[@]}"

command -v flatpak >/dev/null 2>&1 || dnf install -y flatpak
for app in "${FLATPAK_APPS[@]}"; do
    install_app "$app" flatpak install -y flathub "$app"
done

# ============================================================================
# FONTS
# ============================================================================
for font in "${FONT_PACKS[@]}"; do
    case "$font" in
        "Microsoft Fonts")
            install_app "Microsoft Fonts" bash -c "dnf install -y curl cabextract xorg-x11-font-utils fontconfig && \
                rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm"
            ;;
        "Google Fonts")
            install_app "Google Fonts" bash -c "
                mkdir -p $ACTUAL_HOME/.local/share/fonts/google && \
                curl -L -o /tmp/google-fonts.zip https://github.com/google/fonts/archive/main.zip && \
                unzip /tmp/google-fonts.zip -d $ACTUAL_HOME/.local/share/fonts/google && \
                rm -f /tmp/google-fonts.zip"
            ;;
        "Adobe Fonts")
            install_app "Adobe Fonts" bash -c "
                mkdir -p $ACTUAL_HOME/.local/share/fonts/adobe-fonts && \
                git clone --depth 1 https://github.com/adobe-fonts/source-sans.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-sans && \
                git clone --depth 1 https://github.com/adobe-fonts/source-serif.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-serif && \
                git clone --depth 1 https://github.com/adobe-fonts/source-code-pro.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-code-pro"
            ;;
    esac
done

fc-cache -fv

# ============================================================================
# VIRTUALIZATION SETUP
# ============================================================================
echo ""
echo "💻 Virtualization setup:"
echo "  1) QEMU / KVM"
echo "  2) VirtualBox (RPM Fusion)"
echo "  3) Skip virtualization setup"
read -p "Choose option [1-3]: " virt_choice

case "$virt_choice" in
  1)
    log_message "Installing QEMU/KVM virtualization stack..."
    CPU_VENDOR=$(lscpu | grep -E 'Vendor ID:' | awk '{print $3}')
    MODULES="kvm-intel"
    [[ "$CPU_VENDOR" == "AuthenticAMD" ]] && MODULES="kvm-amd"
    dnf install -y @virtualization virt-manager virt-viewer bridge-utils libvirt libvirt-daemon-config-network libvirt-daemon-kvm qemu-kvm
    systemctl enable --now libvirtd
    modprobe "$MODULES"
    usermod -aG libvirt "$ACTUAL_USER"
    log_message "QEMU/KVM installed and configured."
    ;;
  2)
    log_message "Installing VirtualBox (via RPM Fusion)..."
    dnf install -y VirtualBox
    systemctl enable --now vboxdrv.service
    usermod -aG vboxusers "$ACTUAL_USER"
    log_message "VirtualBox installed successfully."
    ;;
  *)
    log_message "Virtualization setup skipped by user."
    ;;
esac

# ============================================================================
# DOCKER SETUP
# ============================================================================
echo ""
echo "🐳 Docker setup:"
echo "  1) Install Docker & Docker Compose"
echo "  2) Skip Docker installation"
read -p "Choose option [1-2]: " docker_choice

if [[ "$docker_choice" == "1" ]]; then
    log_message "Installing Docker Engine & Docker Compose..."

    dnf remove -y docker docker-client docker-common docker-engine || true
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable --now docker
    usermod -aG docker "$ACTUAL_USER"

    log_message "Docker & Docker Compose installed successfully."
else
    log_message "Docker installation skipped by user."
fi

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================
log_message "Configuring system firewall (firewalld)..."

if ! rpm -q firewalld >/dev/null 2>&1; then
    dnf install -y firewalld
    log_message "firewalld installed."
fi

systemctl enable --now firewalld
log_message "firewalld service started and enabled at boot."

log_message "Applying basic firewall rules..."
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=samba

if firewall-cmd --get-zones | grep -q "docker"; then
    log_message "Docker zone already exists in firewalld."
else
    firewall-cmd --permanent --new-zone=docker
    firewall-cmd --permanent --zone=docker --add-interface=docker0 || true
    firewall-cmd --permanent --zone=docker --add-masquerade
    firewall-cmd --permanent --zone=docker --add-port=2375/tcp
    firewall-cmd --permanent --zone=docker --add-port=2376/tcp
    log_message "Docker zone configured in firewalld."
fi

firewall-cmd --reload
log_message "firewalld configuration completed successfully."

# ============================================================================
# CLEANUP & FINISH
# ============================================================================
log_message "Cleaning up temporary files..."
rm -rf /tmp/google-fonts.zip /tmp/fonts-main || true

log_message "All installations complete!"
echo ""
echo "🎉 Fedora setup complete!"
prompt_reboot
