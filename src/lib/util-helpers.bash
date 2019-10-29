# Assorted helpers for Bash utility scripts

warn() { echo "${0##*/}:" "${@}" 1>&2 ; }
