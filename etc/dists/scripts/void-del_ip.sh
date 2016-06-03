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
# Deletes IP address from a container running Void Linux.

VENET_DEV=venet0
IFCFG=/etc/runit/core-services/90-venet.sh
IP=/sbin/ip

function clear_ip()
{
	local cfg="$IFCFG"
	local ip="$1"
	
	grep -v "$ip/" "$cfg" > "${cfg}.new"
	mv "${cfg}.new" "${cfg}"

}

function del_ip()
{
	[ ! -f "$IFCFG" ] && touch "$IFCFG"

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
