#!/usr/bin/env bash
# Zsh Professional · diagnóstico. Não altera nada.
set -uo pipefail

FAIL=0
ok()   { printf '  [OK]    %s\n' "$1"; }
warn() { printf '  [AVISO] %s\n' "$1"; }
bad()  { printf '  [ERRO]  %s\n' "$1"; FAIL=1; }

echo "Zsh Professional · diagnóstico"

echo
echo "Sistema"
if [[ -r /etc/fedora-release ]]; then ok "$(cat /etc/fedora-release)"; else warn "Fedora release não detectado"; fi

echo
echo "Comandos"
for command_name in zsh atuin fzf zoxide eza starship git lerd; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  [OK]    %-10s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    warn "$command_name não encontrado"
  fi
done
for plugin in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
              /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$plugin" ]]; then ok "plugin: $plugin"; else warn "plugin ausente: $plugin"; fi
done
if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi 'nerd'; then
  ok "Nerd Font instalada (selecione-a no terminal)"
else
  warn "nenhuma Nerd Font encontrada: ícones do Starship podem aparecer como quadrados"
fi

echo
echo "Arquivos"
for file in "$HOME/.zshenv" "$HOME/.zshrc" "$HOME/.config/atuin/config.toml" "$HOME/.config/starship.toml"; do
  if [[ -r "$file" ]]; then ok "$file"; else warn "arquivo ausente: $file"; fi
done

if command -v zsh >/dev/null 2>&1; then
  echo
  echo "Sintaxe Zsh"
  check_syntax() {
    local file="$1" label="${1#"$HOME"/}"
    [[ -f "$file" ]] || return 0
    if zsh -n "$file" >/dev/null 2>&1; then ok "$label"; else bad "sintaxe inválida: $label"; zsh -n "$file"; fi
  }
  check_syntax "$HOME/.zshenv"
  check_syntax "$HOME/.zshrc"
  while IFS= read -r -d '' file; do
    check_syntax "$file"
  done < <(find "$HOME/.config/zsh/conf.d" -type f -name '*.zsh' -print0 2>/dev/null)

  echo
  echo "Sessão interativa"
  startup_output="$(zsh -ic exit 2>&1 >/dev/null | grep -v "can't change option: zle" || true)"
  if [[ -z "$startup_output" ]]; then ok "zsh -i inicia sem mensagens de erro"; else bad "mensagens ao iniciar: $startup_output"; fi

  question_mark="$(zsh -ic "bindkey '?'" 2>/dev/null | tail -n 1)"
  if [[ "$question_mark" == *atuin* ]]; then
    warn "'?' está ligado ao Atuin AI (esperado: self-insert)"
  else
    ok "'?' digita normalmente"
  fi

  expected="$HOME/.local/share/lerd/bin"
  actual="$(zsh -c 'print -r -- "$path[1]"' 2>/dev/null || true)"
  if [[ -d "$expected" && "$actual" == "$expected" ]]; then
    ok "Lerd é a primeira entrada do PATH"
  elif [[ -d "$expected" ]]; then
    warn "Lerd não é a primeira entrada do PATH (atual: ${actual:-indisponível})"
  else
    warn "shims do Lerd não encontrados em $expected"
  fi
fi

if command -v starship >/dev/null 2>&1 && [[ -r "$HOME/.config/starship.toml" ]]; then
  echo
  echo "Starship"
  starship_stderr="$(starship prompt 2>&1 >/dev/null || true)"
  if [[ -z "$starship_stderr" ]]; then ok "starship.toml sem avisos"; else warn "starship: $starship_stderr"; fi
fi

if command -v atuin >/dev/null 2>&1; then
  echo
  echo "Atuin"
  ok "$(atuin --version)"
  if atuin doctor >/dev/null 2>&1; then ok "atuin doctor"; else warn "atuin doctor reportou pendências; execute-o para detalhes"; fi
fi

for completion in _lerd _openchamber _copilot; do
  if [[ -r "$HOME/.local/share/zsh/site-functions/$completion" ]]; then ok "completion preservada: $completion"; fi
done

echo
if (( FAIL )); then
  echo "Diagnóstico encontrou erros."
  exit 1
fi
echo "Diagnóstico finalizado."
