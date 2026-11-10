# Syntax highlighting deve ser o último plugin/widget do ZLE.
for _zsh_highlight_file in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  if [[ -r "$_zsh_highlight_file" ]]; then
    source "$_zsh_highlight_file"
    break
  fi
done
unset _zsh_highlight_file
