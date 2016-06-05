#!/bin/bash
#  Copyright (C) 2000-2008, Parallels, Inc. All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# Adds IP address in a container running Slackware.
# Note that this script requires /etc/rc.d/rc.venet to be present.

VENET_DEV=venet0
IFCFG_DIR=/etc/rc.d
IFCFG=${IFCFG_DIR}/rc.venet
HOSTFILE=/etc/hosts
IP=/sbin/ip

function setup_network()
{
	mkdir -p ${IFCFG_DIR}
	# Set up /etc/hosts
	if [ ! -f ${HOSTFILE} ]; then
		echo "127.0.0.1 localhost.localdomain localhost" > $HOSTFILE
	fi

	echo "$IP link set up dev $VENET_DEV" > "${IFCFG}.start"
	echo "$IP route add default dev $VENET_DEV" >> "${IFCFG}.start"
	echo "$IP -6 route add default dev $VENET_DEV" >> "${IFCFG}.start"

	echo "$IP link set down dev $VENET_DEV" > "${IFCFG}.stop"
}

function add_ip()
{
	if [ ! -f "$IFCFG" ] ; then
		echo "Unable to add ip: '$IFCFG' does not exist"
		exit 1
	fi

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
