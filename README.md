# EOS Bogon Filter
Filter Bogons from BGP peering sessions based on Team Cymru fullbogon lists

Bogons are IPv4 and IPv6 prefixes which are not routable in the default
free zone of the Internet, and should therefore never be received from
other autonomous systems over eBGP peering sessions.

Bogons fall into two categories:

1. IP prefixes which are designated for non-Internet use like RFC1918
   prefixes, documentation prefixes, etc.

2. IP prefixes which are held by one of the five RIRs which currently
   is not allocated for use by an autonomous system on the Internet

Team Cymru maintains a list of bogons for both IPv4 and IPv6, based on the
current prefix allocations by all of the RIRs. These bogon lists can be
downloaded from Team Cymru as either a plain text file or as a BGP
feed to implement a remote triggered black hole policy on.

This script downloads the plain textfile bogon lists and formats them
to be an EOS prefix list such that they can be used as a route-map for
filtering bogon prefixes from BGP peering sessions.

# Installation

To install this script, make a directory in flash: and copy in the script,
then create the two prefix lists and schedule the script to periodicially run
to re-download the latest bogon list and refresh the prefix lists.

```
SW1# mkdir flash:/pl-bogons
SW1# copy https://raw.githubusercontent.com/PhirePhly/eos-bogon-filter/main/refresh-bogons.sh flash:/pl-bogons/
SW1# bash /mnt/flash/pl-bogons/refresh-bogons.sh -n
SW1# configure
SW1(config)# ip prefix-list pl-bogons-v4 source flash:/pl-bogons/pl-bogons-v4.txt
SW1(config)# ipv6 prefix-list pl-bogons-v6 source flash:/pl-bogons/pl-bogons-v6.txt
SW1(config)# schedule refresh-bogon-prefixlist interval 240 max-log-files 20 command bash /mnt/flash/pl-bogons/refresh-bogons.sh
```

This script is based on the work done by Alexis Dacquay
https://eos.arista.com/bgp-peering-configuration-best-practices-security-and-manageability/

