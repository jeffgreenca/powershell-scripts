#citrix_user_prune_report.ps1
#Find disabled and expired user accounts still assigned to a virtual desktop
#Jeff Green 2013-12-27

$outputdirectory =  "C:\logs\"
$outputFile = $outputdirectory + ( (get-date -Format yyyy-MM-dd).tostring() + " Citrix User Prune Report.csv" )

add-pssnapin quest.activeroles.*
add-pssnapin citrix.*

#Get lists of expired and disabled users
$expired_users = get-qaduser -ExpiredFor 0 -sizelimit 0 | select-object ntaccountname,accountisdisabled,accountexpirationstatus
$disabled_users = get-qaduser -Disabled -sizelimit 0 | select-object ntaccountname,accountisdisabled,accountexpirationstatus

#Build list of users assigned to desktops
$assigned_users = @()
get-brokerdesktop -maxrecordcount 9999 | foreach {
  $vm = $_
  foreach($username in $vm.AssociatedUserNames) {
	$prop = @{'Machine'=$vm.MachineName; 'Username'=$username}
	$assigned_users += new-object -typename psobject -property $prop
  }
}

$users_to_prune = @()
$assigned_users | foreach {
  $active_user = $_
  $prune_user = ""
  $is_inactive = 0
  $expired_users | foreach {
		if ($active_user.username -eq $_.ntaccountname) {
			$is_inactive = 1
			$prune_user = $_
		}
	}
  if($is_inactive -eq 0) {
	  $disabled_users | foreach {
			if ($active_user.username -eq $_.ntaccountname) {
				$is_inactive = 1
				$prune_user = $_
			}
		}
  }
  
  if ($is_inactive -eq 1) {
	$prop = @{'Username'=$prune_user.ntaccountname;'Machine'=$active_user.machine;'AccountIsDisabled'=$prune_user.accountisdisabled;'AccountExpirationStatus'=$prune_user.accountexpirationstatus}
	$users_to_prune += new-object -type psobject -property $prop
  }
  
}

$users_to_prune | export-csv users_to_prune.txt
