# Atuin assume Ctrl+R. A seta para cima permanece no histórico nativo.
# Não executar import automaticamente: o histórico Atuin começa limpo.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow --disable-ai --no-fzf-ctrl-r)"
fi
