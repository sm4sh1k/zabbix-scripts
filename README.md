Scripts for Zabbix agent running on Windows (and UNIX)
==============

My collection of scripts for zabbix agents on Windows and UNIX hosts.
All scripts are designed to use with passive checks and most of them are written on PowerShell.
Appropriate templates are also included.

## List of scripts

* **apc_check.ps1**(and also **apc_check.cmd** and **apc_check.sh**). Script for parsing text file *apcupsd.status* generated automaticaly by apcupsd (read documentation for apcupsd to do this). It has one input parameter *item* and returns value in appropriate field of file. The CMD and BASH versions are more lightweight and simple than PowerShell version of script. You can use any of them. BASH sript is suitable for UNIX systems (like FreeBSD or Linux).

* **raid_discovery.ps1**(and **raid_discovery.pl**). Modificated version of discovery script placed on Zabbix wiki (https://www.zabbix.org/mw/index.php5?title=Templates/Intel_LSI_RAID&amp;diff=4548&amp;oldid=0). The main goal of modification is to use it with passive checks. For gathering information script uses utility CmdTool2 from Intel website.

* **raid_check.ps1**(and **raid_check.pl**). This is also modified script from mentioned article as above. The goal of modification is the same.

## Installation

Put the scripts to folders you like and edit paths to files at the beginning of all scripts.
Add user parameters to zabbix agent configuration file.
Import templates to Zabbix (all templates were tested on Zabbix 2.2).

On Linux hosts you also have to add zabbix user to a sudoers list for running external executables from scripts.
I just created **/etc/sudoers.d/zabbix_sudo** file and added to it next two lines:
	Defaults:zabbix !requiretty
	zabbix ALL=(ALL) NOPASSWD: /opt/MegaRAID/CmdTool2/CmdTool264

## User parameters

	# raid_check.ps1
	UserParameter=intel.raid.physical_disk[*],powershell -File "C:\Zabbix\scripts\raid_check.ps1" -mode pdisk -item $4 -adapter $1 -enc $2 -pdisk $3
	UserParameter=intel.raid.logical_disk[*],powershell -File "C:\Zabbix\scripts\raid_check.ps1" -mode vdisk -item $3 -adapter $1 -vdisk $2
	UserParameter=intel.raid.bbu[*],powershell -File "C:\Zabbix\scripts\raid_check.ps1" -mode bbu -item $2 -adapter $1
	UserParameter=intel.raid.adapter[*],powershell -File "C:\Zabbix\scripts\raid_check.ps1" -mode adapter -item $2 -adapter $1

	# raid_discovery.ps1
	UserParameter=intel.raid.discovery.pdisks,powershell -File "C:\Zabbix\scripts\raid_discovery.ps1" -mode pdisk
	UserParameter=intel.raid.discovery.vdisks,powershell -File "C:\Zabbix\scripts\raid_discovery.ps1" -mode vdisk
	UserParameter=intel.raid.discovery.bbu,powershell -File "C:\Zabbix\scripts\raid_discovery.ps1" -mode bbu
	UserParameter=intel.raid.discovery.adapters,powershell -File "C:\Zabbix\scripts\raid_discovery.ps1" -mode adapter

	# apc_check.ps1
	UserParameter=apc.ups[*],powershell -File "C:\Zabbix\scripts\apc_check.ps1" -item $1
	#UserParameter=apc.ups[*],C:\Zabbix\scripts\apc_check.cmd $1
	
	# raid_check.pl
	UserParameter=intel.raid.physical_disk[*],/usr/bin/perl -w /etc/zabbix/scripts/raid_check.pl -mode pdisk -item $4 -adapter $1 -enclosure $2 -pdisk $3
	UserParameter=intel.raid.logical_disk[*],/usr/bin/perl -w /etc/zabbix/scripts/raid_check.pl -mode vdisk -item $3 -adapter $1 -vdisk $2
	UserParameter=intel.raid.bbu[*],/usr/bin/perl -w /etc/zabbix/scripts/raid_check.pl -mode bbu -item $2 -adapter $1
	UserParameter=intel.raid.adapter[*],/usr/bin/perl -w /etc/zabbix/scripts/raid_check.pl -mode adapter -item $2 -adapter $1
	
	# raid_discovery.pl
	UserParameter=intel.raid.discovery.pdisks,/usr/bin/perl -w /etc/zabbix/scripts/raid_discovery.pl -mode pdisk
	UserParameter=intel.raid.discovery.vdisks,/usr/bin/perl -w /etc/zabbix/scripts/raid_discovery.pl -mode vdisk
	UserParameter=intel.raid.discovery.bbu,/usr/bin/perl -w /etc/zabbix/scripts/raid_discovery.pl -mode bbu
	UserParameter=intel.raid.discovery.adapters,/usr/bin/perl -w /etc/zabbix/scripts/raid_discovery.pl -mode adapter
	
	# apc_check.sh
	UserParameter=apc.ups[*],/etc/zabbix/scripts/apc_check.sh $1
