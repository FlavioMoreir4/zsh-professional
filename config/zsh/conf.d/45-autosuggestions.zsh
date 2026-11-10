# O Atuin acrescenta sua estratégia automaticamente após ser inicializado.
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
typeset -ga ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(history)

for _zsh_autosuggest_file in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
do
  if [[ -r "$_zsh_autosuggest_file" ]]; then
    source "$_zsh_autosuggest_file"
    break
  fi
done
unset _zsh_autosuggest_file

# Ctrl+Espaço (NUL) quando o terminal envia ^@.
if (( $+widgets[autosuggest-accept] )); then
  bindkey '^@' autosuggest-accept
fi
