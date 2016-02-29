#hp-oa-run-commands.ps1 HP BladeSystem Run Arbitrary Commands
#Jeff Green, Feb 2016

write-host "HP BladeSystem Command Script..."
write-host "--`n"

$username = read-host "Enter username"
$pw = read-host "Enter password (warning - will be echo'd to screen)"
clear
echo "Read username and password..."

$list = import-csv hp-simpleinventory-oa-list.txt

foreach($oa in $list) {
	Write-Output "Operating on for $($oa.Location) $($oa.ip)"
	$ip = $oa.ip
	$raw = plink -m .\adduser-commands.txt -pw $pw $username@$ip
	echo "Results"
	echo $raw
	
	write-output "...done`n"
}