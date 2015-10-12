#Determine if any powered on VMs are syncing time with the host operating system
get-view -viewtype virtualmachine | select name, @{Name="Powerstate";Expression={$_.summary.runtime.powerstate}} ,  @{name="timesync";Expression={$_.config.tools.synctimewithhost}}  | sort -desc timesync,powerstate, name

#For each host
write-output "Hostname, System Time, Current Local Time, Configured TimeZone, Configured NTP Servers"
get-view -viewtype hostsystem | foreach {
  $a = $_.name
  $b = (get-view -id $_.configmanager.datetimesystem).querydatetime() | get-date -Format "HH:mm:ss"
  $c = get-date -Format "HH:mm:ss"
  $d = (get-view -id $y[0].configmanager.datetimesystem).datetimeinfo.timezone.name
  $e = ((get-view -id $_.configmanager.datetimesystem).datetimeinfo.ntpconfig.server -join "  ")
  write-output ( ($a, $b, $c, $d, $e) -join "," )
}