#JG 
#Wait until two VMs are powered off, then reconfigure memory for both and start both

$targetVMName1 = "My Target VM"
$targetVMName1 = "My Other Target VM"
$targetMemoryGB = 3

$completed = 0
while ($completed -eq 0) {
  write-output "Waiting 30 seconds..."
  start-sleep 30
  if ( (get-vm $targetVMName1 ).powerstate -eq "PoweredOn" ) {
	write-output "Conditions not met, waiting"
  } else {
		write-output "$targetVMName1 is off, checking..."
     if ( (get-vm $targetVMName2 ).powerstate -eq "PoweredOn" ) {
		write-output "Conditions not met, waiting"
	 }
	 else {
		write-output "$targetVMName2 is off, reconfiguring!"
		#Both VMs are powered off
		Get-VM $targetVMName1 | Set-VM -MemoryGB $targetMemoryGB -Confirm:$false | Start-VM
		Get-VM $targetVMName2 | Set-VM -MemoryGB $targetMemoryGB -Confirm:$false | Start-VM
		$completed = 1
	 }
  }
}
