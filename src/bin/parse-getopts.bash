# Parse command line options

[ "$(type -t die)" = function ] || . util-helpers.bash

__parse_getopts__() {
  local _kw _w1 _w2 _rest _opt _arg _pk _opts _getopts=:
  local -A _optk _optv _optd
  local -a _argk _argv _argd
  while read _kw _w1 _w2 _rest; do
    [[ ${#_argk[@]} > 0 ]] && _pk=${_argk[-1]} || _pk="${_kw-}" 
    case ${_kw-} in
      onoff) _opt="${_w1-}"; _opt=${_opt#-};_arg="${_w2-}"; _opts="$_opt";;
      value|array) _opt="${_w1-}"; _opt=${_opt#-};_arg="${_w2-}"; _opts="$_opt:";;
      required) _arg="${_w1-}"; _opts=@; [[ $_pk = $_kw ]] || die 70 "argument '$_kw $_arg ${_w2-} ${_rest-}' cannot follow a $_pk argument";;
      optional) _arg="${_w1-}"; _opts=@; [[ $_pk = trailing ]] && die 70 "argument '$_kw $_arg ${_w2-} ${_rest-}' cannot follow a $_pk argument";;
      trailing) _arg="${_w1-}"; _opts=@;;
      *) die 70 "bad specification '${_kw-}' in '${_kw-} ${_w1-} ${_w2-} ${_rest-}'";;
    esac
    [[ "$_arg" =~ ^[[:alpha:]][_[:alnum:]]*$ ]] || die 70 "bad variable name '$_arg' in '$_kw ${_w1-} ${_w2-} ${_rest-}'"
    if [[ $_opts = @ ]]; then
      _argk+=($_kw); _argv+=($_arg); _argd+=("${_w2-}${_rest+ $_rest}")
    elif [[ ${#argk[@]} > 0 ]]; then
      die 70 "option '${_w1-}' in '$_kw ${_w1-} ${_w2-} ${_rest-}' cannot follow arguments"
    elif ! [[ "${_w1-}" =~ ^[-][[:alnum:]]$ ]]; then
      die 70 "bad option '${_w1-}' in '$_kw ${_w1-} ${_w2-} ${_rest-}'"
    elif [[ -v _optk[$_opt] ]]; then
      die 70 "option '$_w1' in '$_kw $_w1 $_arg ${_rest-}' clashes with '${_optk[$_opt]} $_w1 ${_optv[$_opt]} ${_optd[$_opt]}'"
    else
      _optk[$_opt]=$_kw; _optv[$_opt]=$_arg; _optd[$_opt]="${_rest-}"; _getopts+=$_opts;
    fi
  done
  if ! [[ -v _optk[h] ]] ; then
    _optk[h]=help; _getopts+=h
  fi
  while getopts $_getopts _opt; do
    if [[ : = "$_opt" ]]; then
      die 64 "argument after -$OPTARG missing"
    elif [[ '?' = "$_opt" ]]; then
      die 64 "unrecognized option -$OPTARG"
    elif [[ help = ${_optk[$_opt]} ]]; then
      __usage__ _optk _optv _optd _argk _argv _argd
      exit 0
    else
      local -n _var=${_optv[$_opt]}
      case ${_optk[$_opt]} in
        onoff) _var=;;
        value) _var="$OPTARG";;
	array) _var+=("$OPTARG");;
      esac
    fi
  done
  shift $((OPTIND - 1))
  for _arg in "${!_argv[@]}"; do
    _kw=${_argk[$_arg]}
    local -n _var=${_argv[$_arg]}
    if [[ trailing = $_kw ]]; then
      _var+=("$@") ; break
    elif [[ $# = 0 && required = $_kw ]]; then
      warn "required argument ${_argv[$_arg]^^} missing"
      __usage__ _optk _optv _optd _argk _argv _argd 1>&2
      exit 64
    else
      _var="$1"
    fi
    shift
  done
}

__usage__() {
  local -n _optkw=$1 _optvar=$2 _optdoc=$3 _argkw=$4 _argvar=$5 _argdoc=$6
  local _opt _arg _pend _name _w _maxw=0
  echo -n "${0##*/}: [OPTIONS]"
  for _opt in "${!_optvar[@]}"; do
    _name=${_optvar[$_opt]}; [[ ${_optkw[$_opt]} = onoff ]] && _w=-1 || _w=${#_name}
    (( 3 + _w > _maxw && (_maxw = 3 + _w) ))
  done
  for _arg in "${!_argvar[@]}"; do
    _name=${_argvar[$_arg]^^}; _w=${#_name}
    case ${_argkw[$_arg]} in
      required) echo -n " $_name";;
      optional) echo -n " [$_name"; _pend+=']';;
      trailing) echo -n " [$_name...]";;
    esac
    (( _w > _maxw && (_maxw = _w) ))
  done
  echo $_pend
  for _opt in $(printf '%s\n' "${!_optkw[@]}" | sort); do
    case ${_optkw[$_opt]} in
      help) printf "  %-${_maxw}s  help\n" "-h";;
      onoff) printf "  %-${_maxw}s  ${_optdoc[$_opt]}\n" "-$_opt";;
      value) printf "  %-${_maxw}s  ${_optdoc[$_opt]}\n" "-$_opt ${_optvar[$_opt]^^}";;
      array) printf "  %-${_maxw}s  ${_optdoc[$_opt]} (repeatable)\n" "-$_opt ${_optvar[$_opt]^^}";;
    esac
  done
  for _arg in "${!_argvar[@]}"; do
    printf "  %-${_maxw}s  ${_argdoc[$_arg]}\n" ${_argvar[$_arg]^^}
  done
}

__parse_getopts__ "$@"
unset -f __parse_getopts__ __usage__
