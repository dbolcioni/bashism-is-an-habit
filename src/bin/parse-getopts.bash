# Parse command line options

[ "$(type -t die)" = function ] || . util-helpers.bash

__parse_getopts__() {
  local _opt _reqa _opta _u _p _w _mw=0 _gopts=: _opts=":) badarg missing argument for -\$OPTARG ;;\\?) badarg unknown option -\$OPTARG;;"
  local -A _optk _optv _optd _ko=([flag]= [required]= [optional]= [trailing]=)
  local -a _argk _argv _argd
  while read; do
    if [[ "$REPLY" =~ ^[[:blank:]]*(onoff|value|array)[[:blank:]]+-[[:alnum:]][[:blank:]]+[[:alpha:]][_[:alnum:]]*.*$ ]]; then
        set -- $REPLY
	[[ ${_ko[flag]} ]] && die 70 "bad specification '$REPLY', options must precede arguments"
	_opt=${2#-}
	[[ -v _optk[$_opt] ]] && die 70 "option '$_opt' in '$REPLY' clashes with '${_optk[$_opt]} -$_opt ${_optv[$_opt]} ${_optd[$_opt]}'"
	case $1 in
	  onoff) _opts+="$_opt) $3= ;;"; _gopts+=$_opt; _w=-1 ;;
	  value) _opts+="$_opt) $3=\"\$OPTARG\" ;;"; _gopts+=$_opt:; _w=${#3} ;;
	  array) _opts+="$_opt) $3+=(\"\$OPTARG\") ;;"; _gopts+=$_opt:; _w=${#3} ;;
	esac
        _optk[$_opt]=$1; _optv[$_opt]=$3; _optd[$_opt]="${*:4}"; (( 3 + _w > _mw && (_mw = 3 + _w) ))
    elif [[ "$REPLY" =~ ^[[:blank:]]*(required|optional|trailing)[[:blank:]]+[[:alpha:]][_[:alnum:]]*.*$ ]]; then
	set -- $REPLY
	[[ ${_ko[$1]} ]] && die 70 "argument '$REPLY' cannot follow ${_argk[-1]} argument ${_argv[-1]^^}"
	case $1 in
	  required) _reqa+=" $2"; _u+=" ${2^^}";;
	  optional) _opta+=" $2"; _u+=" [${2^^}"; _p+=];  _ko[required]=1 ;;
	  trailing) _u+=" [${2^^}...]$_p"; _ko[required]=1; _ko[optional]=1; _ko[trailing]=1 ;;
	esac
        _argk+=($1); _argv+=($2); _argd+=("${*:3}"); _ko[flag]=1; (( _w > _mw && (_mw = _w) ))
    else
      die 70 "bad specification '$REPLY'"
    fi
  done
  echo "{ usage() { echo \"Usage: \${0##*/} [OPTIONS]\"\"$_u\";"
  for _opt in $(printf '%s\n' "${!_optk[@]}" | sort); do
    case ${_optk[$_opt]} in
      help) printf "echo '  %-${_mw}s  help';" "-h";;
      onoff) printf "echo '  %-${_mw}s  ${_optd[$_opt]}';" "-$_opt";;
      value) printf "echo '  %-${_mw}s  ${_optd[$_opt]}';" "-$_opt ${_optv[$_opt]^^}";;
      array) printf "echo '  %-${_mw}s  ${_optd[$_opt]} (repeatable)';" "-$_opt ${_optv[$_opt]^^}";;
    esac
  done
  for _arg in "${!_argv[@]}"; do
    printf "echo '  %-${_mw}s  ${_argd[$_arg]}';" ${_argv[$_arg]^^}
  done
  _reqa="for REPLY in $_reqa; do [[ \$# = 0 ]] && badarg required argument \${REPLY^^} missing; printf -v \$REPLY \"\$1\"; shift; done"
  _opta="for REPLY in $_opta; do [[ \$# = 0 ]] && break; printf -v \$REPLY \"\$1\"; shift; done"
  if ! [[ -v _optk[h] ]] ; then
    _optk[h]=help; _gopts+=h; _opts+="h) usage; exit 0;;"
  fi
  echo "}; badarg() { warn \"\$@\"; usage 1>&2; exit 64; };"
  echo "while getopts $_gopts REPLY; do case \$REPLY in $_opts esac; done; shift \$((OPTIND - 1)); $_reqa; $_opta; }"
}

eval "$(__parse_getopts__)"
unset -f __parse_getopts__
