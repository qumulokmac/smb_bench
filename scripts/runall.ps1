#########################################################################
# runall.ps1 - wrapper for the current fio spawn
#########################################################################

$myspawn="C:\FIO\spawn-fio-procs-" + $env:computername + ".ps1"
$mypath="H:\stage\" + $env:computername

Write-Host "Spawn script is:"$myspawn

Write-host "Removing prior config files from C:\FIO"
Get-ChildItem -Path C:\FIO | Where-Object {$_.Name -like "*.ini" -or $_.Name -like "*.bat"} | Remove-Item


$mybat="*$env:computername*"
Write-host "Copying new config files that match $mybat"
Get-ChildItem -Path $mypath | Where-Object Name -Like "$mybat" | Copy-Item  -Destination "C:\FIO" 

Write-host "Launching FIO jobs with" $myspawn

& $myspawn 
