# Zsh Professional: ambiente mínimo para shells interativos e não interativos.
# Não inicialize plugins, prompt, Atuin, FZF ou widgets neste arquivo.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export ATUIN_CONFIG_DIR="${XDG_CONFIG_HOME}/atuin"
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship.toml"

typeset -U path PATH

# Remove Herd Lite do PATH herdado sem apagar arquivos.
typeset -a _zsh_clean_path
typeset _zsh_path_entry
for _zsh_path_entry in "${path[@]}"; do
  [[ "$_zsh_path_entry" == "$HOME/.config/herd-lite/bin" ]] && continue
  [[ -n "$_zsh_path_entry" ]] && _zsh_clean_path+=("$_zsh_path_entry")
done
path=("${_zsh_clean_path[@]}")
unset _zsh_clean_path _zsh_path_entry

# Construir PATH em ordem explícita: o Lerd sempre permanece primeiro.
typeset -a _zsh_preferred_path
_zsh_preferred_path=(
  "$HOME/.local/share/lerd/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/bin"
)

# Diretórios opcionais, sempre depois dos shims Lerd.
[[ -d "$HOME/.config/composer/vendor/bin" ]] && _zsh_preferred_path+=("$HOME/.config/composer/vendor/bin")
[[ -d "$HOME/.local/share/pnpm" ]] && _zsh_preferred_path+=("$HOME/.local/share/pnpm")
[[ -d "$HOME/.bun/bin" ]] && _zsh_preferred_path+=("$HOME/.bun/bin")
[[ -d "$HOME/.lmstudio/bin" ]] && _zsh_preferred_path+=("$HOME/.lmstudio/bin")
[[ -d /home/linuxbrew/.linuxbrew/bin ]] && _zsh_preferred_path+=(/home/linuxbrew/.linuxbrew/bin)

path=("${_zsh_preferred_path[@]}" /usr/local/bin /usr/bin "${path[@]}")
unset _zsh_preferred_path

typeset -U path PATH
export PATH
