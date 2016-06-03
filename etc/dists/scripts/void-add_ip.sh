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
# Adds IP address in a container running Void Linux.

VENET_DEV=venet0
IFCFG=/etc/runit/core-services/90-venet.sh
IP=/sbin/ip

function setup_network()
{
	echo "$IP link set up dev $VENET_DEV" > "$IFCFG"
	echo "$IP route add default dev $VENET_DEV" >> "$IFCFG"
	echo "$IP -6 route add default dev $VENET_DEV" >> "$IFCFG"
}

function add_ip()
{
	[ ! -f "$IFCFG" ] && touch "$IFCFG"

	# In case we are starting CT
	if [ "x${VE_STATE}" = "xstarting" ]; then
		setup_network
	fi
	
	local ipm
	for ipm in ${IP_ADDR}; do
		local cmd
		
		if [ "${ipm#*:}" = "${ipm}" ] ; then
			cmd="$IP addr add $ipm/32 dev $VENET_DEV"
			echo "$cmd" >> "$IFCFG"
		else
			cmd="$IP -6 addr add $ipm/128 dev $VENET_DEV"
			echo "$cmd" >> "$IFCFG"
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
