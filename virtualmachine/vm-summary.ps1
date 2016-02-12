#vm-summary.ps1
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
	$clusters = get-cluster
	
	foreach($cluster in $clusters) {
		$objectlist += get-view -viewtype virtualmachine -searchroot $cluster.id | select {$vc}, {$cluster.name}, {$_.name}, {$_.summary.runtime.powerstate}, {$_.summary.runtime.connectionstate}, {$_.summary.config.name}, {$_.summary.config.numcpu}, {$_.summary.config.memorysizemb}, {$_.summary.config.guestfullname}, {$_.summary.guest.guestfullname}, {$_.summary.guest.ipaddress}, {$_.summary.guest.hostname}, {$_.summary.storage.committed}, {$_.summary.storage.uncommitted}, {$_.summary.storage.unshared}
		
	}
	Disconnect-VIServer -Server * -Force -Confirm:$false
}

$objectlist | export-csv -NoTypeInformation $filename

