# RUN AS ROOT!
# Install oh-my-zsh

yay -S zsh
curl -L http://install.ohmyz.sh | sh

# Add ZSH Plugins
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
echo "Installing plugins in $ZSH_CUSTOM"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Change default shell to ZSH
chsh -s $(which zsh)