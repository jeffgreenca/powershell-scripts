#Jeff Green 5/1/2015
#Constants
$global:org = "ABC_vSphere"
$global:dmzExtranetSwitchName = "DMZ-Extranet"
$global:internalSwitchName = "Internal"
function Check-VLAN ($vlanId, $vlanName, $vlanGroup) {
  #This is returning double true, I am not sure why
  $i = 0
  #Check if VLAN exists as expected
  $LanCloud = get-ucslancloud
  
  $existingVLAN = get-ucsvlan -LanCloud $LanCloud -Id $vlanId -Name $vlanName
  if($existingVLAN) {
	$g = Get-UcsFabricNetGroup -Name $vlanGroup
	if ($g) {
		if ($g | Get-UcsFabricPooledVlan -Name $vlanName) {
			switch($vlanGroup) {
			 $global:dmzExtranetSwitchName {
				$adapters = Get-UcsVnicTemplate -Org $global:org | ? {$_.Name -match "dmz"}
			 }
			 $global:internalSwitchName { 
				$adapters = Get-UcsVnicTemplate -Org $global:org | ? {$_.Name -match "int"}
			 }
			 default { }
			}
			if ($adapters) {
				$adapters | % { if ( -not ($_ | Get-UcsVnicInterface -name $vlanName) ) { return $false } }
				return $true
			}
		}
	}
  }
  
  return $false
}

function IsUsingVLANGroups {
	#Check if VLAN Groups are Defined
	return ( (get-ucsfabricnetgroup).count -gt 0 )
}

function Remove-VLAN {
}

function Create-VLAN ($vlanId, $vlanName, $vlanGroup) {
	#Create VLAN
	$LanCloud = get-ucslancloud
	$newVLAN = add-ucsvlan -LanCloud $LanCloud -Id $vlanId -Name $vlanName
	
	if($newVLAN) {
		#Create FabricPooledVlan
		$g = Get-UcsFabricNetGroup -Name $vlanGroup
		$g | Add-UcsFabricPooledVlan -Name $vlanName
	
		#Assign to adapters
		switch($vlanGroup) {
		 $global:dmzExtranetSwitchName {
			$adapters = Get-UcsVnicTemplate -Org $global:org | ? {$_.Name -match "dmz"}
		 }
		 $global:internalSwitchName { 
			$adapters = Get-UcsVnicTemplate -Org $global:org | ? {$_.Name -match "int"}
		 }
		 default { 
			write-host "Error unexpected VLAN Group (Switch) name"
			return 
			}
		}

		if ($adapters)
		{
		  $adapters | % { $_ | Add-UcsVnicInterface -Name $vlanName }
		}
	} else {
		write-host "Create VLAN failed to create VLAN object, exiting..."
	}
}

#function Process-VLAN (

#Inputs
$vlanId = 2001
$vlanName = "VL2001_Test_VLAN"
$vlanGroup = "DMZ-Extranet"

write-host "Result of Check-VLAN: " (Check-VLAN $vlanid $vlanName $vlanGroup)

#Add-VLAN $vlanid $vlanName $vlanGroup
