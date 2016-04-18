#set-vmhosts-syslog-datacenters.ps1
#Example
# ./set-vmhosts-syslog-datacenters.ps1 -syslogServerSuffix "syslog.domain.local:1514" -dataCenters (Get-Datacenter *)
# 

param ( 
	$dataCenters,
	$syslogServerSuffix = "syslog.domain.local",
	$syslogServerPort = "1514"
)

$dataCenters | % {
	$syslogServer = ($_.Name.ToLower() + $syslogServerSuffix)
	$syslogSetting = "tcp://$($syslogServer + ":" + $syslogServerPort)"
	write-host "Configuring $($_.Name) with $syslogSetting"
	if(test-connection $syslogServer) {
		$vmHosts = ""
		$vmHosts = $_ | get-vmhost | ? { !($_.ConnectionState -match "NotResponding") }
		echo "Configuring the following hosts"
		$vmHosts | select name, {$_.parent}, connectionstate, {$syslogServer}
		
		echo "Setting syslog server..."
		$result = $vmHosts | Set-VMHostSysLogServer -SysLogServer $syslogSetting
		echo "Enabling ESXi firewall exception..."
		$vmHosts | Get-VMHostFirewallException -Name syslog | set-vmhostfirewallexception -Enable $true
		echo "Reloading syslog service..."
		$vmHosts | Get-EsxCli | % { $_.system.syslog.reload() }			
	} else {
		echo "DNS not resolved for this syslog server name!  Not setting any hosts."
	}
}
