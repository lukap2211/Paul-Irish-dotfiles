function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '%F{240}(±) %F{250}$' && return
    echo '$'
}

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

PROMPT="%B%F{9}%n%b"                               # username
PROMPT+="%F{240} at "                              # at
PROMPT+="%B%F{172}%m%b"                            # machine
PROMPT+="%F{240} in "                              # in
PROMPT+="%B%F{190}%~%b"                            # working directory
PROMPT+='%{$reset_color%}$(git_prompt_info)
$(virtualenv_info)$(prompt_char) '                 # git repository details


ZSH_THEME_GIT_PROMPT_PREFIX="%F{240} on %B%F{141}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%b"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{37}*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{37}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""
