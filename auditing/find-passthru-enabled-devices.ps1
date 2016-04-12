#find-passthru-enabled-devices.ps1
$vcList = (read-host "Enter a comma-separated list of vCenters") -split ","
$filename = read-host "Specify output CSV file"

write-output "Enter vCenter credentials"
$creds = get-credential

$objectlist = @()

Disconnect-VIServer -Server * -Force -Confirm:$false

foreach($vc in $vcList) {
	Connect-VIServer -Server $vc -Credential $creds
	
	$h = Get-VMHost 
	
	Get-VMHost | foreach {
		$result = "" | select vCenter,Hostname,PassThruEnabled
		$result.vCenter = $vc
		$result.Hostname = $_.Name
		
		if ( $_.ExtensionData.Config.PciPassthruInfo | ? { $_.passthruenabled } ) {
			$result.PassThruEnabled = "True"
		} else {
			$result.PassThruEnabled = "False"
		}
	}
	
	Disconnect-VIServer -Server * -Force -Confirm:$false
}

$objectlist | export-csv -NoTypeInformation $filename