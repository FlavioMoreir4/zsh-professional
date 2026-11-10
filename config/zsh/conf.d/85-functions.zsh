# Cria diretório e entra nele.
mkcd() {
  [[ -n "$1" ]] || { print -u2 'uso: mkcd <diretório>'; return 2; }
  command mkdir -p -- "$1" && builtin cd -- "$1"
}

# Entra na raiz do repositório Git atual.
croot() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    print -u2 'não está dentro de um repositório Git'
    return 1
  }
  builtin cd -- "$root"
}
