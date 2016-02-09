#Create VMRC Shortcuts
#Jeff Green, 2016

$user = read-host "Input the user name that will be used to connect"
$ip = read-host "Input the IP address or hostname of the vCenter server"
$mypath = read-host "Enter a path where the shortcuts should be created, for example c:\temp"

get-vm | select name,id | foreach {

$vmname = $_.name
$vmid = $_.id.replace("VirtualMachine-","")

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("c:\$mypath\Connect to $vmname.lnk")
$Shortcut.TargetPath = "vmrc://$user@$ip/?moid=$vmid"
$Shortcut.Save()

}