#Set-SDRS-VM-Settings-Per-VM.ps1
#vm-name-list.txt is a line-separated list of virtual machine names that should be configured to the automation mode

$sListOfVirtualMachinesByNameToDisableStorageDRS = get-content vm-name-list.txt
$StorageDRSAutomationMode = "manual" #Set the VM mode to manual or automatic

$wumbus = Get-DatastoreCluster
$lorax =  Get-View StorageResourceManager

$squitsch = @()

foreach($guff in $wumbus) {
	$oListOfVirtualMachinesToConfigure = $guff | Get-VM | ? { $sListOfVirtualMachinesByNameToDisableStorageDRS -contains $_.name }

	foreach($snuvv in $oListOfVirtualMachinesToConfigure) {
		#Dr. Seuss breaks down here due for clarity
		#We build a VmConfigInfo object for this particular VM
		$vmConfigInfo			= New-Object VMware.Vim.StorageDrsVmConfigInfo
		$vmConfigInfo.Vm		= $snuvv.ExtensionData.MoRef
		$vmConfigInfo.Enabled	= $true
		$vmConfigInfo.Behavior	= $StorageDRSAutomationMode
		
		#The vmConfigInfo needs to be wrapped in a VmConfigSpec object's "info" property
		$vmConfigSpec			= New-Object VMware.Vim.StorageDrsVmConfigSpec
		$vmConfigSpec.info		= $vmConfigInfo
		
		#Now build the array of VmConfigSpecs so it can be submitted as a configuration all at once
		$squitsch += $vmConfigSpec
	}
	
	#Prepare a config spec at the "pod" level (datastore cluster) which contains our array of per-VM configurations
	$dscSpec 				= New-Object VMware.Vim.StorageDrsConfigSpec
	$dscSpec.vmConfigSpec 	= $squitsch
	
	#Submit the configuration changes via StorageResourceManager (aka the Lorax)
	$lorax.ConfigureStorageDrsForPod( $guff.ExtensionData.MoRef, $dscSpec, $true )
}