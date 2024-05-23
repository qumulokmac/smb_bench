<#
.SYNOPSIS
This script monitors and manages 'fio' processes on remote computers.

.DESCRIPTION
Developed by Kevin McDonald (kmac@qumulo.com) and Shiela (an AI developed by OpenAI) on May 18, 2024, and is intended to be used with the smb_bench harness found at https://github.com/qumulokmac/smb_bench.
This script performs the following functions:
1. Reads a list of remote computers from a specified configuration file.
2. Executes commands on each remote computer to check the status of 'fio' processes.
3. Provides options to either kill the 'fio' processes or display their status.
4. Supports output in CSV, JSON, or TABLE format.
5. Runs in a loop with a configurable sleep time between iterations.

.PARAMETER Action
Specifies the action to be performed: 'status' or 'kill'.

.PARAMETER ConfigFilePath
Specifies the path to the configuration file containing the list of remote computers.

.PARAMETER OutputFormat
Specifies the output format: 'CSV', 'JSON', or 'TABLE'.

.PARAMETER OutputFilePath
Specifies the file path for the output when CSV or JSON format is chosen.

.PARAMETER SleepTime
Specifies the time to sleep between iterations, in seconds.

.NOTES
Created on May 18, 2024.
#>

# Configurable variables
$Action = 'status' # Set to 'status' or 'kill'
$ConfigFilePath = 'C:\FIO\workers.conf'
$OutputFormat = 'TABLE' # Set to 'CSV', 'JSON', or 'TABLE'
$OutputFilePath = 'C:\FIO\output.txt' # File path for CSV or JSON output
$SleepTime = 30 # Time to sleep between iterations in seconds

# Validate the action variable
if (-not $Action) {
    Write-Host "Please specify an action: 'status' or 'kill'"
    exit
}

if ($Action -ne 'status' -and $Action -ne 'kill') {
    Write-Host "Invalid action specified. Use 'status' or 'kill'"
    exit
}

# Validate the output format variable
if ($OutputFormat -ne 'CSV' -and $OutputFormat -ne 'JSON' -and $OutputFormat -ne 'TABLE') {
    Write-Host "Invalid output format specified. Use 'CSV', 'JSON', or 'TABLE'"
    exit
}

while ($true) {
    $processInfo = @()
    $remoteComputers = Get-Content -Path $ConfigFilePath

    foreach ($computer in $remoteComputers) {
        try {
            $processes = Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-CimInstance -ClassName Win32_Process -Filter "Name = 'fio.exe'" | Select-Object ProcessId, Name, UserModeTime, KernelModeTime, CreationDate, ReadTransferCount, WriteTransferCount, ReadOperationCount, WriteOperationCount
            }

            if ($processes) {
                if ($Action -eq 'kill') {
                    Write-Host "$(Get-Date) - Killing 'fio' processes on $($computer)"
                    Invoke-Command -ComputerName $computer -ScriptBlock {
                        Get-Process -Name 'fio' | Stop-Process -Force
                    }
                } elseif ($Action -eq 'status') {
                    foreach ($process in $processes) {
                        $cpuTime = "{0:N2}" -f (($process.UserModeTime + $process.KernelModeTime) / 10000000)
                        $readBytes = "{0:N0}" -f $process.ReadTransferCount
                        $writeBytes = "{0:N0}" -f $process.WriteTransferCount
                        $readOps = $process.ReadOperationCount
                        $writeOps = $process.WriteOperationCount

                        try {
                            $startTime = [datetime]$process.CreationDate
                        } catch {
                            $startTime = "Invalid Date"
                        }

                        $processInfo += [PSCustomObject]@{
                            ComputerName      = $computer
                            ProcessID         = $process.ProcessId
                            Name              = $process.Name
                            CPUTime           = $cpuTime
                            StartTime         = $startTime
                            IOReadBytes       = $readBytes
                            IOWriteBytes      = $writeBytes
                            IOReadOperations  = $readOps
                            IOWriteOperations = $writeOps
                        }
                    }
                }
            } else {
                Write-Host "$(Get-Date) - No 'fio' processes found on $($computer)"
            }
        } catch {
            Write-Host "$(Get-Date) - Error connecting to $($computer): $($_)"
        }
    }

    if ($processInfo) {
        switch ($OutputFormat) {
            'CSV' {
                $processInfo | Export-Csv -Path $OutputFilePath -NoTypeInformation
                Write-Host "Output written to $OutputFilePath in CSV format."
            }
            'JSON' {
                $processInfo | ConvertTo-Json | Out-File -FilePath $OutputFilePath
                Write-Host "Output written to $OutputFilePath in JSON format."
            }
            'TABLE' {
                $processInfo | Format-Table -AutoSize
            }
        }
    }

    Start-Sleep -Seconds $SleepTime
}
