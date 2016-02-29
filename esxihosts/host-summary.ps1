#host-summary.ps1
#Quick and dirty
$vcList = (read-host "Enter a comma-separated list of vCenters") -split ","
$filename = read-host "Specify output CSV file"

write-output "Enter vCenter credentials"
$creds = get-credential

$objectlist = @()

Disconnect-VIServer -Server * -Force -Confirm:$false

foreach($vc in $vcList) {
	Connect-VIServer -Server $vc -Credential $creds
	
	#CAVEAT: We expect all VMs to be in a cluster
	$DCs = get-datacenter
	
	foreach($dc in $DCs) {
		# $_.hardware.systeminfo.vendor
		# $_.hardware.systeminfo.model
		# $_.summary.hardware.cpumodel
		# $_.name
		$objectlist += get-view -viewtype hostsystem -searchroot $dc.id | select {$vc}, {$dc.name}, {$_.name}, {$_.summary.runtime.connectionstate}, {$_.summary.runtime.powerstate}, {$_.hardware.systeminfo.vendor}, {$_.hardware.systeminfo.model}, {$_.summary.hardware.cpumodel}
	}
	
	Disconnect-VIServer -Server * -Force -Confirm:$false
}

$objectlist | export-csv -NoTypeInformation $filename

