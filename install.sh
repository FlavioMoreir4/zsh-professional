#!/usr/bin/env bash
# Zsh Professional · instalador para Fedora (DNF5).
# Dry-run por padrão. Nunca altera o shell padrão.
set -Eeuo pipefail

PROJECT_VERSION="3.1.0"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-professional"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE_ROOT/backups/$TIMESTAMP"
TESTED_FEDORA=45
MIN_FEDORA=41   # DNF5 é o padrão a partir do Fedora 41
APPLY=0
SKIP_PACKAGES=0
WITH_STARSHIP_COPR=0
STARSHIP_OK=1

usage() {
  cat <<'USAGE'
Zsh Professional · Fedora

Uso:
  ./install.sh                          dry-run: mostra o que faria
  ./install.sh --apply                  instala pacotes e aplica a configuração
  ./install.sh --apply --with-starship-copr
                                        idem + Starship via COPR atim/starship
  ./install.sh --apply --skip-packages  só copia arquivos (não chama DNF)

Opções:
  --apply               aplica as alterações (o padrão é dry-run)
  --skip-packages       não instala pacotes nem altera repositórios
  --with-starship-copr  habilita atim/starship e instala o Starship pelo DNF
  -h, --help            mostra esta ajuda

O shell padrão não é alterado. O script não executa chsh nem usermod.
USAGE
}

while (($#)); do
  case "$1" in
    --apply) APPLY=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --with-starship-copr) WITH_STARSHIP_COPR=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opção desconhecida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$EUID" -ne 0 ]] || { echo "Execute como usuário normal, sem sudo."; exit 1; }
[[ -r /etc/fedora-release ]] || { echo "Este instalador exige Fedora."; exit 1; }

FEDORA_VERSION="$(sed -nE 's/.*release ([0-9]+).*/\1/p' /etc/fedora-release)"
[[ -n "$FEDORA_VERSION" && "$FEDORA_VERSION" -ge "$MIN_FEDORA" ]] || {
  printf 'Fedora %s não suportado (mínimo: %s).\n' "${FEDORA_VERSION:-?}" "$MIN_FEDORA" >&2
  exit 1
}
if [[ "$FEDORA_VERSION" -ne "$TESTED_FEDORA" ]]; then
  printf 'AVISO: testado no Fedora %s; você está no Fedora %s.\n' "$TESTED_FEDORA" "$FEDORA_VERSION"
fi

required_files=(
  "config/.zshenv" "config/.zshrc"
  "config/atuin/config.toml" "config/starship.toml"
  "config/zsh/conf.d/00-environment.zsh" "config/zsh/conf.d/99-highlighting.zsh"
)
for file in "${required_files[@]}"; do
  [[ -f "$ROOT/$file" ]] || { printf 'Arquivo obrigatório ausente: %s\n' "$file" >&2; exit 1; }
done

# Alvos gerenciados, arquivo por arquivo: módulos que você criar em conf.d/
# não são tocados nem pelo instalador nem pelo rollback.
TARGETS=("$HOME/.zshenv" "$HOME/.zshrc")
for module in "$ROOT"/config/zsh/conf.d/*.zsh; do
  TARGETS+=("$HOME/.config/zsh/conf.d/$(basename -- "$module")")
done
TARGETS+=("$HOME/.config/atuin/config.toml" "$HOME/.config/starship.toml")

# Somente o que a configuração usa.
PACKAGES=(zsh zsh-autosuggestions zsh-syntax-highlighting fzf zoxide atuin eza git)

if (( ! APPLY )); then
  echo "DRY-RUN · nenhuma alteração será feita."
  printf 'Versão: %s · Fedora detectado: %s\n' "$PROJECT_VERSION" "$FEDORA_VERSION"
  printf 'Backup previsto: %s\n\n' "$BACKUP"
  echo "Arquivos que serão gerenciados:"
  printf '  - %s\n' "${TARGETS[@]}"
  if (( ! SKIP_PACKAGES )); then
    printf '\nPacotes DNF: %s\n' "${PACKAGES[*]}"
    if (( WITH_STARSHIP_COPR )); then
      echo "Starship: COPR atim/starship será habilitado (falha não aborta a instalação)."
    else
      echo "Starship: não será instalado sem --with-starship-copr."
    fi
  fi
  echo
  echo "Shell padrão: preservado."
  echo "Use --apply para executar."
  exit 0
fi

# Backup integral antes de instalar pacotes ou substituir arquivos.
mkdir -p "$BACKUP/files"
: > "$BACKUP/manifest.tsv"
: > "$BACKUP/packages-before.txt"
: > "$BACKUP/packages-added.txt"
printf 'disabled\n' > "$BACKUP/copr-before.txt"

index=0
for target in "${TARGETS[@]}"; do
  if [[ -e "$target" || -L "$target" ]]; then
    printf '%s\t1\n' "$target" >> "$BACKUP/manifest.tsv"
    cp -a -- "$target" "$BACKUP/files/$index"
  else
    printf '%s\t0\n' "$target" >> "$BACKUP/manifest.tsv"
  fi
  ((index+=1))
done

if (( ! SKIP_PACKAGES )); then
  for package in "${PACKAGES[@]}" starship; do
    if rpm -q "$package" >/dev/null 2>&1; then
      printf '%s\n' "$package" >> "$BACKUP/packages-before.txt"
    fi
  done
  if dnf repolist --enabled 2>/dev/null | grep -qiE 'atim.*starship|starship.*atim'; then
    printf 'enabled\n' > "$BACKUP/copr-before.txt"
  fi
fi

printf 'Backup criado: %s\n' "$BACKUP"

if (( ! SKIP_PACKAGES )); then
  # Pacotes base primeiro: uma falha no COPR não deixa o ambiente pela metade.
  sudo dnf install -y --skip-unavailable "${PACKAGES[@]}"

  if (( WITH_STARSHIP_COPR )) && ! command -v starship >/dev/null 2>&1; then
    # O subcomando "copr" vem do dnf5-plugins.
    sudo dnf copr --help >/dev/null 2>&1 || sudo dnf install -y dnf5-plugins
    if sudo dnf -y copr enable atim/starship && sudo dnf install -y starship; then
      :
    else
      STARSHIP_OK=0
      echo "AVISO: não foi possível instalar o Starship pelo COPR atim/starship."
    fi
  fi

  if ! command -v starship >/dev/null 2>&1; then
    STARSHIP_OK=0
    echo "AVISO: Starship não está instalado."
    echo "  Opções: ./install.sh --apply --with-starship-copr"
    echo "          ou https://starship.rs/guide/ (outros métodos oficiais)."
  fi

  for package in "${PACKAGES[@]}" starship; do
    rpm -q "$package" >/dev/null 2>&1 || continue
    grep -qxF "$package" "$BACKUP/packages-before.txt" ||
      printf '%s\n' "$package" >> "$BACKUP/packages-added.txt"
  done
fi

# Copia só os arquivos gerenciados; .zshrc.local, Bash, históricos e o shell
# padrão ficam intocados.
for target in "${TARGETS[@]}"; do
  case "$target" in
    "$HOME/.zshenv")                  src="$ROOT/config/.zshenv" ;;
    "$HOME/.zshrc")                   src="$ROOT/config/.zshrc" ;;
    "$HOME/.config/zsh/conf.d/"*)     src="$ROOT/config/zsh/conf.d/$(basename -- "$target")" ;;
    "$HOME/.config/atuin/config.toml") src="$ROOT/config/atuin/config.toml" ;;
    "$HOME/.config/starship.toml")    src="$ROOT/config/starship.toml" ;;
  esac
  mode=644
  [[ "$target" == "$HOME/.config/atuin/config.toml" ]] && mode=600
  install -D -m "$mode" -- "$src" "$target"
done

echo
echo "Instalação concluída (v$PROJECT_VERSION)."
printf 'Backup: %s\n' "$BACKUP"
echo "Shell padrão preservado."
echo
echo "Próximos passos:"
echo "  1. zsh                 (teste numa sessão; 'exit' volta ao shell anterior)"
echo "  2. ./doctor.sh         (diagnóstico)"
echo "  3. Terminal com Nerd Font (ex.: JetBrainsMono Nerd Font) para os ícones."
(( STARSHIP_OK )) || echo "  4. Instale o Starship (veja o aviso acima)."
printf 'Rollback: ./rollback.sh %q\n' "$BACKUP"
