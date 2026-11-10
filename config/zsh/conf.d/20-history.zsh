# Histórico nativo de contingência.
# Atuin controla Ctrl+R; o histórico nativo continua disponível pelas setas.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

[[ -d "${HISTFILE:h}" ]] || command mkdir -p "${HISTFILE:h}"

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
unsetopt SHARE_HISTORY
