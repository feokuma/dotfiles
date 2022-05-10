#!/bin/sh

sudo pacman-mirrors
sudo pacman -Syyu --no-confirm

cd /opt
sudo git clone https://aur.archlinux.org/yay-git.git
sudo chown -R $USER:$USER ./yay-git
cd yay-git
makepkg -si
cd $HOME

yay -S base-devel 
yay -S $(cat install_packages.txt | xargs)
npm i -g $(cat npm_packages.txt | xargs)