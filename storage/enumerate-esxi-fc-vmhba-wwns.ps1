#Given a file containing a list of ESXi hosts, connect to each one and get a list of FC vmhba WWNs

param (
  [Parameter(Mandatory=$true)]
  [string]$esxiHostListFile
)

$esxi_creds = get-credential -Message "Enter ESXi root credentials"

#start clean
disconnect-viserver * -confirm:$false -erroraction:silentlycontinue -warningaction:silentlycontinue

$results = ""

get-content $esxiHostListFile | foreach {
    write-output "Connecting to $_ ..."
    if( connect-viserver $_ -Credential $esxi_creds -erroraction:continue -warningaction:silentlycontinue) {
        get-vmhost | get-vmhosthba -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}"-f$_.PortWorldWideName}} | foreach {
          $deviceName = $_.VMHost.Name
          $vmhba = $_.Device
          $wwpn = $_.WWN
          
          $results += "$deviceName $vmhba $wwpn`r`n"
        }
    }
    disconnect-viserver * -confirm:$false
}


write-output "RESULTS"
write-output $results
