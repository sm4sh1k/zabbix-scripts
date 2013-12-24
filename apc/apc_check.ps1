Param(
		[parameter(Position=0,Mandatory=$true)]
		[ValidateSet("model", "firmware", "mandate", "serialno", "battdate", "status", "bcharge", "itemp", "timeleft", "linev", "outputv", "loadpct")]
		[alias("i")]
		[String]
        $item
)

$file = "C:\Apcupsd\etc\apcupsd\apcupsd.status"

$regex = ''
switch ($item) {
	'model'			{ $regex = "^MODEL\s+:\s+(.*)" }
	'firmware'		{ $regex = "^FIRMWARE\s+:\s+(.*)" }
	'mandate'		{ $regex = "^MANDATE\s+:\s+(.*)" }
	'serialno'		{ $regex = "^SERIALNO\s+:\s+(.*)" }
	'battdate'		{ $regex = "^BATTDATE\s+:\s+(.*)" }
	'status'		{ $regex = "^STATUS\s+:\s+(.*[A-Z])" }
	'bcharge'		{ $regex = "^BCHARGE\s+:\s+(\d+\.\d+)" }
	'itemp'			{ $regex = "^ITEMP\s+:\s+(\d+\.\d+)" }
	'timeleft'		{ $regex = "^TIMELEFT\s+:\s+(\d+)\.\d+" }
	'linev'			{ $regex = "^LINEV\s+:\s+(\d+\.\d+)" }
	'outputv'		{ $regex = "^OUTPUTV\s+:\s+(\d+\.\d+)" }
	'loadpct'		{ $regex = "^LOADPCT\s+:\s+(\d+\.\d+)" }
}
$output = (Select-String -path $file -pattern $regex | % { $_.Matches } | % { $_.groups[1].value })
write-host $output
