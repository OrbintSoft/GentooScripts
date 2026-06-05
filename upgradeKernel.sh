#!/bin/bash

source "$(dirname "$0")/helper.sh"

# Derive the kernel name variants from a source-dir basename (e.g. linux-6.18.33-gentoo-r1):
#   kernelKver       -> 6.18.33-gentoo-r1-x86_64   (for dracut and /lib/modules)
#   kernelPkgVersion -> 6.18.33-r1                 (for emerge atoms / world file)
kernelKver() {
    local src="${1#linux-}"          # 6.18.33-gentoo-r1
    printf '%s' "${src}-x86_64"
}
kernelPkgVersion() {
    local src="${1#linux-}"          # 6.18.33-gentoo-r1
    printf '%s' "${src/-gentoo/}"    # 6.18.33-r1
}

cecho "GREEN" "START - kernel upgrade"

cecho "CYAN" "START - Install packages"
emerge --ask --verbose --update --deep --newuse --verbose-conflicts sys-kernel/gentoo-sources sys-kernel/linux-headers
cecho "CYAN" "END - Install packages"

cecho "CYAN" "START - choose kernel"
# "current" = the actually running kernel (uname -r), NOT the eselect symlink:
# the symlink may already point to an incomplete/failed upgrade.
currentKver=$(uname -r)                                          # 6.18.26-gentoo-x86_64
currentKernelName="linux-${currentKver%-x86_64}"                 # linux-6.18.26-gentoo
currentKernelVersion=$(kernelPkgVersion "$currentKernelName")    # 6.18.26
cecho "GREEN" "Current (running) kernel: $currentKernelName  (pkg $currentKernelVersion, kver $currentKver)"
eselect kernel list
read -r choice
if ! eselect kernel set "$choice"; then
    cecho "RED" "ERROR: 'eselect kernel set $choice' failed (invalid choice). Aborting."
    exit 1
fi
newKernelPath=$(eselect kernel show | sed -n '2 p' | tr -d ' ')   # /usr/src/linux-6.18.33-gentoo-r1
newKernelName=$(basename "$newKernelPath")                        # linux-6.18.33-gentoo-r1
newKernelVersion=$(kernelPkgVersion "$newKernelName")             # 6.18.33-r1
newKver=$(kernelKver "$newKernelName")                            # 6.18.33-gentoo-r1-x86_64
# the new kernel must have its source tree present, otherwise there is nothing to build
if [ ! -d "$newKernelPath" ]; then
    cecho "RED" "ERROR: new kernel source not available: $newKernelPath. Aborting."
    exit 1
fi
# an upgrade must move forward: new must be strictly greater than current
if [ "$newKernelVersion" = "$currentKernelVersion" ] || \
   [ "$(printf '%s\n%s\n' "$currentKernelVersion" "$newKernelVersion" | sort -V | tail -n1)" != "$newKernelVersion" ]; then
    cecho "RED" "ERROR: '$newKernelVersion' is not an upgrade over current '$currentKernelVersion' (must be > current). Aborting."
    exit 1
fi
cecho "GREEN" "New (target) kernel:  $newKernelName  (pkg $newKernelVersion, kver $newKver)"
# "old" = every INSTALLED gentoo-sources other than current and new
# (there may be more than one if a previous cleanup was skipped)
mapfile -t installedVersions < <(
    for d in /var/db/pkg/sys-kernel/gentoo-sources-*; do
        [ -d "$d" ] && basename "$d" | sed 's/^gentoo-sources-//'
    done
)
oldKernelVersions=()
for v in "${installedVersions[@]}"; do
    [ "$v" = "$currentKernelVersion" ] && continue
    [ "$v" = "$newKernelVersion" ] && continue
    oldKernelVersions+=("$v")
done
if [ ${#oldKernelVersions[@]} -eq 0 ]; then
    cecho "RED" "WARNING: no 'old' kernel to remove (only current/new installed). Continuing."
else
    cecho "YELLOW" "Old kernel(s) to remove during cleanup: ${oldKernelVersions[*]}"
fi
cecho "CYAN" "END - choose kernel, press enter"
read -r -p "$*"

cecho "CYAN" "START - configure kernel"
cecho "YELLOW" "move to source, this is the content of /usr/src/linux:"
cd "/usr/src/linux" || { cecho "RED" "ERROR: cannot cd into /usr/src/linux. Aborting."; exit 1; }
ls -la
cecho "YELLOW" "1.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "backup config, this is the config content:"
zcat "/proc/config.gz" > "/usr/src/linux/.config"
less "/usr/src/linux/.config"
cecho "YELLOW" "2.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "list new config"
make listnewconfig
cecho "YELLOW" "3.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "set defaults config from old"
make olddefconfig
cecho "YELLOW" "4.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "show removed options"
diff <(sort .config) <(sort .config.old) | awk '/^>.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "5.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "show diff options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "6.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "configure manually"
make menuconfig
cecho "YELLOW" "7.press enter to continue"
read -r -p "$*"
cecho "YELLOW" "show again options"
diff <(sort .config) <(sort .config.old) | awk '/^<.*(=|Linux)/ { $1=""; print }'
cecho "YELLOW" "8.press enter to continue"
read -r -p "$*"
cecho "CYAN" "END - configure kernel, press enter"
read -r -p "$*"

cecho "CYAN" "START - build kernel"

cecho "YELLOW" "build modules"
make modules_prepare
cecho "YELLOW" "9.press enter to continue"
read -r -p "$*"

cecho "YELLOW" "build kernel"
make -j6
cecho "YELLOW" "10.press enter to continue"
read -r -p "$*"

cecho "YELLOW" "rebuild modules"
emerge --ask @module-rebuild
cecho "YELLOW" "11.press enter to continue"
read -r -p "$*"

cecho "CYAN" "END - build kernel, press enter"
read -r -p "$*"

cecho "CYAN" "START - install kernel"
cecho "YELLOW" "install modules"
make modules_install
cecho "YELLOW" "12.press enter to continue"
read -r -p "$*"

cecho "YELLOW" "install kernel"
make install
cecho "YELLOW" "13.press enter to continue"
read -r -p "$*"

cecho "CYAN" "END - install kernel, press enter"
read -r -p "$*"

cecho "CYAN" "START update initramfs with Dracut"
dracut --kver="$newKver"
cecho "CYAN" "END update initramfs with Dracut, press enter "
read -r -p "$*"

cecho "CYAN" "START - update bootloader"
grub-mkconfig -o "/boot/grub/grub.cfg"
cecho "CYAN" "END - update bootloader, press enter"
read -r -p "$*"

cecho "CYAN" "START - clean kernel"

cecho "YELLOW" "save new kernel source $newKernelVersion"
emerge --noreplace "sys-kernel/gentoo-sources:$newKernelVersion"
# also pin current so the "new+current pinned" invariant always holds
# (self-healing if a previous upgrade left it unpinned); --noreplace is idempotent
cecho "YELLOW" "keep current kernel source $currentKernelVersion pinned"
emerge --noreplace "sys-kernel/gentoo-sources:$currentKernelVersion"
cecho "YELLOW" "14.press enter to continue"
read -r -p "$*"

if [ ${#oldKernelVersions[@]} -eq 0 ]; then
    cecho "RED" "No 'old' kernel to deselect, skipping this step."
else
    for oldVer in "${oldKernelVersions[@]}"; do
        cecho "YELLOW" "remove old kernel source $oldVer"
        emerge --deselect "sys-kernel/gentoo-sources:$oldVer"
    done
fi
cecho "YELLOW" "15.press enter to continue"
read -r -p "$*"

cecho "YELLOW" "cleanup packages"
emerge --ask --depclean
cecho "YELLOW" "16.press enter to continue"
read -r -p "$*"

cecho "YELLOW" "remove old kernels"
eclean-kernel -n 3
cecho "YELLOW" "17.press enter to continue"
read -r -p "$*"

cecho "CYAN" "END - clean kernel, press enter"

cecho "GREEN" "END - kernel upgrade, press enter close"
read -r -p "$*"
