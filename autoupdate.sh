#!/bin/bash

source "$(dirname "$0")/helper.sh"

cecho "GREEN" "START - packages update"

cecho "CYAN" "START - packages sync"
sudo emaint --auto sync
cecho "CYAN" "END - packages sync, press enter"

read -p "$*"

cecho "CYAN" "START - packages install"
sudo emerge --ask --verbose --update --deep --newuse --exclude 'x11-drivers/nvidia-drivers'  @world
cecho "CYAN" "END - packages install, press enter"

read -p "$*"

cecho "CYAN" "START - dispatch conf"
sudo dispatch-conf
cecho "CYAN" "END - dispatch conf"

cecho "CYAN" "START - packages clean"
sudo emerge --depclean
cecho "CYAN" "END - packages clean"

cecho "GREEN" "END - packages update, press enter close"
read -p "$*"
