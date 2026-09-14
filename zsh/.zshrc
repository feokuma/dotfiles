autoload -Uz compinit
compinit

# Prompt
eval "$(starship init zsh)"

# Autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# History substring search: prefix-aware navigation with up/down arrows
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
# Fallback for terminals that report arrows in application mode
bindkey '\e[A' history-substring-search-up
bindkey '\e[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE_EXIT="yes"

# Fuzzy history: Ctrl+R
eval "$(fzf --zsh)"

# Syntax highlighting (must stay last)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls='eza'
alias la='eza -la'
alias tree='eza --tree'
