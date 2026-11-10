# FZF fornece Ctrl+T e Alt+C. Atuin assume Ctrl+R no módulo seguinte.
if (( $+commands[fzf] )); then
  eval "$(fzf --zsh)"
fi

export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border
  --info=inline
"
