# Assorted helpers for Bash utility scripts

warn() { echo "${0##*/}:" "$@" 1>&2 ; }
die() { local rc="$1"; shift; warn "$@"; exit "$rc"; }
