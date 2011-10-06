#!/bin/sh
#  Copyright (C) 2000-2011, Parallels, Inc. All rights reserved.
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
# Adds IP address(es) in a container running Debian-like distro.

VENET_DEV=venet0
LOOPBACK=lo
CFGFILE=/etc/network/interfaces
HOSTFILE=/etc/hosts

fix_networking_conf()
{
	local cfg="/etc/init/networking.conf"
	local str="local-filesystems"

	test -f ${cfg} || return 0
	fgrep -q "udevtrigger" ${cfg} 2>/dev/null || return 0

	fgrep -v "udevtrigger" ${cfg} | \
		sed "s,(${str},${str},g" > ${cfg}.$$ && \
		mv -f ${cfg}.$$ ${cfg}
}

setup_network()
{
	echo "# This configuration file is auto-generated.
#
# WARNING: Do not edit this file, your changes will be lost.
# Please create/edit $CFGFILE.head and
# $CFGFILE.tail instead, their contents will be
# inserted at the beginning and at the end of this file, respectively.
#
# NOTE: it is NOT guaranteed that the contents of $CFGFILE.tail
# will be at the very end of this file.
#
" > ${CFGFILE}

	if [ -f ${CFGFILE}.head ]; then
		cat ${CFGFILE}.head >> ${CFGFILE}
	fi

	if [ -f ${CFGFILE}.template ]; then
		cat ${CFGFILE}.template >> ${CFGFILE}
	fi
	# Set up loopback
	if ! grep -qw lo ${CFGFILE}; then
		echo "# Auto generated ${LOOPBACK} interface
auto ${LOOPBACK}
iface ${LOOPBACK} inet loopback" >> ${CFGFILE}
	fi

	# Set up /etc/hosts
	if [ ! -f $HOSTFILE ]; then
		echo "127.0.0.1 localhost.localdomain localhost" > $HOSTFILE

		if [ "${IPV6}" = "yes" ]; then
			echo "::1 localhost.localdomain localhost" >> $HOSTFILE
		fi
	fi

	if [ -n "${IP_ADDR}" ]; then
		# Set up venet0
		echo "
# Auto generated ${VENET_DEV} interface
auto ${VENET_DEV}
iface ${VENET_DEV} inet manual
	up ifconfig ${VENET_DEV} up
	up ifconfig ${VENET_DEV} 127.0.0.2
	up route add default dev ${VENET_DEV}
	down route del default dev ${VENET_DEV}
	down ifconfig ${VENET_DEV} down
" >> ${CFGFILE}

		if [ "${IPV6}" = "yes" ]; then
			echo "
iface ${VENET_DEV} inet6 manual
	up route -A inet6 add default dev ${VENET_DEV}
	down route -A inet6 del default dev ${VENET_DEV}
" >> ${CFGFILE}

		fi
	fi

	if [ -f ${CFGFILE}.tail ]; then
		cat ${CFGFILE}.tail >> ${CFGFILE}
	fi

	fix_networking_conf
}

create_config()
{
	local ip=$1
	local netmask=$2
	local mask=$3
	local ifnum=$4

	if [ "${ip#*:}" = "${ip}" ]; then
	    echo "auto ${VENET_DEV}:${ifnum}
iface ${VENET_DEV}:${ifnum} inet static
	address ${ip}
	netmask ${netmask}
" >> ${CFGFILE}.bak

	else
	    sed -i -e "s/iface ${VENET_DEV} inet6 manual/iface ${VENET_DEV} inet6 manual\n\tup ifconfig ${VENET_DEV} add ${ip}\/${mask}\n\tdown ifconfig ${VENET_DEV} del ${ip}\/${mask}/" ${CFGFILE}.bak
	fi

}

get_all_aliasid()
{
	IFNUM=-1
	IFNUMLIST=$(grep -e "^auto ${VENET_DEV}:.*$" 2>/dev/null \
		${CFGFILE}.bak | sed "s/.*${VENET_DEV}://")
}

get_free_aliasid()
{
	local found=

	[ -z "${IFNUMLIST}" ] && get_all_aliasid
	while test -z ${found}; do
		IFNUM=$((IFNUM+1))
		echo "${IFNUMLIST}" | grep -q -E "^${IFNUM}$" 2>/dev/null ||
			found=1
	done
}

add_ip()
{
	local ipm
	local add
	local iface

	if [ "x${VE_STATE}" = "xstarting" ]; then
		if test -n "$IP_ADDR"; then
			setup_network
		else
			# IP_ADDR empty, do we need to remove old ones?
			if grep -q -F -w "${VENET_DEV}" ${CFGFILE}; then
				setup_network
			fi
		fi
	elif ! grep -q -E "^auto ${VENET_DEV}([^:]|$)" ${CFGFILE} 2>/dev/null; then
		setup_network
	fi
	if [ "${IPDELALL}" = "yes" ]; then
		ifdown ${VENET_DEV} >/dev/null 2>&1
		if [ -z "${IP_ADDR}" ]; then
			# No new IPs to assign, remove venet0 completely
			remove_debian_interface "${VENET_DEV}.*" ${CFGFILE}
			sed -i -e 's/^# Auto generated venet0 interface$//' ${CFGFILE}
		else
			# Will add new IPs below, only remove venet0 aliases and IPv6
			remove_debian_interface "${VENET_DEV}:[0-9]*" ${CFGFILE}
			# Remove IPv6 addresses (which are not aliases)
			# Note the actual tab character in grep expression
			grep -v "^	up ifconfig ${VENET_DEV} add " ${CFGFILE} > ${CFGFILE}.bak
			grep -v "^	down ifconfig ${VENET_DEV} del " ${CFGFILE}.bak > ${CFGFILE}
		fi
	fi
	if [ -n "${IP_ADDR}" ]; then
		cp -f ${CFGFILE} ${CFGFILE}.bak
		for ipm in ${IP_ADDR}; do
			ip_conv $ipm
			if grep -w "${_IP}" >/dev/null 2>&1 ${CFGFILE}.bak; then
				continue
			fi
			get_free_aliasid
			create_config "${_IP}" "${_NETMASK}" "${_MASK}" "${IFNUM}"
		done
		mv -f ${CFGFILE}.bak ${CFGFILE}
	fi
	if [ "x${VE_STATE}" = "xrunning" ]; then
		if [ -x /usr/sbin/invoke-rc.d ] ; then
			/usr/sbin/invoke-rc.d networking restart > /dev/null 2>&1
		else
			/etc/init.d/networking restart > /dev/null 2>&1
		fi
	fi
}

add_ip

exit 0
