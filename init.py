from pathlib import Path
import shutil, zipfile, hashlib, tomllib, subprocess, os, textwrap

root = Path("./")
# if root.exists():
#     shutil.rmtree(root)

files = {
"config/.zshenv": r'''# Zsh Professional · ambiente mínimo
# Este arquivo também é lido por shells não interativos.
# Não inicialize plugins, prompts, Atuin, FZF ou completions aqui.

typeset -U path PATH

# Ordem intencional: os shims do Lerd têm precedência sobre instalações
# globais de PHP, Composer e Node. O Lerd/fnm resolve a versão por projeto.
typeset -a _zsh_path_priority
_zsh_path_priority=(
  "$HOME/.local/share/lerd/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/bin"
)

[[ -d "$HOME/.config/composer/vendor/bin" ]] &&
  _zsh_path_priority+=("$HOME/.config/composer/vendor/bin")
[[ -d "$HOME/.composer/vendor/bin" ]] &&
  _zsh_path_priority+=("$HOME/.composer/vendor/bin")
[[ -d "$HOME/.local/share/pnpm" ]] &&
  _zsh_path_priority+=("$HOME/.local/share/pnpm")
[[ -d "$HOME/.bun/bin" ]] &&
  _zsh_path_priority+=("$HOME/.bun/bin")
[[ -d "$HOME/.lmstudio/bin" ]] &&
  _zsh_path_priority+=("$HOME/.lmstudio/bin")
[[ -d /home/linuxbrew/.linuxbrew/bin ]] &&
  _zsh_path_priority+=(/home/linuxbrew/.linuxbrew/bin)

path=("${_zsh_path_priority[@]}" "${path[@]}")
unset _zsh_path_priority

# path e PATH são arrays/variável vinculados no Zsh.
typeset -U path PATH
export PATH
''',

"config/.zshrc": r'''# Zsh Professional · Fedora 45
# Zsh puro, modular, sem Oh My Zsh, zplug ou framework.

[[ -o interactive ]] || return

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSH_MODULE_DIR="$ZSH_CONFIG_DIR/conf.d"

# Módulos explícitos: arquivos extras na pasta não são executados por acidente.
for module in \
  00-environment \
  10-options \
  20-history \
  30-completion \
  40-keybindings \
  45-autosuggestions \
  50-fzf \
  60-atuin \
  70-zoxide \
  80-aliases \
  85-functions \
  90-starship
do
  module_file="$ZSH_MODULE_DIR/$module.zsh"
  [[ -r "$module_file" ]] && source "$module_file"
done

# Configuração pessoal fica depois dos padrões para poder sobrescrevê-los.
# O arquivo é preservado pelo instalador e não faz parte do pacote.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Deve ser o último plugin: registra wrappers de widgets e syntax highlighting.
module_file="$ZSH_MODULE_DIR/99-highlighting.zsh"
[[ -r "$module_file" ]] && source "$module_file"

unset module module_file
''',

"config/zsh/conf.d/00-environment.zsh": r'''# Completions adicionais instaladas pelo Lerd e por ferramentas locais.
typeset -U fpath
[[ -d "$HOME/.local/share/zsh/site-functions" ]] &&
  fpath=("$HOME/.local/share/zsh/site-functions" $fpath)

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || command mkdir -p "$ZSH_CACHE_DIR"
''',

"config/zsh/conf.d/10-options.zsh": r'''# Comportamento interativo.
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt EXTENDED_GLOB
setopt PROMPT_SUBST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
unsetopt FLOW_CONTROL
''',

"config/zsh/conf.d/20-history.zsh": r'''# Histórico nativo de contingência.
# Atuin controla Ctrl+R; o histórico nativo continua disponível pelas setas.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

[[ -d "${HISTFILE:h}" ]] || command mkdir -p "${HISTFILE:h}"

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
unsetopt SHARE_HISTORY
''',

"config/zsh/conf.d/30-completion.zsh": r'''# Um único compinit por sessão.
autoload -Uz compinit
compinit -d "$ZSH_CACHE_DIR/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:messages' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}nenhum resultado%f'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
''',

"config/zsh/conf.d/40-keybindings.zsh": r'''# Emacs keymap e navegação de linha/palavra.
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
''',

"config/zsh/conf.d/45-autosuggestions.zsh": r'''# Plugin fornecido pelo pacote Fedora zsh-autosuggestions.
for candidate in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
do
  if [[ -r "$candidate" ]]; then
    source "$candidate"
    break
  fi
done

# Ctrl+Espaço aceita a sugestão inteira, se o terminal enviar esse atalho.
(( $+widgets[autosuggest-accept] )) && bindkey '^ ' autosuggest-accept
''',

"config/zsh/conf.d/50-fzf.zsh": r'''# FZF primeiro; Atuin será carregado depois e assumirá Ctrl+R.
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi
''',

"config/zsh/conf.d/60-atuin.zsh": r'''# Atuin assume Ctrl+R. A seta para cima permanece no histórico nativo.
# Não executar import automaticamente: o histórico Atuin começa limpo.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi
''',

"config/zsh/conf.d/70-zoxide.zsh": r'''# Navegação inteligente: z <nome> e zi para seleção interativa.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
''',

"config/zsh/conf.d/80-aliases.zsh": r'''# Eza substitui ls apenas quando instalado.
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias l='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  alias ll='command ls -lah'
fi

# Laravel/PHP.
alias a='php artisan'
alias art='php artisan'
alias pest='vendor/bin/pest'
alias pint='vendor/bin/pint'
alias stan='vendor/bin/phpstan analyse'

# Git.
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --decorate -12'
alias gp='git pull --ff-only'
alias gco='git checkout'
alias gsw='git switch'
''',

"config/zsh/conf.d/85-functions.zsh": r'''# Cria diretório e entra nele.
mkcd() {
  [[ -n "$1" ]] || { print -u2 'uso: mkcd <diretório>'; return 2; }
  command mkdir -p -- "$1" && builtin cd -- "$1"
}

# Extrai formatos comuns.
extract() {
  [[ -f "$1" ]] || { print -u2 "arquivo não encontrado: $1"; return 1; }
  case "$1" in
    *.tar.gz|*.tgz) command tar -xzf "$1" ;;
    *.tar.xz|*.txz) command tar -xJf "$1" ;;
    *.tar.bz2|*.tbz2) command tar -xjf "$1" ;;
    *.tar) command tar -xf "$1" ;;
    *.zip) command unzip "$1" ;;
    *.gz) command gunzip "$1" ;;
    *.xz) command unxz "$1" ;;
    *) print -u2 "formato não suportado: $1"; return 2 ;;
  esac
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
''',

"config/zsh/conf.d/90-starship.zsh": r'''# Prompt Starship em duas linhas.
(( $+commands[starship] )) && eval "$(starship init zsh)"
''',

"config/zsh/conf.d/99-highlighting.zsh": r'''# Syntax highlighting sempre por último.
for candidate in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  if [[ -r "$candidate" ]]; then
    source "$candidate"
    break
  fi
done
''',

"config/atuin/config.toml": r'''# Atuin · histórico local novo, sem import automático e sem sincronização.
auto_sync = false
update_check = false
enter_accept = false
secrets_filter = true
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 18
show_preview = true
show_help = true
workspaces = true

# Filtros adicionais. São defesa em profundidade, não garantia absoluta.
history_filter = [
  "(?i)^(export|setenv)\\b.*(password|passwd|token|secret|api[_-]?key|private[_-]?key)=",
  "(?i)^(printenv|env)([[:space:]]|$)",
  "(?i)(--password|--token|--api-key|--secret)(=|[[:space:]])",
  "(?i)\\b(cat|less|more|bat|head|tail|sed|awk|grep)[[:space:]].*\\.env([[:space:]]|$)",
  "(?i)(gh auth token|gcloud auth print-access-token|aws configure get|kubectl get secret|vault kv get|op read|pass show)",
  "(?i)^lerd[[:space:]]+(share:token|stripe:login)([[:space:]]|$)"
]

cwd_filter = [
  "^/home/[^/]+/\\.ssh(/|$)",
  "^/home/[^/]+/\\.gnupg(/|$)"
]
''',

"config/starship.toml": r'''"$schema" = "https://starship.rs/config-schema.json"

add_newline = true
command_timeout = 1000
scan_timeout = 30

# Duas linhas: contexto do projeto acima, cursor limpo abaixo.
format = """
[╭─](bold bright-black)$os$username$hostname$directory$php$nodejs$git_branch$git_status$fill$cmd_duration$status
[╰─](bold bright-black)$character"""

[fill]
symbol = " "

[os]
disabled = false
format = "[$symbol ]($style)"

[os.symbols]
Fedora = ""

[username]
show_always = false
style_user = "bold cyan"
format = "[$user]($style)"

[hostname]
ssh_only = true
style = "bold yellow"
format = "[@$hostname ]($style)"

[directory]
style = "bold blue"
truncation_length = 3
truncate_to_repo = true
read_only = " 󰌾"
format = "[$path]($style)[$read_only]($read_only_style) "

[php]
symbol = " "
format = "[$symbol$version]($style) "
style = "bold blue"

[nodejs]
symbol = " "
format = "[$symbol$version]($style) "
style = "bold green"

[git_branch]
symbol = " "
style = "bold purple"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold yellow"
format = "([$all_status$ahead_behind]($style) )"

[fill]
symbol = " "

[cmd_duration]
min_time = 2000
show_milliseconds = false
format = "[󱎫 $duration]($style) "
style = "dimmed white"

[status]
disabled = false
symbol = "✘ "
format = "[$symbol$status]($style) "
style = "bold red"
map_symbol = true
recognize_signal_code = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold yellow)"

[package]
disabled = true

[time]
disabled = true
''',

"install.sh": r'''#!/usr/bin/env bash
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
''',

"rollback.sh": r'''#!/usr/bin/env bash
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
''',

"doctor.sh": r'''#!/usr/bin/env bash
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
''',

"README.md": r'''# Zsh Professional · Fedora 45

**Versão:** 3.0.0

Ambiente Zsh modular para desenvolvimento PHP/Laravel no Fedora 45, integrado ao Lerd/fnm e com Atuin, FZF, Zoxide, Eza e Starship.

## O que este projeto entrega

- Zsh puro, sem Oh My Zsh, zplug ou framework.
- Lerd como primeira prioridade do `PATH`, preservando os shims de PHP, Composer e Node.
- Nenhuma inicialização manual do fnm: o roteamento de Node continua sob responsabilidade dos shims do Lerd.
- Atuin com histórico próprio, sem import automático e com sincronização desativada.
- Histórico nativo do Zsh como contingência.
- FZF para arquivos/diretórios; Atuin assume Ctrl+R.
- Zoxide para navegação por diretórios.
- Eza com aliases compatíveis.
- Autosuggestions e syntax highlighting dos pacotes Fedora.
- Starship em duas linhas, com diretório, Git, PHP, Node, duração e status do último comando.
- Configuração modular e diagnóstico/rollback.
- `.zshrc.local` preservado para aliases e ajustes exclusivos da máquina.

## Estrutura

```text
zsh-professional-fedora45-v3/
├── config/
│   ├── .zshenv
│   ├── .zshrc
│   ├── atuin/
│   │   └── config.toml
│   ├── starship.toml
│   └── zsh/
│       └── conf.d/
│           ├── 00-environment.zsh
│           ├── 10-options.zsh
│           ├── 20-history.zsh
│           ├── 30-completion.zsh
│           ├── 40-keybindings.zsh
│           ├── 45-autosuggestions.zsh
│           ├── 50-fzf.zsh
│           ├── 60-atuin.zsh
│           ├── 70-zoxide.zsh
│           ├── 80-aliases.zsh
│           ├── 85-functions.zsh
│           ├── 90-starship.zsh
│           └── 99-highlighting.zsh
├── install.sh
├── rollback.sh
├── doctor.sh
└── README.md
```

## Instalação

O instalador é **dry-run por padrão**. Primeiro, extraia o ZIP e entre na pasta do projeto.

```bash
chmod +x install.sh rollback.sh doctor.sh
./install.sh
```

Para instalar os pacotes Fedora e aplicar as configurações:

```bash
./install.sh --apply
```

Para uma instalação completa incluindo Starship pelo COPR:

```bash
./install.sh --apply --with-starship-copr
```

Para aplicar apenas as configurações, sem instalar pacotes:

```bash
./install.sh --apply --skip-packages
```

O instalador exige Fedora 45 e deve ser executado como usuário normal. O `sudo` é usado somente para operações DNF. O backup é criado antes da instalação dos pacotes e antes de substituir qualquer destino.

### O que o instalador não faz

- Não executa `chsh`, `usermod` nem altera `/etc/passwd`.
- Não modifica `.bashrc`, `.bash_profile`, `.profile` ou o shell padrão.
- Não apaga `~/.oh-my-zsh`, `~/.zplug` ou arquivos antigos.
- Não apaga `~/.zsh_history` nem importa esse histórico para Atuin.
- Não apaga `~/.zshrc.local`.
- Não instala nem baixa fontes. O ambiente já pode usar a JetBrainsMono Nerd Font instalada no sistema.

Após instalar, abra uma sessão de teste:

```bash
zsh
```

Para sair e voltar ao shell anterior:

```bash
exit
```

## Rollback

Restaurar o backup mais recente:

```bash
./rollback.sh
```

Restaurar um backup específico:

```bash
./rollback.sh ~/.local/state/zsh-professional/backups/AAAAmmdd-HHMMSS
```

Por segurança, o rollback padrão restaura apenas os arquivos. Para solicitar a remoção dos pacotes que estavam ausentes antes da instalação:

```bash
./rollback.sh --remove-packages
```

Para também avaliar a desativação do COPR `atim/starship`, caso tenha sido habilitado por esta instalação:

```bash
./rollback.sh --restore-copr
```

As duas operações são independentes e exigem confirmação.

## Diagnóstico

```bash
./doctor.sh
```

Dentro de uma sessão Zsh, confira também a resolução dos executáveis:

```zsh
type -a php node npm npx composer lerd
php --version
node --version
npm --version
composer --version
whence -v _lerd _openchamber _copilot
atuin doctor
```

Em projetos Node, deixe o Lerd resolver a versão indicada por `.node-version` ou `.nvmrc`. Não adicione `eval "$(fnm env --use-on-cd)"` à configuração.

## Atalhos

| Tecla | Ação |
|---|---|
| Ctrl+R | Busca do Atuin |
| Ctrl+T | FZF para arquivos |
| Alt+C | FZF para diretórios |
| Tab | Autocompletar do Zsh |
| Seta para cima | Histórico nativo |
| Ctrl+Espaço | Aceita sugestão, se o terminal enviar esse atalho |
| Ctrl+seta esquerda/direita | Navegação por palavra |

## Aliases e funções

| Comando | Ação |
|---|---|
| `a` / `art` | `php artisan` |
| `pest` | `vendor/bin/pest` |
| `pint` | `vendor/bin/pint` |
| `stan` | `vendor/bin/phpstan analyse` |
| `gs` | Git status resumido |
| `gd` | Git diff |
| `gl` | Git log compacto |
| `mkcd pasta` | Cria a pasta e entra nela |
| `extract arquivo` | Extrai formatos comuns |
| `croot` | Vai para a raiz do repositório Git |

Os aliases anteriores que não foram incluídos no material recebido devem ser migrados manualmente para `~/.zshrc.local`. O instalador preserva esse arquivo e o carrega depois dos módulos padrão.

## PATH e Lerd

A prioridade é deliberada:

1. `~/.local/share/lerd/bin`
2. `~/.local/bin`
3. `~/.cargo/bin`
4. `~/bin`
5. Composer global, pnpm, Bun e LM Studio, quando presentes
6. Demais diretórios herdados do sistema.

O `.zshenv` é mínimo porque é carregado também em shells não interativos. Plugins, prompt, Atuin, FZF e completions ficam no `.zshrc`.

## Histórico e segurança

Atuin começa sem importar o histórico anterior e com sincronização desativada. `secrets_filter` e `history_filter` ajudam a evitar gravação de comandos sensíveis, mas **não garantem proteção absoluta**. Evite colocar senhas, tokens e chaves diretamente nos argumentos dos comandos. Prefira variáveis de ambiente, arquivos com permissões restritas e gerenciadores de segredos.

## Validação

Os scripts Bash são validados com `bash -n`; os arquivos TOML são validados sintaticamente. A validação final da sintaxe Zsh deve ser executada no Fedora 45 com `./doctor.sh`, pois o ambiente de empacotamento não substitui o interpretador Zsh da máquina de destino.

## Documentação oficial

- Zsh: https://zsh.sourceforge.io/Doc/
- Atuin: https://docs.atuin.sh/
- FZF: https://github.com/junegunn/fzf
- Zoxide: https://github.com/ajeetdsouza/zoxide
- Eza: https://github.com/eza-community/eza
- Starship: https://starship.rs/guide/
- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
'''
}

for rel, content in files.items():
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")

for script in ("install.sh", "rollback.sh", "doctor.sh"):
    (root / script).chmod(0o755)

# Correct duplicate TOML table: [fill] is declared once only.
starship_path = root / "config/starship.toml"
starship_text = starship_path.read_text(encoding="utf-8")
first_fill = '[fill]\nsymbol = " "\n\n'
second_fill = '[fill]\nsymbol = " "\n\n'
# Remove the later repeated block if it occurs twice.
pos1 = starship_text.find(first_fill)
pos2 = starship_text.find(second_fill, pos1 + len(first_fill))
if pos2 != -1:
    starship_text = starship_text[:pos2] + starship_text[pos2 + len(second_fill):]
starship_path.write_text(starship_text, encoding="utf-8")

# Static validations.
tomllib.loads((root / "config/atuin/config.toml").read_text(encoding="utf-8"))
tomllib.loads((root / "config/starship.toml").read_text(encoding="utf-8"))

for script in ("install.sh", "rollback.sh", "doctor.sh"):
    result = subprocess.run(["bash", "-n", str(root / script)], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"Bash syntax error in {script}: {result.stderr}")

# Ensure installer never changes the default shell and doesn't invoke unsafe remote pipe.
install_text = (root / "install.sh").read_text(encoding="utf-8")
assert "chsh" not in install_text
assert "usermod" not in install_text
assert "curl" not in install_text
assert "fnm env" not in install_text

zip_path = Path("zsh-professional-fedora45-v3.zip")
if zip_path.exists():
    zip_path.unlink()
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(root.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(root.parent))

digest = hashlib.sha256(zip_path.read_bytes()).hexdigest()
print("Projeto Zsh Professional Fedora 45 v3.0.0 criado.")
print(f"Arquivos: {sum(1 for p in root.rglob('*') if p.is_file())}")
print(f"ZIP: {zip_path}")
print(f"Tamanho: {zip_path.stat().st_size:,} bytes")
print(f"SHA256: {digest}")
print("Validações: bash -n (3 scripts) OK; TOML (Atuin e Starship) OK.")
