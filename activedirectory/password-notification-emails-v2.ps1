add-pssnapin quest.activeroles.*

$currentDate = Get-Date

$logDir = "C:\scripts\logs\"
$logFile =  $logDir + $currentDate.ToString("yyyy-MM-dd-HH-mm") + ".log"

write-output "SAMAccountName,Mail,PasswordExpiresDate,AlertType" > $logFile

get-qaduser -sizelimit 0 -enabled:$true -passwordneverexpires:$false | ? { ($_.AccountIsExpired -eq $false) -and ($_.PasswordIsExpired -eq $false) -and ($_.UserMustChangePassword -eq $false) } | select firstname,samaccountname,mail,passwordexpires | foreach {
	if(($_.passwordexpires - $currentDate).days -in @(14,7,5,4,3,2) ) {
		if ($_.mail -eq $null) {
			write-output ( $_.samaccountname + "," + $_.mail + "," + $_.passwordexpires + ",No Mail attribute defined, no alert being sent") >> $logFile
		}
		else {
			write-output ( $_.samaccountname + "," + $_.mail + "," + $_.passwordexpires + ",Send Regular Alert" ) >> $logFile
			Send-MailMessage -body ($_.FirstName + ", your password is expiring soon (" + $_.passwordexpires.ToString("dddd, M/d \a\t hh:mmtt") + ").  Please change your password at your next opportunity to avoid being locked out of your account.`r`n`r`n  If you have any questions about this process, please contact IT support.") -subject "Alert - Your Password Expires Soon" -to $_.mail -from "noreply@companyname.com" -smtpserver smtp.st.com
		}
	}
	if( ($_.passwordexpires - $currentDate) -lt (new-timespan -hours 48) ) {
		if ($_.mail -eq $null) {
			write-output ( $_.samaccountname + "," + $_.mail + "," + $_.passwordexpires + ",No Mail attribute defined, no alert being sent") >> $logFile
		}
		else {
			write-output ( $_.samaccountname + "," + $_.mail + "," + $_.passwordexpires + ",Send Immediate Action Alert") >> $logFile
			Send-MailMessage -body ($_.FirstName + ", your password will expire within 48 hours (" + $_.passwordexpires.ToString("dddd, M/d \a\t hh:mmtt") + ").  Please change your password IMMEDIATELY to avoid being locked out of your account.  If your password expires, you will need to contact IT support to have your password reset.`r`n`r`n  If you have any questions about this process, please contact IT support.") -subject "ACTION REQUIRED - Password Change Required!" -to $_.mail -from "noreply@companyname.com" -smtpserver smtp.st.com
		}
	}
}

#purge logs older than 90 days
gci ($logDir + "*.log") | ? { ((Get-date) - $_.creationtime).days -gt 90 } | Remove-Item

write-output ("Finished script execution at " + (Get-Date) ) >> $logFile