# Ctrl+R para Atuin; seta para cima continua sendo o histórico nativo.
# A tecla ? do Atuin AI também fica desabilitada.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi
