# Emacs keymap e navegação de linha/palavra.
bindkey -e

# Home/End
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char

# Delete/Insert
bindkey '^[[3~' delete-char
bindkey '^[[2~' overwrite-mode

# PageUp/PageDown
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history

# Ctrl+Home/End
bindkey '^[[1;5H' beginning-of-line
bindkey '^[[1;5F' end-of-line

# Delete/Insert
bindkey '^[[3~' delete-char
bindkey '^[[2~' overwrite-mode

# PageUp/PageDown
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history

# Ctrl+Home/Ctrl+End (if supported)
bindkey '^[[1;5H' beginning-of-line
bindkey '^[[1;5F' end-of-line
