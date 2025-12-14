###############
## .bashrc   ##
###############



# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


#####################
### CUSTOM PROMPT ###
#####################
PS1='\[\033[01;32m\]\u\[\033[01;31m\]@\[\033[38;5;135m\]\h\[\033[01;31m\]:\[\033[01;33m\]\w\[\033[00m\] '

###################
### MY ALIASES  ###
###################

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
