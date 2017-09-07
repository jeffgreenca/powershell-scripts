#Set NTP on a handful of ESXi hosts, before vCenter
#Enable firewall exception and set NTPD to automatic start

$ntpServer = "1.2.3.4"
$esxiHosts = @("10.0.0.100, 10.0.0.101, 10.0.0.103")

$cred = Get-Credential

$esxiHosts | foreach {
 connect-viserver $_ -Credential $cred                                                                  
 add-vmhostntpserver -NtpServer $ntpServer                                                           
 Get-VMHostFirewallException | ? name -match NTP | Set-VMHostFirewallException -Enabled $true           
 Get-VMHostService | ? key -match ntpd | Start-VMHostService | Set-VMHostService -Policy "Automatic"    
 disconnect-viserver -Confirm:$false                                                                    
 }
