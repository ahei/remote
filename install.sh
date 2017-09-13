#!/bin/bash

# Time-stamp: <2017-09-13 14:23:11 Wednesday by ahei>

readonly PROGRAM_NAME="install.sh"
readonly PROGRAM_VERSION="1.0"

home=`dirname "$0"`
home=`cd "$home"; pwd`

# echo to stderr
echoe()
{
    printf "$*\n" 1>&2
}

usage()
{
    code=1
    if [ $# -gt 0 ]; then
        code="$1"
    fi

    if [ "$code" != 0 ]; then
        redirect="1>&2"
    fi

    eval cat "$redirect" << EOF
usage: ${PROGRAM_NAME} [OPTIONS] [<INSTALL_DIR>]

INSTALL_DIR default is /usr/bin.

Options:
    -p <PROFILE>
        PROFILE defualt is /etc/profile.
    -v  Output version info.
    -h  Output this help.
EOF

    exit "$code"
}

writeToFile()
{
    line="$1"
    dst="$2"

    if ! grep -qFx "${line}" "$dst"; then
        printf "\n$line" >> "$dst"
    fi
}

if [ "$USER" = root ]; then
    profile="/etc/profile"
else
    profile=~/.bashrc
fi

while getopts ":hvp:" OPT; do
    case "$OPT" in            
        p)
            profile="$OPTARG"
            ;;
            
        h)
            usage
            ;;

        :)
        case "${OPTARG}" in
            ?)
                echoe "Option \`-${OPTARG}' need argument.\n"
                usage 0
        esac
        ;;

        ?)
            echoe "Invalid option \`-${OPTARG}'.\n"
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

writeToFile "export PATH=$home:"'$PATH' $profile
writeToFile 'alias rcp="remote -c"' $profile
writeToFile 'alias rssh=remote' $profile
