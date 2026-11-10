#!/usr/bin/env bash
set -uo pipefail

FAIL=0
ok()   { printf '  [OK]   %s\n' "$1"; }
warn() { printf '  [AVISO] %s\n' "$1"; }
bad()  { printf '  [ERRO] %s\n' "$1"; FAIL=1; }

echo "Zsh Professional · diagnóstico"
if [[ -r /etc/fedora-release ]]; then
  ok "$(cat /etc/fedora-release)"
else
  warn "Fedora release não detectado"
fi

for command_name in zsh atuin fzf zoxide eza starship lerd; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  [OK]   %-12s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    warn "$command_name não encontrado"
  fi
done

for file in \
  "$HOME/.zshenv" \
  "$HOME/.zshrc" \
  "$HOME/.config/atuin/config.toml" \
  "$HOME/.config/starship.toml"
do
  [[ -r "$file" ]] && ok "$file" || warn "arquivo ausente: $file"
done

if command -v zsh >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    if zsh -n "$file" >/dev/null 2>&1; then
      ok "sintaxe: ${file#"$HOME"/}"
    else
      bad "sintaxe inválida: $file"
      zsh -n "$file"
    fi
  done < <(
    find "$HOME/.config/zsh/conf.d" -type f -name '*.zsh' -print0 2>/dev/null
  )

  if zsh -n "$HOME/.zshenv" >/dev/null 2>&1; then
    ok "sintaxe: .zshenv"
  else
    bad "sintaxe inválida: .zshenv"
    zsh -n "$HOME/.zshenv"
  fi

  if zsh -n "$HOME/.zshrc" >/dev/null 2>&1; then
    ok "sintaxe: .zshrc"
  else
    bad "sintaxe inválida: .zshrc"
    zsh -n "$HOME/.zshrc"
  fi

  expected="$HOME/.local/share/lerd/bin"
  actual="$(zsh -fc 'print -r -- "$path[1]"' 2>/dev/null || true)"
  if [[ -d "$expected" && "$actual" == "$expected" ]]; then
    ok "Lerd é a primeira entrada do PATH"
  elif [[ -d "$expected" ]]; then
    warn "Lerd não é a primeira entrada do PATH (atual: ${actual:-indisponível})"
  else
    warn "shims do Lerd não encontrados em $expected"
  fi

fi

if command -v atuin >/dev/null 2>&1; then
  if atuin doctor >/dev/null 2>&1; then
    ok "Atuin doctor"
  else
    warn "Atuin doctor reportou pendências; execute atuin doctor para detalhes"
  fi
fi

for completion in _lerd _openchamber _copilot; do
  if [[ -r "$HOME/.local/share/zsh/site-functions/$completion" ]]; then
    ok "completion preservada: $completion"
  fi
done

echo
if (( FAIL )); then
  echo "Diagnóstico encontrou erros."
  exit 1
fi
echo "Diagnóstico finalizado."
