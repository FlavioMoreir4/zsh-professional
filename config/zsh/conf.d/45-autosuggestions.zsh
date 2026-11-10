# Plugin fornecido pelo pacote Fedora zsh-autosuggestions.
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
