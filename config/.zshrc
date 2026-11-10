# Zsh Professional · Fedora 45
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
