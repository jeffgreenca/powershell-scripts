$vc = "vcenter"
Connect-VIServer $vc

Get-NetworkAdapter -Template * | select {$vc}, {$_.parent.name}, {$_.parent.extensiondata.guest.guestfullname}, name, networkname, macaddress, type

#Or for VMs
#Get-NetworkAdapter -VM * | select {$vc}, {$_.parent.name}, {$_.parent.extensiondata.guest.guestfullname}, name, networkname, macaddress, type
