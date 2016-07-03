#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Switch;

my $mode;
GetOptions("mode=s" => \$mode) or die("Error in command line arguments\n");
die("Mode is not defined. Use --mode parameter") if !defined $mode;

my $cli = 'sudo /opt/MegaRAID/CmdTool2/CmdTool264';

my %enclosures		= ();
my %adapters		= ();
my %battery_units	= ();
my %physical_drives	= ();
my %virtual_drives	= ();

my $adp_count	= `$cli -AdpCount`;
# Controller Count: 1.
if ($adp_count =~ m/.*Controller\sCount:\s(\d)\.*/i) {
	$adp_count = $1;
} else {
	print "Didn't find any adapter, check regex or $cli\n";
	exit(1);
}

for (my $adapter = 0; $adapter < $adp_count; $adapter++) {
	my $pd_num = `$cli -pdGetNum -a $adapter`;
	# Number of Physical Drives on Adapter 0: 6
	if ($pd_num =~ m/.*Number\sof\sPhysical\sDrives\son\sAdapter\s$adapter:\s(\d+)\n.*/) {
		$pd_num = $1;
		if ($pd_num == 0) {
			print "No physical disks found on adapter $adapter\n";
			next;
		}
	}
	
	my $number_of_lds = `$cli -LDGetNum -a $adapter`;
	# Number of Virtual Drives Configured on Adapter 0: 3
	if ($number_of_lds =~ m/.*Number\sof\sVirtual\sDrives\sConfigured\son\sAdapter\s$adapter:\s(\d+)/) {
		$number_of_lds = $1;
		if ($number_of_lds == 0) {
			print "No virtual disks found on adapter $adapter\n";
			next;
		}
	}
	
	switch ($mode) {
		case 'vdisk' {
			for (my $vd = 0;$vd < $number_of_lds;$vd++) {
				$virtual_drives{$vd} = "{ \"{#VDRIVE_ID}\":\"$vd\", \"{#ADAPTER_ID}\":\"$adapter\" }";
			}
		}
		
		case 'bbu' {
			my $bbu_info = `$cli -AdpBbuCmd -GetBbuStatus -a $adapter`;
			if (!($bbu_info =~ m/.*Get BBU Status Failed.*/)) {
				$battery_units{$adapter} = "{ \"{#ADAPTER_ID}\":\"$adapter\" }";
			}
		}
		
		case 'adapter' {
			$adapters{$adapter} = "{ \"{#ADAPTER_ID}\":\"$adapter\" }" if !defined $adapters{$adapter};
		}
		
		case "pdisk" {
			# Number of enclosures on adapter 0 -- 1
			# There are no enclosures on some embedded LSI chips. If so let the enclosure ID be -1
			my $enc_num = `$cli -EncInfo -a $adapter`;
			if ($enc_num =~ m/.*Number\sof\senclosures\son\sadapter\s$adapter\s--\s(\d)\n.*/) {
				$enc_num = $1;
				if ($enc_num == 0) {
					my @pd_list = `$cli -pdlist -a $adapter`;
					# Determine Slot Number for each drive
					foreach my $line (@pd_list) {
						if ($line =~ m/^Slot\sNumber:\s(\d+)$/) {
							$physical_drives{$1} = "{ \"{#ENCLOSURE_ID}\":\"-1\", \"{#PDRIVE_ID}\":\"$1\", \"{#ADAPTER_ID}\":\"$adapter\" }";
						}
					}
					next;
				}
			}
			
			my @all_enclosures = `$cli -EncInfo -a $adapter`;
			my $current_enc_id	= -1;
			my $current_drv_num	= -1;
			foreach my $line (@all_enclosures) {
				if ($line =~ m/\s+Device ID\s+:\s(\d+).*/) {
					$current_enc_id = $1;
				} elsif ($line =~ m/\s+Number\sof\sPhysical\sDrives\s+:\s(\d+).*/) {
					$current_drv_num = $1;
				}
				if (($current_enc_id != -1) && ($current_drv_num != -1)) {
					$enclosures{$current_enc_id} = $current_drv_num;
					$current_enc_id = -1;
					$current_drv_num = -1;
				}
			}
			
			foreach my $enclosure (keys %enclosures) {
				my @pd_list = `$cli -pdlist -a $adapter`;
				my $check_next_line = 0;
				# Determine Slot Number for each drive on current enclosure
				foreach my $line (@pd_list) {
					if ($line =~ m/^Enclosure\sDevice\sID:\s$enclosure$/) {
						$check_next_line = 1;
					} elsif (($line =~ m/^Slot\sNumber:\s(\d+)$/) && $check_next_line) {
						$physical_drives{$1} = "{ \"{#ENCLOSURE_ID}\":\"$enclosure\", \"{#PDRIVE_ID}\":\"$1\", \"{#ADAPTER_ID}\":\"$adapter\" }";
						$check_next_line = 0;
					} else {
						next;
					}
				}
			}
		}
		
		else {
			die("Unknown mode, use pdisk, vdisk, bbu or adapter mode");
		}
	}
}

my $zsend_data = "{ \"data\":[";
my $i;
switch ($mode) {
	case "pdisk" {
		my $phd_count = keys %physical_drives;
		if ($phd_count != 0) {
			$i = 1;
			foreach my $drive (keys %physical_drives) {
				if ($i < $phd_count) {
					$zsend_data .= "$physical_drives{$drive},";
					$i++;
				} else {
					$zsend_data .= "$physical_drives{$drive}]}";
				}
			}
		}
	}
	
	case "vdisk" {
		my $lds_count = keys %virtual_drives;
		if ($lds_count != 0) {
			$i = 1;
			foreach my $vdrive (keys %virtual_drives) {
				if ($i < $lds_count) {
					$zsend_data .= "$virtual_drives{$vdrive},";
					$i++;
				} else {
					$zsend_data .= "$virtual_drives{$vdrive}]}";
				}
			}
		}
	}
	
	case "bbu" {
		$i = 1;
		my $bbu_count = keys %battery_units;
		if ($bbu_count != 0) {
			foreach my $bbu (keys %battery_units) {
				if ($i < $bbu_count) {
					$zsend_data .= "$battery_units{$bbu},";
					$i++;
				} else {
					$zsend_data .= "$battery_units{$bbu}]}";
				}
			}
		}
	}
	
	case "adapter" {
		$i = 1;
		my $adp_count = keys %adapters;
		if ($adp_count != 0) {
			foreach my $adapter (keys %adapters) {
				if ($i < $adp_count) {
					$zsend_data .= "$adapters{$adapter},";
					$i++;
				} else {
					$zsend_data .= "$adapters{$adapter}]}";
				}
			}
		}
	}
}
if ($zsend_data ne "{ \"data\":[") {
	print "$zsend_data\n";
} else {
	print "";
}

