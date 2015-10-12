#get-vm-storage-used.ps1
#example usage 
#   $sr = (Get-Datacenter MyDataCenter).id
#   ./get-vm-storage-used.ps1 -searchRoot $sr
Param([string]$searchRoot)

write-output "VM, GB Committed, GB Uncommitted, PowerState"

 get-view -viewtype "VirtualMachine" -searchroot $searchRoot | foreach {
	$myvmview = $_
	$gbused = ( $myvmview.summary.storage.committed / 1024 / 1024 / 1024 )
	$gbuncom = ( $myvmview.summary.storage.uncommitted / 1024 / 1024 / 1024 )
	$powerstate = $myvmview.runtime.powerstate
	$name = $myvmview.Name

	write-output ($name + "," + $gbused + "," + $gbuncom + "," + $powerstate )
}