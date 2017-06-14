# Quick and Dirty automated deploy of a bunch of VMs from Template with Guest OS Spec and Static IP
# JG 
# Expects vmlist.csv with the following columns:
# Name, vCPU, vRAM, IPAddress, Gateway, PortGroup

$myResourcePool = Get-Cluster "YOUR_CLUSTER"
$myTemplate = Get-Template -Name "YOUR_TEMPLATE"
$mySpecificationName = "YOUR_CUSTOMIZATION_SPEC_NAME"
$myDns = @("YOUR_DNS1_IP", "YOUR_DNS2_IP")
$datastore = "YOUR_DATASTORE"
$subnetMask = "255.255.255.0"

$csvSource = Import-Csv vmlist.csv

#Build a non-persistent guest OS customization spec - but first clear just in case!
Get-OSCustomizationSpec | ? type -eq nonpersistent | Remove-OSCustomizationSpec
$vmspec = New-OSCustomizationSpec -OSCustomizationSpec (Get-OSCustomizationSpec $mySpecificationName -Type Persistent) -Type NonPersistent

foreach($vm in $csvSource) {
    Write-output "Processing $($vm.name)"
    if(Get-VM $vm.name -ErrorAction:SilentlyContinue) {
        Write-Output "ERROR: VM $($vm.name) already exists.  Skipping."
    }
    else 
    {
    
        write-output "Assigning IP $($vm.IPAddress), default gateway $($vm.gateway) and building non-persistent spec"
        $nicmapping = Get-oscustomizationnicmapping -OSCustomizationSpec $vmspec
        $nicmapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $vm.IPAddress -DefaultGateway $vm.Gateway -SubnetMask $subnetMask -Dns $myDns
        
        $portgroup = Get-VDPortGroup $vm.PortGroup | Select -First 1
        write-output "Identified network $portgroup"
        
        write-output "Building!"
        $result = New-VM -Name $vm.name -Template $myTemplate -ResourcePool $myResourcePool -Datastore $datastore
        #Don't judge.  Wait for complete because the vCenter is sometimes too fast for new-vm to start waiting... or so says some stackoverflow article.
        while(1) {
            if(Get-VM $vm.name -ErrorAction:SilentlyContinue) { break }
            start-sleep 1
        }
        
        write-output "Applying non-persistent customization spec"
        $result = Set-VM -VM (Get-VM $vm.name) -OSCustomizationSpec $vmspec -Confirm:$false
        Start-Sleep 1
        
        Write-output "Configuring CPU/Memory"
        $result = Get-VM $vm.name | Set-VM -MemoryGB $vm.vRAM -NumCpu $vm.vCPU -Confirm:$false -ErrorAction:Continue
        Start-Sleep 1
        
        Write-output "Configuring Network"
        $result = Get-VM $vm.name | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup $portgroup -Confirm:$false -ErrorAction:Continue
        Start-Sleep 1
        
        Write-output "Powering up!"
        $result = Start-VM $vm.name
    
    }
}
