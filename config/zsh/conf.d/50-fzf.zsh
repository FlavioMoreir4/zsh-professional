# FZF primeiro; Atuin será carregado depois e assumirá Ctrl+R.
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi
