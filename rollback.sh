#!/usr/bin/env bash
set -Eeuo pipefail

HOME_DIR="${HOME:?HOME não definido}"
BACKUP_ROOT="$HOME_DIR/.local/state/zsh-professional/backups"
REMOVE_PACKAGES=0
BACKUP_DIR=""

usage() {
  echo "Uso: ./rollback.sh [diretorio-do-backup] [--remove-packages]"
}

for arg in "$@"; do
  case "$arg" in
    --remove-packages) REMOVE_PACKAGES=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      [[ -z "$BACKUP_DIR" ]] || { echo "Argumento inesperado: $arg" >&2; exit 2; }
      BACKUP_DIR="$arg"
      ;;
  esac
done

if [[ -z "$BACKUP_DIR" ]]; then
  [[ -d "$BACKUP_ROOT" ]] || { echo "Backups não encontrados." >&2; exit 1; }
  mapfile -t backups < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%p\n' | sort)
  ((${#backups[@]})) || { echo "Nenhum backup encontrado." >&2; exit 1; }
  BACKUP_DIR="${backups[-1]}"
fi

[[ -f "$BACKUP_DIR/manifest.tsv" ]] || { echo "Manifesto ausente: $BACKUP_DIR" >&2; exit 1; }

echo "Backup: $BACKUP_DIR"
echo "Restaurar arquivos gerenciados ao estado anterior?"
(( REMOVE_PACKAGES )) && echo "Também foi solicitada remoção opcional de RPMs."
read -r -p "Continuar? [y/N] " answer
[[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]] || { echo "Cancelado."; exit 0; }

while IFS=$'\t' read -r state rel; do
  [[ -n "$rel" ]] || continue
  case "$rel" in
    .zshenv|.zshrc|.config/zsh/conf.d/*.zsh|.config/atuin/config.toml|.config/starship.toml) ;;
    *) echo "Caminho não permitido: $rel" >&2; exit 1 ;;
  esac

  target="$HOME_DIR/$rel"
  saved="$BACKUP_DIR/home/$rel"
  if [[ "$state" == present ]]; then
    [[ -e "$saved" || -L "$saved" ]] || { echo "Backup ausente: $saved" >&2; exit 1; }
    mkdir -p "$(dirname "$target")"
    rm -f -- "$target"
    cp -a -- "$saved" "$target"
    echo "Restaurado: $rel"
  elif [[ "$state" == absent ]]; then
    rm -f -- "$target"
    echo "Removido arquivo criado: $rel"
  else
    echo "Estado inválido: $state" >&2
    exit 1
  fi
done < "$BACKUP_DIR/manifest.tsv"

rmdir "$HOME_DIR/.config/zsh/conf.d" 2>/dev/null || true
rmdir "$HOME_DIR/.config/zsh" 2>/dev/null || true
rmdir "$HOME_DIR/.config/atuin" 2>/dev/null || true

if (( REMOVE_PACKAGES )) && [[ -s "$BACKUP_DIR/packages-added.txt" ]]; then
  echo "Pacotes ausentes antes da instalação:"
  cat "$BACKUP_DIR/packages-added.txt"
  read -r -p "Remover esses pacotes via DNF? [y/N] " remove_answer
  if [[ "$remove_answer" == [yY] || "$remove_answer" == [yY][eE][sS] ]]; then
    mapfile -t packages < "$BACKUP_DIR/packages-added.txt"
    if ((${#packages[@]})); then
      if [[ "$(id -u)" -eq 0 ]]; then dnf remove --assumeyes "${packages[@]}"; else sudo dnf remove --assumeyes "${packages[@]}"; fi
    fi
  fi
fi

if (( REMOVE_PACKAGES )) &&
   grep -q '^starship_copr_requested=1$' "$BACKUP_DIR/metadata.txt" &&
   grep -q '^starship_copr_preexisting=no$' "$BACKUP_DIR/metadata.txt"; then
  read -r -p "Desabilitar o COPR atim/starship adicionado pelo instalador? [y/N] " copr_answer
  if [[ "$copr_answer" == [yY] || "$copr_answer" == [yY][eE][sS] ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then dnf copr disable --assumeyes atim/starship; else sudo dnf copr disable --assumeyes atim/starship; fi
  fi
fi

echo "Rollback de configuração concluído. Shell padrão não foi alterado."
