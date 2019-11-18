# Parse command line options

[ "$(type -t die)" = function ] || . util-helpers.bash

__parse_getopts__() {
  local _kw _opt _arg _rest _optstr=:
  local -A _optk _optv _optd
  local -a _argk _argv _argd
  while read _kw _opt _arg _rest; do
    case ${_kw-} in
      onoff) _optstr+=${_opt-};;
      value|array) _optstr+=${_opt-}:;;
      required|optional|trailing) break;;
      *) die 70 "bad specification '${_kw-}' in '${_kw-} ${_opt-} ${_arg-} ${_rest-}'";;
    esac
    [[ ${_opt-} =~ ^[-][[:alnum:]]$ ]] || die 70 "bad option '${_opt-}' in '$_kw ${_opt-} ${_arg-} ${_rest-}'"
    [[ ${_arg-} =~ ^[[:alpha:]][_[:alnum:]]*$ ]] || die 70 "bad variable name '${_arg-}' in '$_kw $_opt ${_arg-} ${_rest-}'"
    _opt=${_opt#-}
    [[ -v _optk[$_opt] ]] && die 70 "option '-$_opt' in '$_kw- -$_opt $_arg ${_rest-}' conflicts with '${_optk[$_opt]} -$_opt ${_optv[$_opt]} ${_optd[$_opt]}'"
    _optk[$_opt]=$_kw; _optv[$_opt]=$_arg; _optd[$_opt]="${_rest-}"
  done
  _rest="${_arg-}${_rest+ $_rest}"
  _arg=${_opt-}
  local _prev=${_kw-}
  while true; do
    [[ ${_arg-} =~ ^[[:alpha:]][_[:alnum:]]*$ ]] || die 70 "bad variable name '${_arg-}' in '${_kw-} ${_arg-} ${_rest-}'"
    [[ ${#_argk[@]} > 0 ]] && _prev=${_argk[-1]}
    case ${_kw-} in
      required) [[ $_prev != $_kw ]] && die 70 "$_kw argument '$_arg' in '$_kw $_arg ${_rest-}' cannot follow non required arguments";;
      optional|trailing) [[ trailing = $_prev ]] && die 70 "$_kw argument '$_arg' in '$_kw $_arg ${_rest-}' cannot follow the trailing argument";;
      *) die 70 "bad specification '${_kw-}' in '${_kw-} $_arg ${_rest-}'";;
    esac
    _argk+=($_kw); _argv+=($_arg); _argd+=("${_rest-}")
    read _kw _arg _rest || break
  done
  if ! [[ -v _optk[h] ]] ; then
    _optk[h]=help; _optstr+=h
  fi
  while getopts $_optstr _opt; do
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
