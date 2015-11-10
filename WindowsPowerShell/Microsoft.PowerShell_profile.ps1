set-location %userprofile%\documents
$Shell = $Host.UI.RawUI
$size = $Shell.WindowSize
$size.width=120
$size.height=25
$Shell.WindowSize = $size
$size = $Shell.BufferSize
$size.width=120
$size.height=8000
$Shell.BufferSize = $size
clear-host
#Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session
#$cred = get-credential
#connect-viserver vcenter6 -allLinked -credential $cred
