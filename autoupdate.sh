#!/bin/bash

source "$(dirname "$0")/helper.sh"

cecho "GREEN" "START - packages update"

cecho "CYAN" "START - packages sync"
sudo -E emaint --auto sync
cecho "CYAN" "END - packages sync, press enter"

read -r -p "$*"

cecho "CYAN" "START - packages install"
sudo emerge --ask --verbose --update --deep --newuse --verbose-conflicts --exclude 'x11-drivers/nvidia-drivers sys-kernel/gentoo-sources sys-kernel/linux-headers'  @world
cecho "CYAN" "END - packages install, press enter"

read -r -p "$*"

cecho "CYAN" "START - dispatch conf"
sudo -E dispatch-conf
cecho "CYAN" "END - dispatch conf"

cecho "CYAN" "START - packages clean"
sudo emerge --depclean
cecho "CYAN" "END - packages clean"

cecho "GREEN" "END - packages update, press enter to close"
read -r -p "$*"
