$list = import-csv hp-simpleinventory-oa-list.txt
$pw = read-host "Enter common Administrator password (warning - will be echo'd to screen)"

foreach($oa in $list) {
	echo "y" | plink Administrator@$($oa.ip) -pw $pw "exit"
}