#!/bin/bash

source "$(dirname "$0")/helper.sh"

cecho "GREEN" "START - kernel upgrade"

cecho "CYAN" "START - Install packages"
sudo emerge --ask --verbose --update --deep --newuse --verbose-conflicts sys-kernel/gentoo-sources sys-kernel/linux-headers
cecho "CYAN" "END - Install packages"

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
cecho "CYAN" "END - choose kernel, press enter"
read -p "$*"

cecho "CYAN" "START - configure kernel"
cecho "YELLOW" "move to source, this is the content of /usr/src/linux:"
cd "/usr/src/linux"
ls -la
cecho "YELLOW" "1.press enter to continue"
read -p "$*"
cecho "YELLOW" "backup config, this is the config content:"
zcat "/proc/config.gz" > "/usr/src/linux/.config"
less "/usr/src/linux/.config"
cecho "YELLOW" "2.press enter to continue"
read -p "$*"
cecho "YELLOW" "list new config"
make listnewconfig
cecho "YELLOW" "3.press enter to continue"
read -p "$*"
cecho "YELLOW" "set defaults config from old"
make olddefconfig
cecho "YELLOW" "4.press enter to continue"
read -p "$*"
cecho "YELLOW" "show removed options"
diff <(sort .config) <(sort .config.old) | awk '/^>.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "5.press enter to continue"
read -p "$*"
cecho "YELLOW" "show diff options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "6.press enter to continue"
read -p "$*"
cecho "YELLOW" "configure manually"
make menuconfig
cecho "YELLOW" "7.press enter to continue"
read -p "$*"
cecho "YELLOW" "show again options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "8.press enter to continue"
read -p "$*"
cecho "CYAN" "END - configure kernel, press enter"
read -p "$*"

cecho "CYAN" "START - build kernel"

cecho "YELLOW" "build modules"
make modules_prepare
cecho "YELLOW" "9.press enter to continue"
read -p "$*"

cecho "YELLOW" "build kernel"
make -j6
cecho "YELLOW" "10.press enter to continue"
read -p "$*"

cecho "YELLOW" "rebuild modules"
emerge --ask @module-rebuild
cecho "YELLOW" "11.press enter to continue"
read -p "$*"

cecho "CYAN" "END - build kernel, press enter"
read -p "$*"

cecho "CYAN" "START - install kernel"
cecho "YELLOW" "install modules"
make modules_install
cecho "YELLOW" "12.press enter to continue"
read -p "$*"

cecho "YELLOW" "install kernel"
make install
cecho "YELLOW" "13.press enter to continue"
read -p "$*"

cecho "CYAN" "END - install kernel, press enter"
read -p "$*"

cecho "CYAN" "START update initramfs with Dracut"
dracut --kver="$newKernelVersion-gentoo-x86_64"
cecho "CYAN" "END update initramfs with Dracut, press enter "
read -p "$*"

cecho "CYAN" "START - update bootloader"
grub-mkconfig -o "/boot/grub/grub.cfg"
cecho "CYAN" "END - update bootloader, press enter"
read -p "$*"

cecho "CYAN" "START - clean kernel"

cecho "YELLOW" "save new kernel source $newKernelVersion"
emerge --noreplace "sys-kernel/gentoo-sources:$newKernelVersion"
cecho "YELLOW" "14.press enter to continue"
read -p "$*"

cecho "YELLOW" "remove old kernel source $deprecatedVersion"
emerge --deselect "sys-kernel/gentoo-sources:$deprecatedVersion"
cecho "YELLOW" "15.press enter to continue"
read -p "$*"

cecho "YELLOW" "cleanup packages"
emerge --ask --depclean
cecho "YELLOW" "16.press enter to continue"
read -p "$*"

cecho "YELLOW" "remove old kernels"
eclean-kernel -n 3
cecho "YELLOW" "17.press enter to continue"
read -p "$*"

cecho "CYAN" "END - clean kernel, press enter"

cecho "GREEN" "END - kernel upgrade, press enter close"
read -p "$*"
