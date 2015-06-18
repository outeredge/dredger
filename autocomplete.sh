_dredger() {
    COMPREPLY=($(compgen -W "$(make -f /usr/local/dredger/Makefile -pRrq : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($1 !~ "^[#.]") {print $1}}' | egrep -v '^[^[:alnum:]]' | sort | xargs)" -- "${COMP_WORDS[$COMP_CWORD]}"));
}
complete -F _dredger dredger
