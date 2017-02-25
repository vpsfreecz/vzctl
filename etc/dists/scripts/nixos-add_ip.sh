#!/bin/bash

# Adds IP address in a Nixos container
# via /ifcfg.{start,stop} shell script(s) loaded by systemd service

export PATH=$PATH:/run/current-system/sw/bin
VENET_DEV=venet0
#HOSTFILE=/etc/hosts
IP=ip
IFCFG=/ifcfg

function setup_network()
{
    # Set up /etc/hosts
        echo "Setup network"
    #if [ ! -f ${HOSTFILE} ]; then
    #   echo "127.0.0.1 localhost.localdomain localhost" > $HOSTFILE
    #fi

    echo "$IP link set up dev $VENET_DEV" > "${IFCFG}.start"
    echo "$IP route add default dev $VENET_DEV" >> "${IFCFG}.start"
    echo "$IP -6 route add default dev $VENET_DEV" >> "${IFCFG}.start"
        #echo "echo > ${IFCFG}.done" >> "${IFCFG}.start"


    echo "$IP link set down dev $VENET_DEV" > "${IFCFG}.stop"
        echo "/Setup network"
}

function add_ip()
{
    # In case we are starting CT
    if [ "x${VE_STATE}" = "xstarting" ]; then
        setup_network
    fi

    local ipm
    for ipm in ${IP_ADDR}; do
        local cmd

        if [ "${ipm#*:}" = "${ipm}" ] ; then
            cmd="$IP addr add $ipm/32 dev $VENET_DEV"
            echo "$cmd" >> "${IFCFG}.start"
            echo "$IP addr del $ipm/32 dev $VENET_DEV" >> "${IFCFG}.stop"
        else
            cmd="$IP -6 addr add $ipm/128 dev $VENET_DEV"
            echo "$cmd" >> "${IFCFG}.start"
            echo "$IP -6 addr del $ipm/128 dev $VENET_DEV" >> "${IFCFG}.stop"
        fi

        if [ "x${VE_STATE}" != "xstarting" ] ; then
            $cmd

            if [ "${ipm#*:}" = "${ipm}" ] ; then
                if ! ($IP route list | grep -q "default dev $VENET_DEV") ; then
                    $IP route add default dev $VENET_DEV
                fi
            else
                if ! ($IP -6 route list | grep -q "default dev $VENET_DEV") ; then
                    $IP -6 route add default dev $VENET_DEV
                fi
            fi
        fi
    done
}

add_ip
exit 0
# end of script
