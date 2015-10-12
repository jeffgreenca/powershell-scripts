$dc = "MyDatacenter"
$outFile = "vm-resource-limits.csv"

get-view -viewtype virtualmachine -searchroot (get-datacenter $dc).id | select-object {$_.Name}, {$_.Config.Hardware.NumCPU}, {$_.Config.Hardware.NumCoresPerSocket}, {$_.Config.Hardware.MemoryMB}, {$_.Runtime.PowerState}, {$_.Guest.ToolsStatus}, {$_.Config.Version}, {$_.ResourceConfig.MemoryAllocation.Limit}, {$_.ResourceConfig.MemoryAllocation.Reservation}, {$_.ResourceConfig.MemoryAllocation.Shares.Level}, {$_.ResourceConfig.CpuAllocation.Limit}, {$_.ResourceConfig.CpuAllocation.Reservation}, {$_.ResourceConfig.CpuAllocation.Shares.Level} | export-csv $outFile

