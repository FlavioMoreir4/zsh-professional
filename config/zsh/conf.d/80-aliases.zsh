# Eza como padrão; /usr/bin/ls continua disponível explicitamente.
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto'
  alias l='eza --icons=auto'
  alias ll='eza -lah --icons=auto --git'
  alias la='eza -a --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
  alias la='ls -A --color=auto'
fi

# Laravel / PHP.
alias art='php artisan'
alias artisan='php artisan'
alias pest='./vendor/bin/pest'
alias pint='./vendor/bin/pint'
alias stan='./vendor/bin/phpstan'

# Composer.
alias ci='composer install'
alias cu='composer update'
alias cr='composer require'
alias cda='composer dump-autoload'

# Node / npm.
alias ni='npm install'
alias nu='npm update'
alias nr='npm run'
alias nd='npm run dev'
alias nb='npm run build'

# Git.
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Navegação.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
