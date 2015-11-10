#Create some Windows DHCP scopes on Windows 2012 R2
#Assumes /24 for all networks, range is x.x.x.20 to x.x.x.250
#Assumes x.x.x.1 = default route
#Execute on DHCP server

#CSV file in format
#ID,Description
#10.10.10.0,MyScope1
#10.10.11.0,MyScope2

import-csv "source.csv" | foreach {
 $subnetPrefix = @(($_.id -split "\.")[0] , ($_.id -split "\.")[1] , ($_.id -split "\.")[2]) -join "."
 Add-DhcpServerv4Scope -Name $_.Description -StartRange $($subnetPrefix + ".20") -EndRange $($subnetPrefix + ".250") -SubnetMask 255.255.255.0
 Set-DhcpServerv4OptionValue -OptionId 3 -Value $($subnetprefix + ".1") -ScopeId $($subnetprefix + ".0")
}
