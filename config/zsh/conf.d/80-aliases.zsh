# Eza substitui ls apenas quando instalado.
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias l='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  alias ll='command ls -lah'
fi

# Laravel/PHP.
alias a='php artisan'
alias art='php artisan'
alias pest='vendor/bin/pest'
alias pint='vendor/bin/pint'
alias stan='vendor/bin/phpstan analyse'

# Git.
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --decorate -12'
alias gp='git pull --ff-only'
alias gco='git checkout'
alias gsw='git switch'
