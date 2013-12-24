zabbix-scripts
==============

My collection of scripts for zabbix agents on Windows hosts.
All scripts are designed to use with passive checks.

List of scripts:

1) apc_check.ps1(and apc_check.cmd)
Script for parsing text file apcupsd.status generated automaticaly by apcupsd (read documentation for apcupsd to do this).

2) raid_discovery.ps1
Modificated version of discovery script placed on Zabbix wiki (https://www.zabbix.org/mw/index.php5?title=Templates/Intel_LSI_RAID&amp;diff=4548&amp;oldid=0). The main goal of modification is to use it with passive checks.

3) raid_check.ps1
This is also modified script from mentioned article as above. The goal of modification is the same.
