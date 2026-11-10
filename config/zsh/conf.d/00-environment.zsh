# Preserva completions locais do Lerd, OpenChamber e Copilot.
typeset -U fpath
[[ -d "$HOME/.local/share/zsh/site-functions" ]] &&
  fpath=("$HOME/.local/share/zsh/site-functions" "${fpath[@]}")

# Lerd controla o fnm. Não executar `fnm env` neste shell.
