#vm-summary.ps1
#Quick and dirty
$dcs = get-datacenter
foreach($datacenter in $dcs) {
	get-view -searchroot $datacenter.id -viewtype virtualmachine | select {$datacenter.name}, {$_.name}, {$_.summary.runtime.powerstate}, {$_.summary.config.name}, {$_.summary.config.numcpu}, {$_.summary.config.memorysizemb}, {$_.summary.config.guestfullname}, {$_.summary.guest.guestfullname}, {$_.summary.guest.ipaddress}, {$_.summary.guest.hostname}, {$_.summary.storage.committed}, {$_.summary.storage.uncommitted}, {$_.summary.storage.unshared}
}