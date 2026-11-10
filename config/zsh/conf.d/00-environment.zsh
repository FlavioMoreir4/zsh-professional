# Completions adicionais instaladas pelo Lerd e por ferramentas locais.
typeset -U fpath
[[ -d "$HOME/.local/share/zsh/site-functions" ]] &&
  fpath=("$HOME/.local/share/zsh/site-functions" $fpath)

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || command mkdir -p "$ZSH_CACHE_DIR"
