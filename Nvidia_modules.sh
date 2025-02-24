#!/bin/bash
# do this as root
sudo su -

# fyi, version sort installed kernels
rpm -qa kernel | sed -e 's/^kernel-//g' | sort -uV

# fyi, version sort installed dkms module/module-version and kernel/arch
dkms status | sort -uV

export CURRENT_KERNEL="$(uname -r)"; echo "CURRENT_KERNEL=${CURRENT_KERNEL}"
export LATEST_KERNEL="$(rpm -qa kernel | sed -e 's/^kernel-//g' | sort -uV | tail -1)"; echo LATEST_KERNEL=${LATEST_KERNEL} # this matches uname -r

# example rebuild; pick one
export KERNEL_UNAME="6.12.11-200.fc41.x86_64"
export KERNEL_UNAME=${CURRENT_KERNEL}
export KERNEL_UNAME=${LATEST_KERNEL}
echo KERNEL_UNAME=${KERNEL_UNAME}

# set proper values for dkms build, install, etc
export DKMS_ARCH="$(dkms status | grep ${KERNEL_UNAME}, | awk -F, '{print $3}' | awk '{print $1}' | awk -F: '{print $1}')"
export DKMS_KERNEL="$(dkms status | grep ${KERNEL_UNAME}, | awk -F, '{print $2}' | awk '{print $1}')" # should be the same as KERNEL_UNAME
export DKMS_MODULE_VERSION="$(dkms status | grep ${KERNEL_UNAME}, | awk -F, '{print $1}' | awk '{print $1}')"

# manually verify values
echo DKMS_ARCH=${DKMS_ARCH}
echo DKMS_KERNEL=${DKMS_KERNEL}
echo DKMS_MODULE_VERSION=${DKMS_MODULE_VERSION}

# NOTICE! Using the LATEST_KERNEL value is easiest/safest.
# NOTICE! If you're booted with the latest kernel and the modules ARE NOT loaded, then properly rebuilding may immediately load the correct signed module and will likely reset a graphical session.
# IMPORTANT! If you're booted from the kernel you want to 'fix' then do this in a tmux, screen, or from the linux console.
KERNEL_UNAME=${DKMS_KERNEL} dkms uninstall ${DKMS_MODULE_VERSION} -k ${DKMS_KERNEL}/${DKMS_ARCH}
KERNEL_UNAME=${DKMS_KERNEL} dkms build ${DKMS_MODULE_VERSION} -k ${DKMS_KERNEL}/${DKMS_ARCH} --force
KERNEL_UNAME=${DKMS_KERNEL} dkms install ${DKMS_MODULE_VERSION} -k ${DKMS_KERNEL}/${DKMS_ARCH}
KERNEL_UNAME=${DKMS_KERNEL} dkms status ${DKMS_MODULE_VERSION} -k ${DKMS_KERNEL}/${DKMS_ARCH}

# verify the build make.log enters the correct /usr/
less /var/lib/dkms/nvidia-open/*/${DKMS_KERNEL}/${DKMS_ARCH}/log/make.log

systemctl reboot
