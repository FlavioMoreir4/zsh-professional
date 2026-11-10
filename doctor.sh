#!/usr/bin/env bash
set -uo pipefail
HOME_DIR="${HOME:?HOME não definido}"
CONFIG_DIR="$HOME_DIR/.config/zsh"

pass() { printf '[OK] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*"; }
fail() { printf '[FALHA] %s\n' "$*"; }

echo "========== ZSH PROFESSIONAL DOCTOR =========="
if command -v zsh >/dev/null 2>&1; then pass "$(zsh --version)"; else fail "Zsh não encontrado"; fi

for cmd in atuin fzf zoxide eza starship; do
  if command -v "$cmd" >/dev/null 2>&1; then pass "$cmd: $(command -v "$cmd")"; else warn "$cmd não encontrado"; fi
done

echo
echo "========== SINTAXE ZSH =========="
if command -v zsh >/dev/null 2>&1; then
  syntax_ok=1
  for file in "$HOME_DIR/.zshenv" "$HOME_DIR/.zshrc" "$CONFIG_DIR"/conf.d/*.zsh; do
    [[ -f "$file" ]] || continue
    if zsh -n "$file"; then pass "Sintaxe: ${file#$HOME_DIR/}"; else fail "Erro: ${file#$HOME_DIR/}"; syntax_ok=0; fi
  done
  (( syntax_ok )) || exit 1
fi

echo
echo "========== INTEGRAÇÃO LERD =========="
if command -v zsh >/dev/null 2>&1; then
  zsh -ic '
    print -r -- "php=$(whence -p php)"
    print -r -- "node=$(whence -p node)"
    print -r -- "npm=$(whence -p npm)"
    print -r -- "composer=$(whence -p composer)"
    print -r -- "lerd=$(whence -p lerd)"
    if [[ ":$PATH:" == *":$HOME/.config/herd-lite/bin:"* ]]; then
      print -r -- "herd_lite_in_path=yes"
    else
      print -r -- "herd_lite_in_path=no"
    fi
    print -r -- "completion_lerd=$([[ -f "$HOME/.local/share/zsh/site-functions/_lerd" ]] && print yes || print no)"
  ' 2>/dev/null
fi

echo
echo "========== ATUIN =========="
if command -v atuin >/dev/null 2>&1; then
  atuin config get auto_sync --resolved 2>/dev/null || true
  atuin config get update_check --resolved 2>/dev/null || true
  atuin config get secrets_filter --resolved 2>/dev/null || true
  atuin config get enter_accept --resolved 2>/dev/null || true
fi

echo
echo "O diagnóstico não altera o shell padrão."
