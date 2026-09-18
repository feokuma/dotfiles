autoload -Uz compinit
compinit

# Default editor (used by yazi, git, fzf, etc.)
export EDITOR="nvim"
export VISUAL="nvim"

# yazi: change shell cwd on exit (open with `yy`; required because yazi runs
# as a child process and cannot move the parent shell itself)
yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

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
