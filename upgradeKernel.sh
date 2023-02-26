#!/bin/bash

source "$(dirname "$0")/helper.sh"

cecho "GREEN" "START - kernel upgrade"

cecho "CYAN" "START - choose kernel"
oldKernelPath=$(eselect kernel show | sed -n '2 p' | tr -d ' ')
echo "Current kernel path: $oldKernelPath"
oldKernelName=$(echo $oldKernelPath | awk -F/ '{print $NF}')
echo "Current kernel name: $oldKernelName"
oldKernelVersion=$(cut -d "-" -f2 <<< "$oldKernelName")
echo "Current kernel version: $oldKernelVersion"
eselect kernel list
read choice
eselect kernel set $choice
newKernelPath=$(eselect kernel show | sed -n '2 p' | tr -d ' ')
echo "New kernel path: $newKernelPath"
newKernelName=$(echo $newKernelPath | awk -F/ '{print $NF}')
echo "New kernel name: $newKernelName"
newKernelVersion=$(cut -d "-" -f2 <<< "$newKernelName")
echo "New kernel version: $newKernelVersion"

deprecatedVersion=$(grep -F 'sys-kernel/gentoo-sources:' /var/lib/portage/world | grep -F -v "$oldKernelVersion" | cut -d ":" -f2)
echo "Old kernel version: $deprecatedVersion"

cecho "CYAN" "END - choose kernel"
read -p "$*"

cecho "CYAN" "START - configure kernel"
cecho "YELLOW" "move to source"
cd "/usr/src/linux"
read -p "$*"
cecho "YELLOW" "backup config"
zcat /proc/config.gz > /usr/src/linux/.config
read -p "$*"
cecho "YELLOW" "list new config"
make listnewconfig
read -p "$*"
cecho "YELLOW" "set defaults config from old"
make olddefconfig
read -p "$*"
cecho "YELLOW" "show removed options"
diff <(sort .config) <(sort .config.old) | awk '/^>.*(=|Linux)/ { $1=""; print }'
read -p "$*"
cecho "YELLOW" "show diff options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
read -p "$*"
cecho "YELLOW" "configure manually"
make menuconfig
read -p "$*"
cecho "YELLOW" "show again options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
read -p "$*"
cecho "CYAN" "END - configure kernel"
read -p "$*"

cecho "CYAN" "START - build kernel"
cecho "YELLOW" "build modules"
make modules_prepare
read -p "$*"

cecho "YELLOW" "build kernel"
make -j6
read -p "$*"

cecho "CYAN" "END - build kernel"
read -p "$*"

cecho "CYAN" "START - install kernel"
cecho "YELLOW" "install modules"
make modules_install
read -p "$*"

cecho "YELLOW" "install kernel"
make install
read -p "$*"

cecho "CYAN" "END - install kernel"
read -p "$*"

cecho "CYAN" "START - update bootloader"
grub-mkconfig -o "/boot/grub/grub.cfg"
cecho "CYAN" "END - update bootloader"
read -p "$*"

cecho "CYAN" "START - clean kernel"

cecho "YELLOW" "save new kernel $newKernelVersion"
emerge --noreplace "sys-kernel/gentoo-sources:$newKernelVersion"
read -p "$*"

cecho "YELLOW" "remove old kernel $deprecatedVersion"
emerge --deselect "sys-kernel/gentoo-sources:$deprecatedVersion"
read -p "$*"

cecho "YELLOW" "cleanup packages"
emerge --ask --depclean

cecho "CYAN" "END - clean kernel"

cecho "GREEN" "END - kernel upgrade, press enter close"
read -p "$*"
