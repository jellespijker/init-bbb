#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -alh'

PS1='[\u@\h \W]\$ '

export VISUAL="atom"
export CMAKE_MODULE_PATH=/usr/share/cmake/Modules
