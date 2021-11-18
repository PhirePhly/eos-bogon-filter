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

# Rationale

This script dynamically updates a pair of prefix lists based on the IP
prefixes that should never be received from another autonomous system
across the default free zone of the Internet, due to the prefixes either
not being routable address space or not currently being allocated to an
active AS by one of the RIRs.

These two prefix lists are intented to be used as part of the ingress BGP
policy on eBGP peering sessions to filter out these prefixes. This protection
is only on the control plane, so this doesn't implement any Remote Triggered
Black Hole policy in the data plane for these bogons, which is often also a
desirable protection.

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

These two prefix lists will now automatically update every four hours, and can
be used as part of an ingress route-map from peers:

```
route-map ingress-filtering-v4 deny 10
   match ip address prefix-list pl-bogons-v4
route-map ingress-filtering-v4 permit 100
route-map ingress-filtering-v6 deny 10
   match ipv6 address prefix-list pl-bogons-v6
route-map ingress-filtering-v6 permit 100
router bgp 64496
   neighbor 192.0.2.1 remote-as 64497
   neighbor 192.0.2.1 route-map ingress-filtering-v4 in
   neighbor 2001:db8::2 remote-as 64497
   neighbor 2001:db8::2 route-map ingress-filtering-v6 in
```


This script is based on the work done by Alexis Dacquay
https://eos.arista.com/bgp-peering-configuration-best-practices-security-and-manageability/

