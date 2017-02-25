#!/bin/sh

# Sets user:passwd in a container, adding user if necessary.

export PATH=$PATH:/run/current-system/sw/bin
CFGFILE="/etc/passwd"

set_serrpasswd()
{
    local userpw="$1"
    local user=$(echo $userpw | sed 's/:.*$//')
    local passwd=$(echo $userpw | sed 's/^[^:]*://')

    if [ -z "${user}" -o  -z "${passwd}" ]; then
        exit $VZ_CHANGEPASS
    fi
    if [ ! -c /dev/urandom ]; then
        mknod /dev/urandom c 1 9 > /dev/null
    fi
    if ! grep -E "^${user}:" ${CFGFILE} 2>&1 >/dev/null; then
        useradd -m "${user}" 2>&1 || exit $VZ_CHANGEPASS
    fi
    echo "${passwd}" | passwd --stdin "${user}" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "${user}:${passwd}" | chpasswd 2>&1 || exit $VZ_CHANGEPASS
    fi
}

[ -z "${USERPW}" ] && return 0
set_serrpasswd "${USERPW}"
echo "Warning: password and user changes are not persistent on nixos"

exit 0
