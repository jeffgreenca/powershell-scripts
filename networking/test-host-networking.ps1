<#
.SYNOPSIS
	Run various networking tests on all hosts in a cluster, using a test VM.
	Requires use of distributed virtual switch.
.DESCRIPTION
	Using a Microsoft Windows test VM, iterate through a list of port groups and 
	subnets (specified in the CSV input file) and run tests.
	Testing method involves assigning the test VM to a specific port group or VLAN ID,
	assigning IP information and running a test ping.
	
	Currently, performs the following tests:		
		Test connectivity with VM on each port group
		Test connectivity for each VLAN ID on each uplink on each host in the cluster.
.PARAMETER csvFile
	Input - CSV file containing IP info to test.  Must contain the following columns.
		Port Group - a valid port group name available on the specified DVS
		Source IP - IP to assign to the test VM for this port group
		Gateway IP - Gateway to assign to the test VM
		SubnetMask - Subnet mask to assign to test VM
		Test IP - IP address to target for ping test
		
	This is example data:
	PortGroup,SourceIP,GatewayIP,SubnetMask,TestIP
	PG_NET1,10.10.101.55,10.10.101.1,255.255.255.0,10.0.0.1
	PG_NET2,10.10.102.55,10.10.102.1,255.255.255.0,10.0.0.1
.PARAMETER creds
	The username and password for the guest OS of the test VM.
.PARAMETER vmName
	A powered on Windows OS virtual machine with UAC disabled and VMware tools running.
	Note this VM will be vMotioned, network reassigned, and IP address changed by this script!
.EXAMPLE
	.
.NOTES
	Author: Jeff Green
	Date: July 10, 2015

#>

param
(
	[Parameter(Mandatory=$true)]
	[string]$clusterName,
	[Parameter(Mandatory=$true)]
	[string]$dvsName,
	[Parameter(Mandatory=$true)]
	[pscredential]$creds,
	[Parameter(Mandatory=$true)]
	[string]$vmName,
	[Parameter(Mandatory=$true)]
	[string]$csvFile,
	[int]$timesToPing = 10,
	[int]$pingReplyCountThreshold = 8,
	[Parameter(Mandatory=$true)]
	[string]$resultFile
)

#Setup

# Configure internal variables
$trustVMInvokeable = $false #this is to speed development only.  Set to false.
$testResults = @()
$testPortGroupName = "HostNetworking_VlanID_Per_Link_Connectivity_Testing_BSG"
$data = import-csv $csvFile
$cluster = get-cluster $clusterName
$dvs = get-vdswitch $dvsName
$vm = get-vm $vmName

#We'll use this later to reset the VM back to its original network location
$originalVMPortGroup = ($vm | get-Networkadapter)[0].networkname

#Test if Invoke-VMScript works
if(-not $trustVMInvokeable) {
	if (-not (Invoke-VMScript -ScriptText "echo test" -VM $vm -GuestCredential $creds).ScriptOutput -eq "test") {
		write-output "Unable to run scripts on test VM guest OS!"
		return 1
	}
}

#Define Test Functions
function TestPing($ip, $count, $mtuTest) {
	if($mtuTest) {
		$count = 4 #Less pings for MTU test
		$pingReplyCountThreshold = 3 #Require 3 responses for success on MTU test.  Note this scope is local to function and will not impact variable for future run.
		$script = "ping -f -l 8972 -n $count $ip"
	} else {
		$script =  "ping -n $count $ip"
	}
	
	write-host "Script to run: $script"
	$result = Invoke-VMScript -ScriptText $script -VM $vm -GuestCredential $creds
	
	#parse the output for the "received packets" number
	$rxcount = (( $result.ScriptOutput | ? { $_.indexof("Packets") -gt -1 } ).Split(',') | ? { $_.indexof("Received") -gt -1 }).split('=')[1].trim()
	
	#if we received enough ping replies, consider this a success
	$success = ([int]$rxcount -gt $pingReplyCountThreshold) 
	
	#however there is one condition where this will be a false positive... gateway reachable but destination not responding
	if ( $result.ScriptOutput | ? { $_.indexof("host unreach") -gt -1 } ) {
		$success = $false
		$rxcount = 0;
	}
	
	write-host "Full results of ping test..."
	write-host $result.ScriptOutput
	
	return @($success, $count, $rxcount);
}

function SetGuestIP($ip, $subnet, $gw) {
  $script = @"
	`$iface = (gwmi win32_networkadapter -filter "netconnectionstatus = 2" | select -First 1).interfaceindex
	netsh interface ip set address name=`$iface static $ip $subnet $gw
	netsh interface ipv4 set subinterface `$iface mtu=9000 store=active
"@
  write-host "Script to run: " + $script
  return (Invoke-VMScript -ScriptText $script -VM $vm -GuestCredential $creds)
}

#Tests
# Per Port Group Tests  (Test each port group)

$vmhost = $vm.vmhost
foreach($item in $data) {
	if($testPortGroup = $dvs | get-vdportgroup -name $item.PortGroup) {
		($vm | get-Networkadapter)[0] | Set-NetworkAdapter -Portgroup $testPortGroup -confirm:$false
		if( SetGuestIP $item.SourceIP $item.SubnetMask $item.GatewayIP ) {
			echo ("Set Guest IP to " + $item.SourceIP)
			
			#Run normal ping test
			$pingTestResult = TestPing $item.TestIP $timesToPing $false
			#Add to results
			$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
			$thisTest["Host"] = $vmhost.name
			$thisTest["PortGroupName"] = $testPortGroup.name
			$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
			$thisTest["SourceIP"] = $item.SourceIP
			$thisTest["DestinationIP"] = $item.TestIP
			$thisTest["Result"] = $pingTestResult[0].tostring()
			$thisTest["TxCount"] = $pingTestResult[1].tostring()
			$thisTest["RxCount"] = $pingTestResult[2].tostring()
			$thisTest["JumboFramesTest"] = ""
			$thisTest["Uplink"] = $thisUplink

			$testResults += new-object -typename psobject -Property $thisTest

			#DISABLED JUMBO FRAMES TEST!
			if($false) {
				#Run jumbo frames test
				$pingTestResult = TestPing $item.TestIP $timesToPing $true
				#Add to results
				$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
				$thisTest["Host"] = $vmhost.name
				$thisTest["PortGroupName"] = $testPortGroup.name
				$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
				$thisTest["SourceIP"] = $item.SourceIP
				$thisTest["DestinationIP"] = $item.TestIP
				$thisTest["Result"] = $pingTestResult[0].tostring()
				$thisTest["TxCount"] = $pingTestResult[1].tostring()
				$thisTest["RxCount"] = $pingTestResult[2].tostring()
				$thisTest["JumboFramesTest"] = ""
				$thisTest["Uplink"] = $thisUplink
				
				$testResults += new-object -typename psobject -Property $thisTest
			}

			
		} else {
			$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
			$thisTest["PortGroupName"] = $testPortGroup.name
			$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
			$thisTest["SourceIP"] = $item.SourceIP
			$thisTest["DestinationIP"] = $item.GatewayIP
			$thisTest["Result"] = "false - error setting guest IP"
			$testResults += new-object -typename psobject -Property $thisTest
		}
	} else {
		$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
			$thisTest["PortGroupName"] = $item.PortGroup
			$thisTest["Result"] = "false - could not find port group"
			$testResults += new-object -typename psobject -Property $thisTest
	}
}

# Per Host Tests (Test Each Link for Each VLAN ID on each host)
$testPortGroup = $null
($testPortGroup = new-vdportgroup $dvs -Name $testPortGroupName -ErrorAction silentlyContinue) -or ($testPortGroup = $dvs | get-vdportgroup -Name $testPortGroupName)
($vm | get-Networkadapter)[0] | Set-NetworkAdapter -Portgroup $testPortGroup -confirm:$false

$cluster | get-vmhost | ? {$_.ConnectionState -match "connected" } | foreach {
	$vmhost = $_
	#Migrate VM to new host
	if(Move-VM -VM $vm -Destination $vmhost) {
	
		foreach($item in $data) {
			#Configure test port group VLAN ID for this particular VLAN test, or clear VLAN ID if none exists
			$myVlanId = $null
			$myVlanId = (get-vdportgroup -name $item.PortGroup).VlanConfiguration.Vlanid
			if($myVlanId) {
				$testPortGroup = $testPortGroup | Set-VDVlanConfiguration -Vlanid $myVlanId
			} else {
				$testPortGroup = $testPortGroup | Set-VDVlanConfiguration -DisableVlan
			}
			
			
			if( SetGuestIP $item.SourceIP $item.SubnetMask $item.GatewayIP ) {
				echo ("Set Guest IP to " + $item.SourceIP)
				
				#Run test on each uplink individually
				$uplinkset = ( ($testPortGroup | Get-VDUplinkTeamingPolicy).ActiveUplinkPort + ($testPortGroup | Get-VDUplinkTeamingPolicy).StandbyUplinkPort ) | sort
				foreach($thisUplink in $uplinkset) {
					#Disable all uplinks from the test portgroup
					$testPortGroup | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -UnusedUplinkPort $uplinkset
					#Enable  only this uplink for the test portgroup
					$testPortGroup | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $thisUplink

					#Run normal ping test
					$pingTestResult = TestPing $item.TestIP $timesToPing $false
					#Add to results
					$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
					$thisTest["Host"] = $vmhost.name
					$thisTest["PortGroupName"] = $testPortGroup.name
					$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
					$thisTest["SourceIP"] = $item.SourceIP
					$thisTest["DestinationIP"] = $item.TestIP
					$thisTest["Result"] = $pingTestResult[0].tostring()
					$thisTest["TxCount"] = $pingTestResult[1].tostring()
					$thisTest["RxCount"] = $pingTestResult[2].tostring()
					$thisTest["JumboFramesTest"] = ""
					$thisTest["Uplink"] = $thisUplink

					$testResults += new-object -typename psobject -Property $thisTest

					#DISABLED JUMBO FRAMES TEST!
					if($false) {
						#Run jumbo frames test
						$pingTestResult = TestPing $item.TestIP $timesToPing $true
						#Add to results
						$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
						$thisTest["Host"] = $vmhost.name
						$thisTest["PortGroupName"] = $testPortGroup.name
						$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
						$thisTest["SourceIP"] = $item.SourceIP
						$thisTest["DestinationIP"] = $item.TestIP
						$thisTest["Result"] = $pingTestResult[0].tostring()
						$thisTest["TxCount"] = $pingTestResult[1].tostring()
						$thisTest["RxCount"] = $pingTestResult[2].tostring()
						$thisTest["JumboFramesTest"] = ""
						$thisTest["Uplink"] = $thisUplink
						
						$testResults += new-object -typename psobject -Property $thisTest
					}					
				}
				
				$testPortGroup | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort ($uplinkset | sort)
				
			} else {
				$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
				$thisTest["PortGroupName"] = $testPortGroup.name
				$thisTest["VlanID"] = $testPortGroup.vlanconfiguration.vlanid
				$thisTest["SourceIP"] = $item.SourceIP
				$thisTest["DestinationIP"] = $item.GatewayIP
				$thisTest["Result"] = "false - error setting guest IP"
				$testResults += new-object -typename psobject -Property $thisTest
			}
		}
	} else {
		$thisTest = [ordered]@{"VM" = $vm.name; "TimeStamp" = (Get-Date -f s); "Host" = $vmhost.name;}
		$thisTest["Result"] = "false - unable to vMotion VM to this host"
		$testResults += new-object -typename psobject -Property $thisTest
	}
}

#Clean up
($vm | get-Networkadapter)[0] | Set-NetworkAdapter -Portgroup (get-vdportgroup $originalVMPortGroup) -confirm:$false

Remove-VDPortGroup -VDPortGroup $testPortGroup -confirm:$false

#Future Test Ideas
#Query driver/firmware for each host's network adapters ?

#Show Results
$testResults | ft
$testResults | Export-CSV -notypeinformation $resultFile
