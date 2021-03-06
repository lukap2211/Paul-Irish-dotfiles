[ -n "$PS1" ] && source ~/.bash_profile


[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [[ "${-}" =~ i ]]
then
  source "${HOME}/.bash-proxy-config/include/alias.sh"
else
  source "${HOME}/.bash-proxy-config/include/fn.sh"
  export -f proxy
fi
