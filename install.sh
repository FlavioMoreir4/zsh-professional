#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME não definido}"
STATE_DIR="$HOME_DIR/.local/state/zsh-professional"
BACKUP_ROOT="$STATE_DIR/backups"

APPLY=0
SKIP_PACKAGES=0
WITH_STARSHIP_COPR=0

usage() {
  cat <<'EOF'
Zsh Professional - Fedora 45

Uso:
  ./install.sh
  ./install.sh --apply
  ./install.sh --apply --with-starship-copr
  ./install.sh --apply --skip-packages

Opções:
  --apply                 Autoriza alterações e instalação.
  --skip-packages         Não chama DNF; exige dependências instaladas.
  --with-starship-copr    Habilita atim/starship e instala Starship.
  -h, --help              Ajuda.

O shell padrão nunca é alterado. Não executa chsh.
EOF
}

while (($#)); do
  case "$1" in
    --apply) APPLY=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --with-starship-copr) WITH_STARSHIP_COPR=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

TARGETS=(
  ".zshenv" ".zshrc"
  ".config/zsh/conf.d/00-environment.zsh"
  ".config/zsh/conf.d/10-options.zsh"
  ".config/zsh/conf.d/20-history.zsh"
  ".config/zsh/conf.d/30-completion.zsh"
  ".config/zsh/conf.d/40-keybindings.zsh"
  ".config/zsh/conf.d/45-autosuggestions.zsh"
  ".config/zsh/conf.d/50-fzf.zsh"
  ".config/zsh/conf.d/60-atuin.zsh"
  ".config/zsh/conf.d/70-zoxide.zsh"
  ".config/zsh/conf.d/80-aliases.zsh"
  ".config/zsh/conf.d/85-functions.zsh"
  ".config/zsh/conf.d/90-starship.zsh"
  ".config/zsh/conf.d/99-highlighting.zsh"
  ".config/atuin/config.toml"
  ".config/starship.toml"
)

BASE_PACKAGES=(zsh atuin fzf zoxide eza zsh-autosuggestions zsh-syntax-highlighting)

[[ -r /etc/os-release ]] || { echo "Não foi possível identificar o sistema." >&2; exit 1; }
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == fedora && "${VERSION_ID:-}" == 45 ]] || {
  echo "Preparado para Fedora 45. Detectado: ${PRETTY_NAME:-desconhecido}" >&2
  exit 1
}

if (( ! APPLY )); then
  printf 'DRY-RUN: nenhuma alteração será feita.\nSistema: %s\n' "${PRETTY_NAME}"
  printf 'Arquivos gerenciados: %s\n' "${#TARGETS[@]}"
  printf 'Pacotes base: %s\n' "${BASE_PACKAGES[*]}"
  printf 'Starship via COPR: %s\n' "$([[ $WITH_STARSHIP_COPR == 1 ]] && echo sim || echo não)"
  echo "Shell padrão: NÃO será alterado."
  echo "Para aplicar: ./install.sh --apply --with-starship-copr"
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$timestamp"
[[ -e "$BACKUP_DIR" ]] && BACKUP_DIR="${BACKUP_DIR}-$$"
mkdir -p "$BACKUP_DIR/home"
: > "$BACKUP_DIR/manifest.tsv"
: > "$BACKUP_DIR/packages-added.txt"

# Backup exato dos arquivos que serão gerenciados.
for rel in "${TARGETS[@]}"; do
  src="$HOME_DIR/$rel"
  saved="$BACKUP_DIR/home/$rel"
  if [[ -e "$src" || -L "$src" ]]; then
    mkdir -p "$(dirname "$saved")"
    cp -a -- "$src" "$saved"
    printf 'present\t%s\n' "$rel" >> "$BACKUP_DIR/manifest.tsv"
  else
    printf 'absent\t%s\n' "$rel" >> "$BACKUP_DIR/manifest.tsv"
  fi
done

previous_shell="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7 || true)"
{
  printf 'created_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'hostname=%s\n' "$(hostname)"
  printf 'previous_shell=%s\n' "$previous_shell"
  printf 'shell_change_performed=no\n'
  printf 'starship_copr_requested=%s\n' "$WITH_STARSHIP_COPR"
  printf 'starship_copr_preexisting=unknown\n'
} > "$BACKUP_DIR/metadata.txt"

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

if (( ! SKIP_PACKAGES )); then
  packages=("${BASE_PACKAGES[@]}")

  if (( WITH_STARSHIP_COPR )); then
    if dnf copr list --enabled 2>/dev/null | grep -Fq 'atim/starship'; then
      sed -i 's/^starship_copr_preexisting=.*/starship_copr_preexisting=yes/' "$BACKUP_DIR/metadata.txt"
    else
      run_privileged dnf copr enable --assumeyes atim/starship
      sed -i 's/^starship_copr_preexisting=.*/starship_copr_preexisting=no/' "$BACKUP_DIR/metadata.txt"
    fi
    packages+=(starship)
  fi

  for pkg in "${packages[@]}"; do
    if ! rpm -q "$pkg" >/dev/null 2>&1; then
      printf '%s\n' "$pkg" >> "$BACKUP_DIR/packages-added.txt"
    fi
  done

  run_privileged dnf install --assumeyes "${packages[@]}"
fi

install -D -m 0644 "$SCRIPT_DIR/config/.zshenv" "$HOME_DIR/.zshenv"
install -D -m 0644 "$SCRIPT_DIR/config/.zshrc" "$HOME_DIR/.zshrc"

for source_file in "$SCRIPT_DIR"/config/zsh/conf.d/*.zsh; do
  rel=".config/zsh/conf.d/$(basename "$source_file")"
  install -D -m 0644 "$source_file" "$HOME_DIR/$rel"
done

install -D -m 0600 "$SCRIPT_DIR/config/atuin/config.toml" "$HOME_DIR/.config/atuin/config.toml"
install -D -m 0644 "$SCRIPT_DIR/config/starship.toml" "$HOME_DIR/.config/starship.toml"

chmod 0700 "$HOME_DIR/.config/atuin" "$BACKUP_ROOT" "$BACKUP_DIR"
echo
echo "Configuração instalada. Backup: $BACKUP_DIR"
echo "Teste com: zsh"
echo "Diagnóstico: ./doctor.sh"
echo "Rollback: ./rollback.sh '$BACKUP_DIR'"
echo "O shell padrão NÃO foi alterado."
