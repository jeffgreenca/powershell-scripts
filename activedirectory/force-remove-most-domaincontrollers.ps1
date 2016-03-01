#force-remove-most-domaincontrollers.ps1
#Remove NTDS settings and server for all DCs in domain except the one specified
#Use case:  Lab environment where a copy of a DC with the FSMO roles is used, but the other "improperly decomissioned" DCs must be removed to allow creating new AD objects
#Based on Microsoft script to check NTDS settings, https://gallery.technet.microsoft.com/scriptcenter/Check-Active-Directory-9faf93b5

$dcToPreserve = "MYDC01"

$c = (Get-ADRootDSE).configurationNamingContext
$s = Get-ADObject -Filter {ObjectClass -eq "Server"} -SearchBase "CN=Sites,$c" -SearchScope Subtree
$s | ? { ! $_.name -eq "MYDC01" } | foreach {
  #Remove NTDS Settings
  Get-ADObject -Filter {ObjectClass -eq "nTDSDSA"} -SearchBase "$($_.DistinguishedName)" | Remove-ADObject -Recursive
  #Remove Server
  Get-ADObject $_.distinguishedname | Remove-ADObject -Recursive 
}