
###
# Configuration Section
###
$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$password = "YourPasswordHere"
$username = "YOURUSERNAME"
$sharename = "SMB_SHARENAME"

###
# Common
###
$password = ConvertTo-SecureString $password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $password)
$nodes = [string[]](Get-Content $nodeconf)

###
# Unmount existing SMB shares
###

foreach($myhost in Get-Content $wrkrconf) 
{
  Write-Host "Unmounting all mapped drives on: "$myhost
  $session = New-PSSession -ComputerName $myhost
  Invoke-Command -Computer $myhost -scriptblock { Get-SmbMapping | Remove-SmbMapping -UpdateProfile -Force 2>$null  }
}

###
# Mount share for all nodes on all hosts 
###

foreach($myhost in Get-Content $wrkrconf) 
{
  "#"*80
  Write-Host "Mapping SMB shares on: "$myhost
  "#"*80

  $maxnodes=(Get-Content $nodeconf | Measure-Object –Line).Count
  $session = New-PSSession -ComputerName $myhost

  $index = 5
  foreach ($n in Get-Content $nodeconf)
  {
    $SMBServer = $nodes[$maxnodes--]
    $myunc = -join("\\", $SMBServer, "\", $sharename)
    $driveletter = [char](65+$index++)
    $RRun = { 
      param($Cred, $myunc, $driveletter)
      New-PSDrive -Name $driveletter -Root $myunc -Persist -PSProvider "FileSystem" -Credential $Cred }
      Invoke-Command -ComputerName $myhost -ScriptBlock $RRun -ArgumentList $Cred,$myunc,$driveletter -Credential $Cred

      if ( $index -eq 26 ) 
      {
        Write-Host "You have reached drive letter "$driveletter":, you need to rethink your mounting strategy"
        exit(1)
      }
    }
  Write-Host "`n"
}
