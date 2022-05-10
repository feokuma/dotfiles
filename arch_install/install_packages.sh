#!/bin/sh

sudo pacman-mirrors
sudo pacman -Syyu --no-confirm
sudo pacman -S yay --no-confirm
yay -S base-devel 
yay -S $(cat install_packages.txt | xargs)
npm i -g $(cat npm_packages.txt | xargs)