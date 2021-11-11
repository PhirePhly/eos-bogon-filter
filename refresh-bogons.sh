#!/bin/sh
# (C) Kenneth Finnegan, 2021, Arista Networks
#
# Download the Team Cymru fullbogons lists and format to be imported
# into an EOS prefix-list via a source directive and refresh the
# running-config

PL_PATH_PREFIX="/mnt/flash/pl-bogons"
EOS_V4PL_NAME="pl-bogons-v4"
EOS_V6PL_NAME="pl-bogons-v6"

set -e

SKIP_EOS_REFRESH=""

#####
#
# Function definitions
#
#####

function usage {
	echo ""
	echo "Usage: $0 [-h] [-n]"
	echo ""
	echo "Download the Team Cymru fullbogons list and import them into EOS running-config"
	echo "as a pair of prefix-lists to be used in BGP route-maps"
	echo ""
	echo " -h : Help - display this message"
	echo " -n : Skip EOS refresh - Don't have EOS refresh the prefix-lists in the running-config"
	echo ""
}


#####
#
# Start processing
#
#####

while getopts ":hn" OPT; do
	case $OPT in
		h)
			usage
			exit 0
			;;
		n)
			SKIP_EOS_REFRESH="1"
			;;
		\?)
			usage
			exit 1
			;;
	esac
done


# Fetch bogon lists from Cymru

curl -s https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt |\
awk '!/#/ {print "permit " $0 " le 32"}' >$PL_PATH_PREFIX/pl-bogons-v4.txt.new

curl -s https://www.team-cymru.org/Services/Bogons/fullbogons-ipv6.txt |\
awk '!/#/ {print "permit " $0 " le 128"}' >$PL_PATH_PREFIX/pl-bogons-v6.txt.new

# Perform health checks to ensure that we successfully downloaded the lists


# Install the new prefix lists and refresh the running config

mv $PL_PATH_PREFIX/pl-bogons-v4.txt.new $PL_PATH_PREFIX/pl-bogons-v4.txt
mv $PL_PATH_PREFIX/pl-bogons-v6.txt.new $PL_PATH_PREFIX/pl-bogons-v6.txt

if [ -z ${SKIP_EOS_REFRESH} ]; then
	FastCli -p 15 -c "refresh ip prefix-list $EOS_PL_NAME_V4"
	FastCli -p 15 -c "refresh ipv6 prefix-list $EOS_PL_NAME_V6"
fi

