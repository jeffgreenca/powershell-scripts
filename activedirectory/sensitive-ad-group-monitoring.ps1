#sensitive-ad-group-monitoring.ps1
#Jeff Green 2016 jeffgreenca
#Check group membership for changes, query specific set of domain controllers

$dcList = @('dc1.lab.local','dc2.lab.local')
$monitoredGroup = "sensitiveADGroup"
$alertRecipEmail = "specific-administrator@lab.local"
$alertFromEmail = "alerter@lab.local"
$smtpServer = "1.2.3.4"

while($true) {
	$alerts = @()
	$adds = @()
	$removes = @()
	
	try 
	{
		$lastUserList = import-clixml lastuserlist.xml
	}
	catch
	{
		$alerts += "Error reading from lastuserlist.xml, it may not exist or may be corrupt.  This is only normal on the first run ever."
	}
	
	$userList = @()

	foreach($dc in $dcList) {
		try {
			$members = Get-ADGroup $monitoredGroup -Server $dc | Get-ADGroupMember
		}
		catch {
			$alerts += "Error querying $dc for group $monitoredGroup membership"
		}
		
		foreach ($member in $members) {
			if ($userList -contains $member.distinguishedname) {
				#User already in new list
			} else {
				$userList += $member.distinguishedname
			}
		}
		
		try {
			$nestedMembers = Get-ADGroup $monitoredGroup -Server $dc | Get-AdGroupMember | ? objectclass -ne "user"
		}
		catch {
			$alerts += "Error querying $dc for group $monitoredGroup membership consisting of groups"
		}
	}

	if($userList -and $lastuserlist) {
		#Compare lastUserList to userList
		$adds		= diff $lastUserList $userList -passthru | ? sideindicator -eq "=>"
		$removes	= diff $lastuserlist $userList -passthru | ? sideindicator -eq "<="
	} elseif ($lastuserlist) {
		$removes = $lastUserList
	} elseif ($userList) {
		$adds = $userList
	} else {
		#No members either now or previously
	}
	
	#Log alerts
	$alerts  | % { write-output "$(get-date -f "yyyy-MM-dd hh:mm:ss") GROUP-MONITOR ALERT $_" >> $logfile }
	
	#Log adds and removes
	$adds    | % { write-output "$(get-date -f "yyyy-MM-dd hh:mm:ss") GROUP-MONITOR GROUP:$monitoredGroup DETECTED-MEMBER-ADDED $_" >> $logfile }
	$removes | % { write-output "$(get-date -f "yyyy-MM-dd hh:mm:ss") GROUP-MONITOR GROUP:$monitoredGroup DETECTED-MEMBER-REMOVED $_" >> $logfile }
	
	#Conditions under which an alert should be sent
	if($adds -or $removes -or $alerts) {
		$body = @()
		$body += "ALERTS"
		$body += $alerts | sort
		$body += "`r`nAdded Members"
		$body += $adds | sort
		$body += "`r`nRemoved Members"
		$body += $removes | sort
		$body += "`r`n`r`nCurrent Membership"
		$body += $userList
		$body += "`r`n`r`nMembers that are Groups"
		$body += $nestedMembers
		$body += "`r`n`r`nPrevious Membership"
		$body += $lastuserlist
		$body += "`r`n`r`n Message end."
		
		Send-MailMessage -SmtpServer $smtpServer -From $alertFromEmail -To $alertRecipEmail -Body ($body -join "`r`n") -Subject "AD Monitor - $monitoredGroup Security Alert"
	}
	
	$userList | Export-Clixml lastuserlist.xml
	start-sleep 5
}