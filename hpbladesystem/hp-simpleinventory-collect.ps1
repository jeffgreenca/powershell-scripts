#HP BladeSystem inventory using plink.exe
#Jeff Green, Feb 2016

write-host "HP BladeSystem Inventory Collection Script... summarized version."
write-host "--`n"

$pw = read-host "Enter common Administrator password (warning - will be echo'd to screen)"

$list = import-csv hp-simpleinventory-oa-list.txt

foreach($oa in $list) {
	Write-Output "Collecting info for $($oa.Location) $($oa.ip)"
	$ip = $oa.ip
	$matchCriteria = "(^Totals:)|(^\d.[^<]+$)|(Product Name:)|(Server Blade #)|(CPU \d:)|(Memory:)|(FLB Adapter \d:)|(Mezzanine \d:)"
	$raw = plink -m .\hp-simpleinventory-commands.txt -pw $pw Administrator@$ip
	$summary = $raw | ? {$_ -match $matchCriteria}
	
	write-output "Summary for $($oa.Location) -- $($oa.ip)" > "hp-summary-$($oa.Location)-$ip.txt"
	write-output $summary >> "hp-summary-$($oa.Location)-$ip.txt"
	write-output "...done`n"
}