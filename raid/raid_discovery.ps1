Param(
		[parameter(Position=0,Mandatory=$true)]
		[ValidateSet("pdisk", "vdisk", "bbu", "adapter")]
		[alias("m")]
		[String]
        $mode
)

$CLI = 'C:\CmdTool2\CmdTool2-64.exe'

$number_of_adapters = [int](& $CLI -adpCount | Select-String "Controller Count: (\d+)" -AllMatches | % {$_.Matches} | % {$_.groups[1].value})
$physical_drives = @{}
$virtual_drives = @{}
$battery_units = @{}
$adapters = @{}
for ($adapter = 0; $adapter -lt $number_of_adapters;$adapter++) {	
	# check number of physical disks on this adapter
	$number_of_disks = [int](& $CLI -pdGetNum -a $adapter | Select-String "Number of Physical Drives on Adapter $adapter\: (\d)" -AllMatches | % {$_.Matches} | % {$_.groups[1].value})
	if ($number_of_disks -eq 0) {
		write-host "No physical disks found on adapter $adapter. Skipping this adapter"
		Continue
	}
	
	# check number of configured RAID volumes
	$number_of_lds = [int](& $CLI -LDGetNum -a $adapter | Select-String "Number of Virtual Drives Configured on Adapter $adapter\:\s(\d+)" -AllMatches | % {$_.Matches} | % {$_.groups[1].value})
	if ($number_of_lds -eq 0) {
		write-host "No virtual disks found on adapter $adapter. Skipping this adapter"
		Continue
	}
	
	switch ($mode) {
		"vdisk" {
			# List RAID Volumes
			for ($vd = 0;$vd -lt $number_of_lds;$vd++) {			
				$virtual_drives.Add($vd,"{ `"{#VDRIVE_ID}`":`"$vd`", `"{#ADAPTER_ID}`":`"$adapter`" }")			
			}
		}
		"bbu" {
			# List Battery unit
			$bbu_is_missing = (& $CLI -AdpBbuCmd -GetBbuStatus -a $adapter | Select-String ".*Get BBU Status Failed.*" | % {$_.Matches})
			if (!$bbu_is_missing) {			
				$battery_units.Add($adapter,"{ `"{#ADAPTER_ID}`":`"$adapter`" }")			
			}
		}
		"adapter" {
			# Trying to add current adapter to adapters list
			if (!($adapters.ContainsKey($adapter))) {
				$adapters.Add($adapter,"{ `"{#ADAPTER_ID}`":`"$adapter`" }")
			}
		}
		"pdisk" {
			# List physical drives
			$tmp_file = Join-Path ${env:temp} "raid_pdlist-$(Get-Date -Format yyyy-MM-dd-HH-mm-ss).tmp"		
			& $CLI -pdlist -a $adapter | Out-File $tmp_file		
			$reader = [System.IO.File]::OpenText($tmp_file)
			$check_next_line = 0
			[regex]$regex_encall = "^\s*Enclosure\sDevice\sID:\s(.*)$"
			[regex]$regex_enc = "^\s*Enclosure\sDevice\sID:\s(\d+)$"
			[regex]$regex_slot = "^\s*Slot\sNumber:\s(\d+)$"
			# Determine Slot Number for each drive on enclosure
			$enclosure_id = -10;
			try {
				for(;;) {
					$line = $reader.ReadLine()
					if ($line -eq $null) { break }
					# Line contains enc id, next line is slot id
					if (($regex_encall.isMatch($line)) -eq $True) {
						if (($regex_enc.isMatch($line)) -eq $True) {
							$enclosure_id = $regex_enc.Matches($line) | % {$_.groups[1].value}
						} else {
							$enclosure_id = -1
						}
						$check_next_line = 1
					} elseif ((($regex_slot.isMatch($line)) -eq $True) -and ($check_next_line -eq 1) -and ($enclosure_id -ne -10)) {
						$drive_id = $regex_slot.Matches($line) | % {$_.groups[1].value}
						$physical_drives.Add($drive_id,"{ `"{#ENCLOSURE_ID}`":`"$enclosure_id`", `"{#PDRIVE_ID}`":`"$drive_id`", `"{#ADAPTER_ID}`":`"$adapter`" }")
						$check_next_line = 0
						$enclosure_id = -10
					} else {
						Continue
					}
				}
			}
			finally {
				$reader.Close()
			}
			remove-item $tmp_file
		}
	}
}

# Send text with json
$zsend_data = ''
switch ($mode) {
	"pdisk" {
		if ($physical_drives.Count -ne 0) {
			$i = 1
			$zsend_data = '{ "data":['
			foreach ($physical_drive in $physical_drives.Keys) {
				if ($i -lt $physical_drives.Count) {
					$string = "$($physical_drives.Item($physical_drive)),"
				} else {
					$string = "$($physical_drives.Item($physical_drive)) ]}"
				}		
				$i++
				$zsend_data += $string
			}
		}
	}
	"vdisk" {
		if ($virtual_drives.Count -ne 0) {
			$i = 1
			$zsend_data = '{ "data":['
			foreach ($virtual_drive in $virtual_drives.Keys) {
				if ($i -lt $virtual_drives.Count) {
					$string = "$($virtual_drives.Item($virtual_drive)),"
				} else {
					$string = "$($virtual_drives.Item($virtual_drive)) ]}"
				}		
				$i++
				$zsend_data += $string
			}
		}
	}
	"bbu" {
		if ($battery_units.Count -ne 0) {
			$i = 1
			$zsend_data = '{ "data":['
			foreach ($battery_unit in $battery_units.Keys) {
				if ($i -lt $battery_units.Count) {
					$string = "$($battery_units.Item($battery_unit)),"
				} else {
					$string = "$($battery_units.Item($battery_unit)) ]}"
				}
				$i++
				$zsend_data += $string
			}
		}
	}
	"adapter" {
		if ($adapters.Count -ne 0) {
			$i = 1
			$zsend_data = '{ "data":['
			foreach ($adapter in $adapters.Keys) {
				if ($i -lt $firmwares.Count) {
					$string = "$($adapters.Item($adapter)),"
				} else {
					$string = "$($adapters.Item($adapter)) ]}"
				}
				$i++
				$zsend_data += $string
			}
		}
	}
}
write-host $zsend_data
