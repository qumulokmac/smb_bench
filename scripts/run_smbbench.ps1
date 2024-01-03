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
#   6/ Waits for the jobs to complete and uploads the results to the Azure Blob AZURE_CONTAINER_NAME
#
#   Prerequisites:
#      - Update the workers.conf & nodes.conf files in maestro:C:\FIO & A:\config
#      - Change the values in smbbench_config.json match your job specifics/credentials
#
####################################################################################################

####################################################################################################
# User Configuration Section has been moved to smbbench_config.json 
####################################################################################################

$jsonString = Get-Content 'C:\cygwin64\home\localadmin\ini\smbbench_config.json' -Raw
$jsonObject = $jsonString | ConvertFrom-Json
$jsonObject.smbbench_settings | Where-Object { $_.type -eq "powershell" -or $_.type -eq "global" } | ForEach-Object {
    $envVarName = $_.name
    $envVarValue = $_.value
    Set-Variable -Name $_.name -Value $_.value
}

$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$LOCALADMIN_PASSWORD = ConvertTo-SecureString $LOCALADMIN_PASSWORD -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($LOCALADMIN_USERNAME, $LOCALADMIN_PASSWORD)
$nodes = [string[]](Get-Content $nodeconf)
$jobArray = New-Object -TypeName System.Collections.ArrayList
$maxnodes=(Get-Content $nodeconf | Measure-Object Line).Count

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
  $myunc = -join("\\", $SMBServer, "\", $SMB_SHARE_NAME)
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

  $job = Invoke-Command -ComputerName $myhost -ScriptBlock $workerScript -ArgumentList $Cred,$myhost,$SMB_SHARE_NAME,$UNIQUE_RUN_IDENTIFIER -Credential $Cred -AsJob -JobName "${myhost}_${UNIQUE_RUN_IDENTIFIER}"
  $jobArray.Add($job.Id) | Out-Null
  $job | Format-List | Out-File -Width 2000 -FilePath "C:\FIO\${myhost}_${UNIQUE_RUN_IDENTIFIER}_workerscript.out" 

}
Write-Host -NoNewline "`tWaiting for ALL fio jobs " -ForegroundColor Green
Write-Host -NoNewline "[${jobArray}]"  -ForegroundColor Magenta
Write-Host " to complete`n`n"

Wait-Job  $jobArray | Receive-Job

################################################################################################
#  Upload results
################################################################################################

Write-Host "`nGathering results"

$Context = New-AzStorageContext -StorageAccountName $AZURE_ACCOUNT_NAME -StorageAccountKey $AZURE_ACCOUNT_KEY    
$DTS = Get-Date -UFormat "%Y-%m-%d-%H%M"

foreach($myhost in Get-Content $wrkrconf)
{ 
    ###
    # Uploading the result json file adding JPC to the blob key 
    ###

    $FilePath = "A:\results\${myhost}_${UNIQUE_RUN_IDENTIFIER}_smbbench-results.json"
    $FileName = Split-Path -Path $FilePath -Leaf

    $jsonContent = Get-Content -Raw -Path $FilePath
    $jsonObject = $jsonContent | ConvertFrom-Json
    $JPC = ($jsonObject.jobs.jobname).Count
	$BlobName = "${UNIQUE_RUN_IDENTIFIER}/${DTS}/${JPC}-JPC/${myhost}/${myhost}_${DTS}_${UNIQUE_RUN_IDENTIFIER}_${JPC}-JPC-results.json"

    Write-Host "Uploading $FilePath to [${AZURE_ACCOUNT_NAME}/${AZURE_CONTAINER_NAME}]/${BlobName}" -ForegroundColor Green 
    Set-AzStorageBlobContent -Container $AZURE_CONTAINER_NAME -File $FilePath -Blob $BlobName -Context $Context -Force  | Out-File -Append -Width 2000 -FilePath "C:\FIO\${myhost}_${UNIQUE_RUN_IDENTIFIER}_azureupload.out"

    ###
    # Uploading the INI file for future reference
    ###
    $FilePath = "A:\ini\${myhost}_${UNIQUE_RUN_IDENTIFIER}_smbbench.ini"
    $FileName = Split-Path -Path $FilePath -Leaf
	$BlobName = "${UNIQUE_RUN_IDENTIFIER}/${DTS}/${JPC}-JPC/${myhost}/${myhost}_${DTS}_${UNIQUE_RUN_IDENTIFIER}_${JPC}-JPC-fio.ini"

    Write-Host "Uploading $FilePath to [${AZURE_ACCOUNT_NAME}/${AZURE_CONTAINER_NAME}]/${BlobName}" -ForegroundColor Yellow 
    Set-AzStorageBlobContent -Container $AZURE_CONTAINER_NAME -File $FilePath -Blob $BlobName -Context $Context -Force  | Out-File -Append -Width 2000 -FilePath "C:\FIO\${myhost}_${UNIQUE_RUN_IDENTIFIER}_azureupload.out"


} 
 
