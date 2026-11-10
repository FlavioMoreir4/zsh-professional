#!/usr/bin/env bash
set -Eeuo pipefail

STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-professional"
BACKUP_ROOT="$STATE_ROOT/backups"
BACKUP=""
REMOVE_PACKAGES=0
RESTORE_COPR=0

usage() {
  cat <<'EOF'
Uso:
  ./rollback.sh
  ./rollback.sh /caminho/do/backup
  ./rollback.sh --remove-packages
  ./rollback.sh --restore-copr
  ./rollback.sh --remove-packages --restore-copr /caminho/do/backup

Por padrão, restaura somente arquivos. Remoção de RPMs e repositórios
exige opções explícitas.
EOF
}

while (($#)); do
  case "$1" in
    --remove-packages) REMOVE_PACKAGES=1 ;;
    --restore-copr) RESTORE_COPR=1 ;;
    -h|--help) usage; exit 0 ;;
    *) BACKUP="$1" ;;
  esac
  shift
done

if [[ -z "$BACKUP" ]]; then
  [[ -d "$BACKUP_ROOT" ]] || {
    echo "Nenhum backup encontrado."
    exit 1
  }
  latest="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tail -n 1)"
  [[ -n "$latest" ]] || {
    echo "Nenhum backup encontrado."
    exit 1
  }
  BACKUP="$BACKUP_ROOT/$latest"
fi

[[ -f "$BACKUP/manifest.tsv" ]] || {
  printf 'Backup inválido: %s\n' "$BACKUP" >&2
  exit 1
}

echo "Restaurando: $BACKUP"
index=0
while IFS=$'\t' read -r target existed; do
  [[ -n "$target" ]] || { ((index+=1)); continue; }

  rm -rf -- "$target"
  if [[ "$existed" == "1" ]]; then
    [[ -e "$BACKUP/files/$index" || -L "$BACKUP/files/$index" ]] || {
      printf 'Backup do destino ausente: %s\n' "$target" >&2
      exit 1
    }
    mkdir -p -- "$(dirname -- "$target")"
    cp -a -- "$BACKUP/files/$index" "$target"
    printf 'Restaurado: %s\n' "$target"
  else
    printf 'Removido (não existia antes): %s\n' "$target"
  fi
  ((index+=1))
done < "$BACKUP/manifest.tsv"

if (( REMOVE_PACKAGES )) && [[ -s "$BACKUP/packages-added.txt" ]]; then
  echo
  echo "Pacotes instalados por este projeto e ausentes antes:"
  cat "$BACKUP/packages-added.txt"
  read -r -p "Confirma a remoção desses pacotes? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    mapfile -t packages < "$BACKUP/packages-added.txt"
    sudo dnf remove -y "${packages[@]}"
  else
    echo "Remoção de pacotes cancelada."
  fi
fi

if (( RESTORE_COPR )) &&
   [[ -f "$BACKUP/copr-before.txt" ]] &&
   grep -qx 'disabled' "$BACKUP/copr-before.txt" &&
   dnf repolist --enabled 2>/dev/null | grep -qiE 'atim.*starship|starship.*atim'
then
  read -r -p "Desabilitar o COPR atim/starship habilitado durante a instalação? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo dnf copr disable -y atim/starship
  else
    echo "Repositório mantido."
  fi
fi

echo
echo "Rollback concluído. O shell padrão não foi alterado."
