Param(
		[parameter(Position=0,Mandatory=$true)]
		[ValidateSet("discovery", "status")]
		[alias("m")]
		[String]
		$mode
	,
		[parameter()]
		[ValidateNotNullOrEmpty()]
		[alias("n","upsname")]
		[string]
		$mode_upsname
	,
		[parameter()]
		[ValidateSet("status", "bcharge", "bvoltage", "temp", "inputv", "outputv", "load", "inputfreq")]
		[alias("i","item")]
		[string]
		$mode_item
)

$CLI = "C:\Program Files (x86)\NUT\bin\upsc.exe"

function func_discovery {
	$zsend_data = ''
	
	$upses = @((& $CLI -l) -split ' ')
	if ($upses.Count -gt 0) {
		$i = 1
		$zsend_data = '{ "data":['
		foreach ($upsname in $upses) {
			if ($i -lt $upses.Count) {
				$string = "{ `"{#UPSNAME}`":`"$upsname`" },"
			} else {
				$string = "{ `"{#UPSNAME}`":`"$upsname`" } ]}"
			}
			$i++
			$zsend_data += $string
		}
	}
	
	write-host $zsend_data
}

function func_status($upsname,$item) {
	$command = ''
	switch ($item) {
		'status'		{ $command = 'ups.status' }
		'bcharge'		{ $command = 'battery.charge' }
		'bvoltage'		{ $command = 'battery.voltage' }
		'temp'			{ $command = 'ups.temperature' }
		'inputv'		{ $command = 'input.voltage' }
		'outputv'		{ $command = 'output.voltage' }
		'load'			{ $command = 'ups.load' }
		'inputfreq'		{ $command = 'input.frequency' }
	}
	
	$output = (& $CLI $upsname $command)
	write-host $output
}


switch ($mode) {
	"discovery" { func_discovery }
	"status" 	{ func_status $mode_upsname $mode_item }
}
