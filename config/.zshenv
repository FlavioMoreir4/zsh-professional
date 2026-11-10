# Zsh Professional · ambiente mínimo
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
