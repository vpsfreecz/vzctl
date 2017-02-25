#!/bin/sh -x

# Sets up resolver template (/resolv.conf) in a container


export PATH=$PATH:/run/current-system/sw/bin

[ -n "${SEARCHDOMAIN}" ] && echo "search ${SEARCHDOMAIN}" >> /resolv.conf
for ns in ${NAMESERVER}; do
  echo "nameserver $ns" >> /resolv.conf
done
exit 0
