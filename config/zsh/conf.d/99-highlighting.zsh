# Syntax highlighting sempre por último.
for candidate in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  if [[ -r "$candidate" ]]; then
    source "$candidate"
    break
  fi
done
