#Given a file containing a list of ESXi hosts, connect to each one and build a zone config for Cisco MDS (may change in the future)

param (
  [Parameter(Mandatory=$true)]
  [string]$dns_suffix_to_remove_from_esxi_hostname,
  [Parameter(Mandatory=$true)]
  [string]$esxiHostList
)

$esxi_creds = get-credential -Message "Enter ESXi root credentials"

#ESXi host FQDN postfix to remove
$default_domain = "." + $dns_suffix_to_remove_from_esxi_hostname

#These determine the A and B side controllers that will be associated in zones with HBA1/2
$vmhba1Controller = "CONTROLLER1ALIAS"
$vmhba2Controller = "CONTROLLER2ALIAS"

$vsan = "1"
$zoneset1 = "zoneset name MyProdZone1 vsan $vsan"
$zoneset2 = "zoneset name MyProdZone2 vsan $vsan"

$hostDefinition = ""
$hostDefinition2 = ""

#start clean
disconnect-viserver * -confirm:$false -erroraction:silentlycontinue

get-content $esxiHostList | foreach {
    write-output "Connecting to $_ ..."
    if( connect-viserver $_ -Credential $esxi_creds -erroraction:continue -warningaction:silentlycontinue) {
        get-vmhost | get-vmhosthba -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}"-f$_.PortWorldWideName}} | foreach {
          $deviceName = $_.VMHost.Name.Replace($default_domain,"").ToUpper()
          $vmhba = $_.Device
          $wwpn = $_.WWN
          
          if($vmhba -eq "vmhba1") {
          $vmhba1 += "device-alias name $deviceName pwwn $wwpn`r`n"
          
          $vmhba1z += "zone name $deviceName vsan $vsan`r`n"
          $vmhba1z += "member device-alias $vmhba1Controller`r`n"
          $vmhba1z += "member device-alias $deviceName`r`n"
          
          $zoneset1 += "member $deviceName`r`n"
          
          #HP 3PAR Storage Host Creation CLI
          $hostDefinition += "createhost -persona 11 $deviceName $wwpn`r`n"
          } 
          if($vmhba -eq "vmhba2") {
          $vmhba2 += "device-alias name $deviceName pwwn $wwpn`r`n"
          
          $vmhba2z += "zone name $deviceName vsan $vsan`r`n"
          $vmhba2z += "member device-alias $vmhba2Controller`r`n"
          $vmhba2z += "member device-alias $deviceName`r`n"
          
          $zoneset2 += "member $deviceName`r`n"
          
          #HP 3PAR Storage Host Creation CLI
          $hostDefinition2 += "createhost -add $deviceName $wwpn`r`n"
          }
        }
    }
    disconnect-viserver * -confirm:$false
}


write-output "device-alias configuration script for vmhba1"
write-output $vmhba1
write-output "device-alias configuration script for vmhba2"
write-output $vmhba2

write-output "zoning for vmhba1"
write-output $vmhba1z
write-output "zoning for vmhba2"
write-output $vmhba2z

write-output "zoneset memberships for vmhba1"
write-output $zoneset1
write-output "zoneset memberships for vmhba2"
write-output $zoneset2

write-output "3PAR configuration commands"
write-output $hostDefinition
write-output $hostDefinition2
