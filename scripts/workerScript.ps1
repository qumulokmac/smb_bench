####################################################################################################
# SMB Bench Worker Script
#
# Author: kmac@qumulo.com
#
# Date: 20231229
#
# Descr: This script will run on each of the worker hosts
#   1/ Mount's the A:\ drive for administrative actions
#   2/ Mount an SMB share to letter drives for each node in the cluster
#   3/ Launch FIO 
#   4/ Copy the results to a shared drive
#
####################################################################################################
param($Cred, $myhost, $sharename, $runname)
 
"#"*80
Write-Host "Mapping SMB shares on $myhost"  -ForegroundColor yellow
"#"*80

$index = 5
$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$maxnodes=(Get-Content $nodeconf | Measure-Object –Line).Count
$nodes = [string[]](Get-Content $nodeconf)

####################################################################################################
      
foreach ($node in Get-Content $nodeconf) 
{
    $SMBServer = $nodes[$maxnodes--]
    $myunc = "\\${SMBServer}\${sharename}"
    $driveletter = [char](65+$index++)

    Write-Host "${myhost}`: Mounting SMB share $myunc on ${driveletter}`:" -ForegroundColor yellow
    New-PSDrive -Name $driveletter -Root $myunc -Persist -PSProvider "FileSystem" -Credential $Cred
}

Write-Host "`n${myhost}: Session mapped drives:`n" -ForegroundColor yellow
# Net Use
Write-Host "`nLaunching FIO on $myhost`n" -ForegroundColor yellow

####################################################################################################

$ResultFileName = "C:\FIO\${myhost}_${runname}_smbbench-results.json"
$IniFileName = "C:\FIO\${myhost}_${runname}_smbbench.ini"

$JPC = (Get-Content $IniFileName | Select-String "\[job" -AllMatches).Matches.Count

$command = "cmd.exe /c c:\FIO\fio-master\fio.exe --thread --output=`"$ResultFileName`" --output-format=json C:\FIO\${myhost}_${runname}_smbbench.ini"

Invoke-Expression $command
Copy-Item -Path $ResultFileName -Destination "F:\results"


