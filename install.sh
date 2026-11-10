#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_VERSION="3.0.0"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-professional"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE_ROOT/backups/$TIMESTAMP"
APPLY=0
SKIP_PACKAGES=0
WITH_STARSHIP_COPR=0

usage() {
  cat <<'EOF'
Zsh Professional · Fedora 45

Uso:
  ./install.sh
  ./install.sh --apply
  ./install.sh --apply --skip-packages
  ./install.sh --apply --with-starship-copr

Opções:
  --apply               aplica alterações (padrão é dry-run)
  --skip-packages       não instala pacotes nem altera repositórios
  --with-starship-copr  habilita atim/starship e instala Starship pelo DNF
  -h, --help            mostra esta ajuda

O shell padrão não é alterado. O script não executa chsh nem usermod.
EOF
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

[[ "$EUID" -ne 0 ]] || {
  echo "Execute como usuário normal, sem sudo."
  exit 1
}
[[ -r /etc/fedora-release ]] || {
  echo "Este instalador exige Fedora 45."
  exit 1
}
grep -qE 'Fedora release 45([[:space:]]|$)' /etc/fedora-release || {
  printf 'Distribuição detectada: %s\n' "$(cat /etc/fedora-release)"
  echo "Este pacote foi preparado especificamente para Fedora 45."
  exit 1
}

required_files=(
  "config/.zshenv"
  "config/.zshrc"
  "config/atuin/config.toml"
  "config/starship.toml"
  "config/zsh/conf.d/00-environment.zsh"
  "config/zsh/conf.d/99-highlighting.zsh"
)
for file in "${required_files[@]}"; do
  [[ -f "$ROOT/$file" ]] || {
    printf 'Arquivo obrigatório ausente: %s\n' "$file" >&2
    exit 1
  }
done

TARGETS=(
  "$HOME/.zshenv"
  "$HOME/.zshrc"
  "$HOME/.config/zsh/conf.d"
  "$HOME/.config/atuin/config.toml"
  "$HOME/.config/starship.toml"
)
PACKAGES=(
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  zoxide
  atuin
  eza
  bat
  ripgrep
  fd-find
  git
  curl
  tar
  xz
  fontconfig
)

if (( ! APPLY )); then
  echo "DRY-RUN · nenhuma alteração será feita."
  printf 'Versão: %s\n' "$PROJECT_VERSION"
  printf 'Backup previsto: %s\n\n' "$BACKUP"
  echo "Arquivos que serão gerenciados:"
  printf '  - %s\n' "${TARGETS[@]}"
  if (( ! SKIP_PACKAGES )); then
    printf '\nPacotes DNF: %s\n' "${PACKAGES[*]}"
    if (( WITH_STARSHIP_COPR )); then
      echo "Starship: COPR atim/starship será habilitado."
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
  if (( WITH_STARSHIP_COPR )); then
    sudo dnf -y copr enable atim/starship
    sudo dnf -y install starship
  fi

  sudo dnf install -y --skip-unavailable "${PACKAGES[@]}"

  if ! command -v starship >/dev/null 2>&1; then
    echo "AVISO: Starship não está instalado."
    echo "Execute novamente com --with-starship-copr ou instale-o por um método confiável."
  fi

  for package in "${PACKAGES[@]}" starship; do
    rpm -q "$package" >/dev/null 2>&1 || continue
    if ! grep -qxF "$package" "$BACKUP/packages-before.txt"; then
      printf '%s\n' "$package" >> "$BACKUP/packages-added.txt"
    fi
  done
fi

# Instala arquivos sem tocar em .zshrc.local, Bash, históricos ou shell padrão.
mkdir -p "$HOME/.config/zsh/conf.d" "$HOME/.config/atuin"
install -m 644 "$ROOT/config/.zshenv" "$HOME/.zshenv"
install -m 644 "$ROOT/config/.zshrc" "$HOME/.zshrc"
cp -a "$ROOT/config/zsh/conf.d/." "$HOME/.config/zsh/conf.d/"
install -m 600 "$ROOT/config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
install -m 644 "$ROOT/config/starship.toml" "$HOME/.config/starship.toml"

echo
echo "Instalação concluída."
printf 'Backup: %s\n' "$BACKUP"
echo "Shell padrão preservado."
echo "Teste agora com: zsh"
echo "Diagnóstico: ./doctor.sh"
echo "Rollback: ./rollback.sh '$BACKUP'"
