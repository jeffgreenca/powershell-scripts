#2012-11-02 JG Set VM Disk IOps Limit
# Set the IOps limit for each virtual machine hard disk.
# This IOps limit unlike disk shares does not require Storage I/O control
# Instead it is handled at the disk scheduler level to prevent the VM from overrunning storage.

$defang = 0 #0 = run and make changes to vms, 1 = run without making changes
$vmSearchPatterns = ('VDI*')

$iopsLimit = 200 #Set this to the desired IOps limit per VM

$count = 0
foreach($vmSearchPattern in $vmSearchPatterns) {
	Get-VM -name $vmSearchPattern | foreach {
		foreach($disk in (Get-HardDisk $_)) {
			Write-Output "Setting IOps limit to $iopsLimit for $_ -> $disk"
			if ($defang -eq 0) {
				$r = Set-VMResourceConfiguration -Configuration $_.VMResourceConfiguration -Disk $disk -DiskLimitIOPerSecond $iopsLimit
			}
		}
		$count++
	}
	write-output "Processed $count virtual machines matching pattern ""$vmSearchPattern"""
}