#Get-RDM-LUN-IDs.ps1
#JG 9/17/2013 
#Adapted from http://pelicanohintsandtips.wordpress.com/2011/11/27/get-lun-id-of-raw-disk-mappings-with-powercli/

$dc = "myDatacenter"
$cluster = "myCluster"

write-output ("vm.Name ,disk.Name ,disk.ScsiCanonicalName ,disk.Filename ,disk.DiskType ,id ,disk.capacitykb")
get-datacenter $dc | get-cluster $cluster | get-vm | foreach {
	$vm = $_
	$vm | Get-HardDisk | Where {$_.DiskType -eq "RawPhysical"} | foreach {
		$Lun = Get-SCSILun $_.SCSICanonicalName -VMHost $vm.VMHost
		$id = $Lun.RuntimeName.Substring($Lun.RuntimeName.LastIndexof("L")+1)
		write-output ($vm.Name + "," + $_.VMHost + "," + $_.Name + "," + $_.ScsiCanonicalName + "," + $_.Filename + "," + $_.DiskType + "," + $id + "," + $_.capacitykb)
	}
	$vm | Get-HardDisk | Where {$_.DiskType -eq "RawVirtual"} | foreach {
		$Lun = Get-SCSILun $_.SCSICanonicalName -VMHost $vm.VMHost
		$id = $Lun.RuntimeName.Substring($Lun.RuntimeName.LastIndexof("L")+1)
		write-output ($vm.Name + "," + $_.VMHost + "," + $_.Name + "," + $_.ScsiCanonicalName + "," + $_.Filename + "," + $_.DiskType + "," + $id + "," + $_.capacitykb)
	}
}