#See https://support.microsoft.com/en-us/help/3042553/ms15-034-vulnerability-in-http.sys-could-allow-remote-code-execution-april-14,-2015
function Check-httpsys-version {
       $info = gci c:\windows\system32\drivers\http.sys | select -ExpandProperty versioninfo | select *
       $version = @($info.FileMajorPart, $info.FileMinorPart, $info.FileBuildPart, $info.FilePrivatePart) -join "."

       $list = @{ "6.1.7601.18772" = "2008 R2 Patch";
                             "6.1.7601.22976" = "2008 R2 Patch";
                             "6.2.9200.17285" = "2012Patch";
                             "6.2.9200.21401" = "2012 Patch";
                             "6.3.9600.17712" = "2012 R2 Patch" }
                             
       $list.add($version, "This System")

       $list.GetEnumerator() | Sort -Property Name
}

Check-httpsys-version
