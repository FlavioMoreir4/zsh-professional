# Atuin assume Ctrl+R. A seta para cima permanece no histórico nativo.
# Não executa import: o histórico do Atuin começa limpo.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"

  # Versões recentes ligam "?" ao Atuin AI. Em vez de usar --disable-ai (que
  # não existe em versões antigas e quebraria o init), devolvemos a tecla ao
  # comportamento normal. Em versões sem AI, a condição simplesmente não ocorre.
  [[ "$(bindkey '?')" == *atuin* ]] && bindkey '?' self-insert
fi
