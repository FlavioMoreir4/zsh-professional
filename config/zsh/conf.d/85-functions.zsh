mkcd() {
  if (( $# != 1 )); then
    print -u2 'Uso: mkcd <diretorio>'
    return 2
  fi
  command mkdir -p -- "$1" && builtin cd -- "$1"
}

croot() {
  local repo_root
  repo_root="$(command git rev-parse --show-toplevel 2>/dev/null)" || {
    print -u2 'Este diretório não pertence a um repositório Git.'
    return 1
  }
  builtin cd -- "$repo_root"
}
