# Zsh Professional: loader interativo.
[[ -o interactive ]] || return 0

typeset -g ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Preparar fpath antes do compinit.
[[ -r "$ZSH_CONFIG_DIR/conf.d/00-environment.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/conf.d/00-environment.zsh"

# Extensão pessoal: não é sobrescrita pelo instalador.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Ordem explícita, evitando carregamento duplicado.
typeset -a _zsh_professional_modules
_zsh_professional_modules=(
  10-options.zsh
  20-history.zsh
  30-completion.zsh
  40-keybindings.zsh
  45-autosuggestions.zsh
  50-fzf.zsh
  60-atuin.zsh
  70-zoxide.zsh
  80-aliases.zsh
  85-functions.zsh
  90-starship.zsh
  99-highlighting.zsh
)

typeset _zsh_professional_module
for _zsh_professional_module in "${_zsh_professional_modules[@]}"; do
  [[ -r "$ZSH_CONFIG_DIR/conf.d/$_zsh_professional_module" ]] &&
    source "$ZSH_CONFIG_DIR/conf.d/$_zsh_professional_module"
done

unset _zsh_professional_modules _zsh_professional_module
