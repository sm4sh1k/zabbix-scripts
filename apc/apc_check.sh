#!/bin/sh

strfile="/var/log/apcupsd.status"
strout=""

case "$1" in
	model)
		strout=`awk -F: < $strfile '/^MODEL\ +:\ +(.*)/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	firmware)
		strout=`awk -F: < $strfile '/^FIRMWARE\ +:\ +(.*)/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	mandate)
		strout=`awk -F: < $strfile '/^MANDATE\ +:\ +(.*)/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	serialno)
		strout=`awk -F: < $strfile '/^SERIALNO\ +:\ +(.*)/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	battdate)
		strout=`awk -F: < $strfile '/^BATTDATE\ +:\ +(.*)/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	status)
		strout=`awk -F: < $strfile '/^STATUS\ +:\ +(.*[A-Z])/ {print $2}' | sed -e 's/^ *//g' -e 's/ *$//g'`
		;;
	bcharge)
		strout=`awk < $strfile '/^BCHARGE\ +:\ +([0-9]+\.[0-9]+)/ {print $3}'`
		;;
	itemp)
		strout=`awk < $strfile '/^ITEMP\ +:\ +([0-9]+\.[0-9]+)/ {print $3}'`
		;;
	timeleft)
		strout=`awk < $strfile '/^TIMELEFT\ +:\ +([0-9]+)\.[0-9]+/ {print $3}' | sed -e 's/\.[0-9]0* *$//g'`
		;;
	linev)
		strout=`awk < $strfile '/^LINEV\ +:\ +([0-9]+\.[0-9]+)/ {print $3}'`
		;;
	outputv)
		strout=`awk < $strfile '/^OUTPUTV\ +:\ +([0-9]+\.[0-9]+)/ {print $3}'`
		;;
	loadpct)
		strout=`awk < $strfile '/^LOADPCT\ +:\ +([0-9]+\.[0-9]+)/ {print $3}'`
		;;
esac

echo "${strout}"
