# Parse command line options

[ "$(type -t die)" = function ] || . util-helpers.bash

__parse_getopts__() {
  local _kw _first _second _rest _optstr=: _opt _arg
  local -A _optv _optk _optd
  local -a _argv _argk _argd
  while read _kw _first _second _rest; do
    case ${_kw-} in
      onoff) __doopt__ _optk _optv _optd _optstr $_kw "${_first-}" "${_second-}" "${_rest-}";;
      value) __doopt__ _optk _optv _optd _optstr $_kw "${_first-}" "${_second-}" "${_rest-}"; _optstr+=:;;
      array) __doopt__ _optk _optv _optd _optstr $_kw "${_first-}" "${_second-}" "${_rest-}"; _optstr+=:;;
      required) __doarg__ _argk _argv _argd $_kw "${_first-}" "${_second-}${_rest+ $_rest}";;
      optional) __doarg__ _argk _argv _argd $_kw "${_first-}" "${_second-}${_rest+ $_rest}";;
      trailing) __doarg__ _argk _argv _argd $_kw "${_first-}" "${_second-}${_rest+ $_rest}";;
      *) die 70 "bad specification '${_kw-}' in '${_kw-} ${_first-} ${_second-} ${_rest-}'";;
    esac
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

__doopt__() { # @KW @VAR @DOC @GETOPTS KW -O VAR DOC 
  local _opt
  [[ $6 =~ [-][[:alnum:]] ]] || die 70 "bad option '$6' in '${@:5}'"
  _opt=${6#-}
  [[ $7 =~ [[:alpha:]][_[:alnum:]]* ]] || die 70 "bad variable name '$7' in '${@:5}"
  local -n _kw=$1 _var=$2 _doc=$3 _str=$4
  [[ -v var[$_opt] ]] && die 70 "option '$6' in '${@:5}' conflicts with '${_kw[$_opt]} $6 ${_var[$_opt]} ${_doc[$_opt]}'"
  _kw[$_opt]=$5; _var[$_opt]=$7; _doc[$_opt]="$8"
  _str+=$_opt
}

__doarg__() { # @KW @VAR @DOC KW VAR DOC
  [[ $5 =~ [[:alpha:]][_[:alnum:]]* ]] || die 70 "bad variable name '$5' in '${@:4}"
  local -n _kw=$1 _var=$2 _doc=$3
  local _prev=$4
  [[ ${#_kw[@]} > 0 ]] && _prev=${_kw[-1]}
  [[ required = $4 && $_prev != $4 ]] && die 70 "$4 argument '$5' in '${@:4}' cannot follow non required arguments"
  [[ optional = $4 && trailing = $_prev ]] && die 70 "$4 argument '$5' in '${@:4}' cannot follow the trailing argument"
  _kw+=($4); _var+=($5); _doc+=("$6")
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
  for _opt in "${!_optvar[@]}"; do
    case ${_optkw[$_opt]} in
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
unset -f __parse_getopts__ __doopt__ __doarg__ __usage__
