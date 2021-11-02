#!/bin/sh

sudo pacman-mirrors
sudo pacman -Syyu
sudo pacman -S yay 
yay -S base-devel
yay -S $(cat install_packages.txt | xargs)