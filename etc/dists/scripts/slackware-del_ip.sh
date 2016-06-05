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
# Deletes IP address from a container running Slackware.
# Note that this script requires /etc/rc.d/rc.venet to be present.

VENET_DEV=venet0
IFCFG=/etc/rc.d/rc.venet
IP=/sbin/ip

function clear_ip()
{
	local cfg="${IFCFG}.$1"
	local ip="$2"
	
	grep -v "$ip/" "$cfg" > "${cfg}.new"
	mv "${cfg}.new" "${cfg}"

}

function del_ip()
{
	if [ ! -f "$IFCFG" ] ; then
		echo "Unable to del ip: '$IFCFG' does not exist"
		exit 1
	fi

	local ipm

	if [ "x${IPDELALL}" = "xyes" ]; then
		$IFCFG stop
		return 0
	fi

	for ipm in ${IP_ADDR}; do
		clear_ip "start" "$ipm"
		clear_ip "stop" "$ipm"
		
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
