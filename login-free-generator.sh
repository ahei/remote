#!/usr/bin/env bash

# Time-stamp: <2017-09-12 22:02:49 Tuesday by ahei>

# @file login-free-generator.sh
# @version 1.0
# @author ahei

readonly PROGRAM_NAME="login-free-generator.sh"
readonly PROGRAM_VERSION="1.0.0"

usage()
{
    local code=1
    local redirect
    
    if [ $# -gt 0 ]; then
        code="$1"
    fi

    if [ "$code" != 0 ]; then
        redirect="1>&2"
    fi

    eval cat "$redirect" << EOF
usage: ${PROGRAM_NAME} [OPTIONS]

Options:
    -v  Output version info.
    -h  Output this help.
EOF

    exit "$code"
}

options=":hv"
eval set -- $(getopt -o "$options" -- "$@")
while getopts "$options" OPT; do
    case "$OPT" in
        v)
            version
            ;;

        h)
            usage 0
            ;;

        :)
            case "${OPTARG}" in
                ?)
                    echoe "Option \`-${OPTARG}' need argument.\n"
                    usage
            esac
            ;;

        ?)
            echoe "Invalid option \`-${OPTARG}'.\n"
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

keyFile=$(mktemp key.XXXXXX -u)
ssh-keygen -t rsa -f "$keyFile" -N "" -q

cat <<EOFOUTER
chmod 755 ~
cd
mkdir -p .ssh
chmod 700 .ssh
cd .ssh

cp id_rsa.pub id_rsa.pub.bak
cp id_rsa id_rsa.bak

cat > id_rsa.pub <<EOF
$(cat $keyFile.pub)
EOF
cat > id_rsa <<EOF
$(cat $keyFile)
EOF
/bin/cat id_rsa.pub >> authorized_keys
chmod 600 authorized_keys id_rsa
EOFOUTER

rm -rf "$keyFile" "$keyFile.pub"
