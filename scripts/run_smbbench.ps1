####################################################################################################
# SMB Bench Main Script run_smbbench.ps1
#
# Author: kmac@qumulo.com
#
# Date: 20231229
#
# Descr: This script will run on the Maestro Server
#   1/ Sets up variables, accounts, etc 
#   2/ Unmounts any currently mapped drives on the worker hosts
#   3/ Mounts the A:\ drive for admin purposes
#   4/ Copy the INI files from the shared drive to the local C:\FIO directory
#   5/ Launches the workerscript on each worker host
#   6/ Waits for the jobs to complete and uploads the results to the Azure Blob Container
#
#   Prerequisites:
#      - Update the workers.conf & nodes.conf files in maestro:C:\FIO & A:\config
#      - Have already ran the script make-fiojobs-one-fio.sh [Cygwin]
#      - Ensure these directories exist: A:\FIODATA, A:\ini, A:\logs, A:\results 
#      - Change the values in the configuration section to match your job specifics/credentials
#
####################################################################################################

####################################################################################################
# User Configuration Section
####################################################################################################
$UNIQUE_RUN_IDENTIFIER = "mrcooper"
$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$password = "P@55w0rd123!"
$username = "localadmin"
$sharename = "mrcooper"

# Azure credentials: 
$AzureAccountName ="smbbench"
$Container = "fio-results"
$AzureAccountKey = "Ppfj1erZJwwH0aiXp6m4WtvFuGcHVi6AHTn94OSAcVVcRtTGQpdJ3DZVN+pJwU+tWgfp+9PwIzRj+ASt7Mbrrg=="  

####################################################################################################
# Setup [Do not change settings below this line]
####################################################################################################
$password = ConvertTo-SecureString $password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $password)
$nodes = [string[]](Get-Content $nodeconf)
$jobArray = New-Object -TypeName System.Collections.ArrayList
$maxnodes=(Get-Content $nodeconf | Measure-Object Line).Count
$DTS = Get-Date -UFormat "%Y/%m/%d/%H"

Clear-Host

foreach($myhost in Get-Content $wrkrconf) 
{
  Write-Host "Unmounting all mapped drives on: "${myhost} -ForegroundColor Green 
  Invoke-Command -Computer $myhost -scriptblock { Get-SmbMapping | Remove-SmbMapping -UpdateProfile -Force 2>$null  }
}

####################################################################################################
# Main worker host loop
####################################################################################################

foreach($myhost in Get-Content $wrkrconf) 
{ 

  Write-Host "${myhost}:" -ForegroundColor Cyan
  Write-Host "`tMounting the SMB shares on ${myhost}" -ForegroundColor Green

  $SMBServer = $nodes[0]
  $myunc = -join("\\", $SMBServer, "\", $sharename)
  $driveletter = "A"

  $session = New-PSSession -ComputerName $myhost

  $RRun = { 
      param($Cred, $myunc, $driveletter, $myhost)
      New-PSDrive -Name $driveletter -Root $myunc -Persist -PSProvider "FileSystem" -Credential $Cred | out-null
      Copy-Item "A:\INI\$myhost_*", "A:\config\*" -Destination C:\FIO

  }
  Invoke-Command -ComputerName $myhost -ScriptBlock $RRun -ArgumentList $Cred,$myunc,$driveletter,$myhost -Credential $Cred
 
  $scriptContent = Get-Content -Path 'C:\FIO\workerScript.ps1' -Raw
  $workerScript = [ScriptBlock]::Create($scriptContent)

  Write-Host "`tStarting FIO on " -NoNewline -ForegroundColor Green 

  Write-Host ${myhost} -ForegroundColor Cyan

  $job = Invoke-Command -ComputerName $myhost -ScriptBlock $workerScript -ArgumentList $Cred,$myhost,$sharename,$UNIQUE_RUN_IDENTIFIER -Credential $Cred -AsJob -JobName "${myhost}_${UNIQUE_RUN_IDENTIFIER}_fio"
  $jobArray.Add($job.Id) | Out-Null
  $job | Format-List | Out-File -Width 2000 -FilePath "C:\FIO\${myhost}_${UNIQUE_RUN_IDENTIFIER}_workerscript.out" 

}
Write-Host "`tWaiting on the fio jobs [${jobArray}] to complete`n" -ForegroundColor Blue -BackgroundColor Yellow 
Write-Host "`n`n"
Wait-Job  $jobArray | Receive-Job

################################################################################################
#  Upload results
################################################################################################


Write-Host "`nGathering results"

$Context = New-AzStorageContext -StorageAccountName $AzureAccountName -StorageAccountKey $AzureAccountKey    

foreach($myhost in Get-Content $wrkrconf)
{ 
    $FilePath = "A:\results\${myhost}_${UNIQUE_RUN_IDENTIFIER}_smbbench-results.json"
    $FileName = Split-Path -Path $FilePath -Leaf
    $BlobName = "${UNIQUE_RUN_IDENTIFIER}/${DTS}/${myhost}/${FileName}"

    Write-Host "Uploading $FilePath to [${AzureAccountName}/${Container}]/${BlobName}" -ForegroundColor Yellow 

    Set-AzStorageBlobContent -Container $Container -File $FilePath -Blob $BlobName -Context $Context -Force  | Out-File -Append -Width 2000 -FilePath "C:\FIO\${myhost}_${UNIQUE_RUN_IDENTIFIER}_azureupload.out"
} 
