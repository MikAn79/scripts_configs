# first add rpm-fusion

# https://docs.fedoraproject.org/en-US/quick-docs/rpmfusion-setup/

sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# https://rpmfusion.org/Howto/NVIDIA

sudo dnf update -y

sudo dnf install htop -y

sudo dnf install kernel-headers kernel-devel dkms

sudo dnf install akmod-nvidia

# cuda driver below breaks nvidia on fedora 41. lets not use it for now

# sudo dnf install xorg-x11-drv-nvidia-cuda

# I start htop to monitor cpu usage. after you install driver, it needs to do some "magic" in the background. wait until cpu usage goes back down to idle

htop
