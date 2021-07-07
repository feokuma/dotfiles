#!/bin/sh

sudo pacman -Syu
sudo pacman -S yay 
yay -S base-devel
yay -S $(cat install_packages.txt | xargs)