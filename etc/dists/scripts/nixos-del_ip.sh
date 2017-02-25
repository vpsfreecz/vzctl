#!/bin/bash

# Adds IP address from a Nixos container

PATH=$PATH:/run/current-system/sw/bin
VENET_DEV=venet0
IP=ip
IFCFG=/ifcfg

function clear_ip()
{
    local cfg="$IFCFG"
    local ip="$1"
    local f

    for f in start stop; do
        grep -v "${ip}/" "${cfg}.${f}" > "${cfg}.${f}.new"
        mv "${cfg}.${f}.new" "${cfg}.${f}"
    done

}


function del_ip()
{
    local ipm

    for ipm in ${IP_ADDR}; do
        clear_ip "$ipm"

        if [ "${ipm#*:}" = "${ipm}" ] ; then
            $IP addr del $ipm/32 dev $VENET_DEV
        else
            $IP -6 addr del $ipm/128 dev $VENET_DEV
        fi
    done
}

del_ip
exit 0
# end of script
