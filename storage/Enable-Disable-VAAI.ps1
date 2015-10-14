#Enable-Disable-VAAI.ps1, JG 2015
#Enables or disables VAAI for all hosts in a specific vSphere logical datacenter.
#
#Per VMware KB http://kb.vmware.com/kb/1033665 this does not require a host reboot
#To disable VAAI:
# ./enable-disable-vaai.ps1 -DisableVAAI -vCenter MyServer -Datacenter MyDatacenter
#
#To enable VAAI:
# ./enable-disable-vaai.ps1 -EnableVAAI -vCenter MyServer -Datacenter MyDatacenter

[cmdletbinding(SupportsShouldProcess=$true)]
param (
	[Parameter(mandatory=$true)][string]$vcenter,
	[Parameter(mandatory=$true)][string]$datacenter,
	[Parameter(Mandatory=$true,ParameterSetName="DisableMode")][switch]$DisableVAAI,
	[Parameter(Mandatory=$true,ParameterSetName="EnableMode")][switch]$EnableVAAI
)

if( $DisableVAAI ) { $value = 0 }
if( $EnableVAAI ) { $value = 1 }


Connect-VIServer $vcenter

Get-Datacenter $datacenter | Get-VMHost | foreach {
  Set-VMHostAdvancedConfiguration -VMHost $_ -Name DataMover.HardwareAcceleratedMove -Value $value
  Set-VMHostAdvancedConfiguration -VMHost $_ -Name DataMover.HardwareAcceleratedInit -Value $value
  Set-VMHostAdvancedConfiguration -VMHost $_ -Name VMFS3.HardwareAcceleratedLocking -Value $value
}
