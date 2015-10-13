#enumerate VMHosts by datastore with detailed information
#jpg 8/8/2013
#jpg 10/14/2013 updated to place FC HBA's first, added "parent" field

param (
	[string]$datacenter = ""
)

$output="FC HBA A,FC HBA B,Datacenter,Cluster,Parent,Host,Version,Build,Manufacturer,Host Model, ConnectionState, ProcessorType, Physical Memory, Physical CPUs, Total Mhz, Assigned vRAM, Assigned VMs, Assigned vCPUs"

write-output $output

Get-datacenter $datacenter | foreach {
	$dcname = $_.Name
	$_ | get-vmhost | foreach {
		
		$hostname = $_.Name
		$version = $_.Version
		$build = $_.Build
		$cluster = $_ | get-cluster | select-object name
		$parent = $_.Parent
		$manf = $_.Manufacturer
		$model = $_.Model
		
		$hba = $_ | Get-VMHostHba | ? { $_.Type -eq "FibreChannel" }
		
		#add these
		$connectionstate = $_.ConnectionState
		$hbaA = "n/a"
		$hbaB = "n/a"
		$hbaA = "{0:X0}" -f $hba[0].PortWorldWideName
		$hbaB = "{0:X0}" -f $hba[1].PortWorldWideName
		
		$processortype = $_.ProcessorType
		$physicalRAM = [int]$_.MemoryTotalGB
		$numcpu = $_.NumCpu
		$mhz = $_.CpuTotalMhz
		
		$assignedram = 0
		$vmcount = 0
		$assignedvcpu = 0 
		$_ | get-vm | % { 
			$assignedram += $_.MemoryMB 
			$vmcount += 1 
			$assignedvcpu += $_.numcpu
		}
		
		$output = ("`r`n" + "$hbaA,$hbaB,$dcname,$cluster,$parent,$hostname,$version,$build,$manf,$model,$connectionstate,$processortype,$physicalram,$numcpu,$mhz,$assignedram,$vmcount,$assignedvcpu")
		write-output $output
	}
}