autoload -Uz compinit
compinit

# Completion case-insensitive: "do[Tab]" completa "Downloads"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# History
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt share_history        # share entries across terminals immediately
setopt hist_ignore_all_dups # a new entry erases an older identical one
setopt hist_ignore_space    # commands starting with " " aren't saved
setopt hist_reduce_blanks   # strip redundant whitespace
setopt hist_verify          # !! expands on enter for review before execution

# Default editor (used by yazi, git, fzf, etc.)
export EDITOR="nvim"
export VISUAL="nvim"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
# Conveniência para o projeto rn-toolchain
alias gotest="./go test ./..."
alias gotestv="./go test -v ./..."

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

# Launch VS Code detached so it doesn't flood or hold the terminal
# (unalias first: re-sourcing the file with an old `alias code` loaded is a parse error)
# Resolve relative paths before passing: the wrapper cd's to its app dir exec,
# which would break `code .` and other relative paths.
unalias code 2>/dev/null
code() {
	local -a abs
	local arg
	for arg in "$@"; do
		case "$arg" in
			-*|[a-z]*:*) abs+=("$arg") ;; # flags and URI schemes stay as-is
			*) abs+=("${arg:A}") ;;        # resolve to absolute path
		esac
	done
	setsid -f visual-studio-code-electron "${abs[@]}" >/dev/null 2>&1 </dev/null
}

alias ls='eza'
alias la='eza -la'
alias tree='eza --tree'
eval "$(mise activate zsh)"
