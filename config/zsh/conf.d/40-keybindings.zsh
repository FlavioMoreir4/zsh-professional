# Keymap Emacs e navegação de linha/palavra.
# Sequências variam entre terminais; as abaixo cobrem Ptyxis, GNOME Console e VTE.
bindkey -e

# Home/End
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Ctrl+setas: navegação por palavra (também aceita a sugestão palavra a palavra)
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Seta direita/esquerda explícitas: forward-char é um dos widgets que
# o zsh-autosuggestions usa para aceitar a sugestão inteira no fim da linha.
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char

# Delete/Insert
bindkey '^[[3~' delete-char
bindkey '^[[2~' overwrite-mode

# PageUp/PageDown
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history

# Ctrl+Home/Ctrl+End
bindkey '^[[1;5H' beginning-of-line
bindkey '^[[1;5F' end-of-line
