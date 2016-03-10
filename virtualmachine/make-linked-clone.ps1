#Make-Linked-Clone.ps1
#Very simple, just to save a couple steps typing.

param ( 
	[Parameter(Mandatory=$true)]
	[string]$strSourceVM,
	[Parameter(Mandatory=$true)]
	[string]$strSourceSnapshot,
	[Parameter(Mandatory=$true)]
	[string]$strNewVM
)

echo "Getting source VM snapshot..."
$snap = get-snapshot -Name $strSourceSnapshot -VM $strSourceVM

if($snap) {
	echo "Attempting to create linked clone from $strSourceVM to $strNewVM..."
	$vm = get-vm $strSourceVM
	New-VM -Name $strNewVM -VM $strSourceVM -Location $vm.Folder -Datastore ($vm | get-datastore)[0] -ResourcePool ($vm | Get-ResourcePool) -LinkedClone -ReferenceSnapshot $snap
} else {
	echo "Unable get source VM $strSourceVM or source VM snapshot $sourceSnapshotName"
}