get-datacenter | foreach {
  $dc = $_.Name
  $_ | get-cluster | foreach {
    $cluster = $_.Name
    $count = (get-view -viewtype "VirtualMachine" -Property Name -Filter @{"Runtime.PowerState"="PoweredOn"} -SearchRoot (get-view $_).moref | Measure-Object).Count
    write-output "$dc, $cluster, $count"
  }
} 