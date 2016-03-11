#Make-Linked-Clone.ps1
#Very simple, just to save a couple steps typing.

param ( 
	[Parameter(Mandatory=$true)]
	[string]$SourceVM,
	[Parameter(Mandatory=$true)]
	[string]$SourceSnapshot,
	[Parameter(Mandatory=$true)]
	[string]$NewVMName
)

echo "Getting source VM snapshot..."
$snap = get-snapshot -Name $SourceSnapshot -VM $SourceVM

if($snap) {
	echo "Attempting to create linked clone from $SourceVM to $NewVMName..."
	$vm = get-vm $SourceVM
	New-VM -Name $NewVMName -VM $SourceVM -Location $vm.Folder -Datastore ($vm | get-datastore)[0] -ResourcePool ($vm | Get-ResourcePool) -LinkedClone -ReferenceSnapshot $snap
} else {
	echo "Unable get source VM $SourceVM or source VM snapshot $sourceSnapshotName"
}