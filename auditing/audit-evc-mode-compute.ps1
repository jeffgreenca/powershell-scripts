#audit-evc-mode-compute.ps1
$vcList = (read-host "Enter a comma-separated list of vCenters") -split ","
$filename = read-host "Specify output CSV file"

write-output "Enter vCenter credentials"
$creds = get-credential

$objectlist = @()

Disconnect-VIServer -Server * -Force -Confirm:$false

foreach($vc in $vcList) {
	Connect-VIServer -Server $vc -Credential $creds
	
	#CAVEAT: We expect all hosts to be in a cluster... not always the case!
	$clusters = get-cluster
	
	foreach($cluster in $clusters) {
		$objectlist += get-view -viewtype hostsystem -searchroot $cluster.id | select {$vc}, {$cluster.name}, {$cluster.evcmode}, {$_.name}, {$_.summary.hardware.model}, {$_.summary.runtime.powerstate}, {$_.summary.runtime.connectionstate}, {$_.Summary.CurrentEVCModeKey}, {$_.Summary.MaxEVCModeKey}
	}
	
	Disconnect-VIServer -Server * -Force -Confirm:$false
}

$objectlist | export-csv -NoTypeInformation $filename