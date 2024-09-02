alias sudo='sudo ' # allows using aliases after sudo

# enable color support of ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    # ls
    alias ll='ls --color=auto -alFh'
    alias la='ls --color=auto -A'
    alias l='ls --color=auto -CF'

    # grep
    alias grep='grep --color=auto'
    alias zgrep='zgrep --color=auto'
fi

# avoid mistakes
alias cp='cp -i'
alias mv='mv -i'
#alias rm='rm -i'

# Add an "alert" alias for long running commands. Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Git aliases are handled by git and set in `~/.gitconfig`.

