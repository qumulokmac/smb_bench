######################################################################
# SMB Bench Windows Server userdata script
# smbbench-custom-data.ps1
# kmac@qumulo.com
# June 4th, 2024
######################################################################

Start-Transcript -Path "C:\userdata_mainlog.txt" -Append

###
# Dump the environmental variables for any forensics 
###
Get-ChildItem Env: | ForEach-Object {
    "$($_.Name)=$($_.Value)" 
} | Out-File -FilePath "C:\userdata_env_vars_log.txt" -Append

###
# Disable the local firewall
###
netsh advfirewall set allprofiles state off
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Output "Firewall disabled successfully" | Out-File -FilePath "C:\userdata_firewall_log.txt" -Append

###
# Configure WSM
###
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force
Write-Output "WSM configured successfully" | Out-File -FilePath "C:\userdata_wsm_log.txt" -Append
 
###
# Get rid of Windows Defender
###
Set-MpPreference -DisableRealtimeMonitoring $true
Remove-WindowsFeature Windows-Defender, Windows-Defender 
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Write-Output "Windows Defender disabled and removed successfully" | Out-File -FilePath "C:\userdata_defender_log.txt" -Append

###
# Disable the Server Manager Dashboard on Startup
###
New-ItemProperty -Path HKCU:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -PropertyType DWORD -Value 1 -Force
Write-Output "Server Manager Dashboard disabled successfully" | Out-File -FilePath "C:\userdata_server_manager_log.txt" -Append

###
# Install Notepad++
###
try {
    $nppInstaller = "npp_installer.exe"
    $nppUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.7/npp.8.6.7.Installer.x64.exe"
    Invoke-WebRequest -Uri $nppUrl -OutFile "C:\$nppInstaller"
    Start-Process -FilePath "C:\$nppInstaller" -ArgumentList "/S" -Wait
    Write-Output "Notepad++ installed successfully." | Out-File -FilePath "C:\userdata_notepad++_log.txt" -Append
} catch {
    Write-Output "Failed to install Notepad++: $_"
}

###
# Install Chrome
###
$chromeInstallerUrl = "https://dl.google.com/chrome/install/standalonesetup64.exe"
$installerPath = "C:\Windows\Temp\ChromeInstaller.exe"
Invoke-WebRequest -Uri $chromeInstallerUrl -OutFile $installerPath
Start-Process -FilePath $installerPath -Args "/silent /install" -Wait

###
# Install Sysinternals
###
try {
    $sysinternalsZip = "SysinternalsSuite.zip"
    $sysinternalsUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
    Invoke-WebRequest -Uri $sysinternalsUrl -OutFile "C:\$sysinternalsZip"
    Expand-Archive -LiteralPath "C:\$sysinternalsZip" -DestinationPath "C:\SysinternalsSuite" -Force
    Write-Output "Sysinternals Suite installed successfully." | Out-File -FilePath "C:\userdata_sysinternals_log.txt" -Append
} catch {
    Write-Output "Failed to install Sysinternals Suite: $_"
}

###
# Install 7-Zip
###
$sevenZipInstaller = "7zip_installer.exe"
$sevenZipUrl = "https://www.7-zip.org/a/7z1900-x64.msi"
Invoke-WebRequest -Uri $sevenZipUrl -OutFile "C:\$sevenZipInstaller"
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\$sevenZipInstaller /quiet" -Wait
Write-Output "7zip installed successfully." | Out-File -FilePath "C:\userdata_7zip_log.txt" -Append

###
# Install Visual Studio Code
###
$vscodeInstaller = "vscode_installer.exe"
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
Invoke-WebRequest -Uri $vscodeUrl -OutFile "C:\$vscodeInstaller"
Start-Process -FilePath "C:\$vscodeInstaller" -ArgumentList "/silent /mergetasks=!runcode" -Wait
Write-Output "Vscode installed successfully." | Out-File -FilePath "C:\userdata_vscode_log.txt" -Append

###
# Install Cygwin and required packages for dmbbench
###
try {
    $cygwinInstaller = "setup-x86_64.exe"
    $cygwinUrl = "https://cygwin.com/setup-x86_64.exe"
    Invoke-WebRequest -Uri $cygwinUrl -OutFile "C:\$cygwinInstaller"
    $packages = "_autorebase,alternatives,autoconf,automake,base-cygwin,base-files,bash,bzip2,ca-certificates,coreutils,crypto-policies,csih,cygrunsrv,cygutils,cygwin,cygwin-debuginfo,dash,diffutils,editrights,file,findutils,gawk,getent,gettext,git,gnupg,grep,groff,gzip,hostname,info,ipc-utils,jq,less,libargp,libassuan0,libattr1,libblkid1,libbrotlicommon1,libbrotlidec1,libbsd0,libbz2_1,libcares2,libcom_err2,libcrypt2,libcurl4,libdb5.3,libedit0,libexpat1"
    Start-Process -FilePath "C:\$cygwinInstaller" -ArgumentList "--quiet-mode --root C:\Cygwin64 --site http://cygwin.mirror.constant.com --packages $packages" -Wait -NoNewWindow
    Write-Output "Cygwin installed and configured successfully."
} catch {
    Write-Output "Failed to install Cygwin: $_"
}

###
# Set the system timezone
###
tzutil /s "UTC"

###
# Disable unnecessary services
###
Stop-Service -Name "Spooler" -Force
Set-Service -Name "Spooler" -StartupType Disabled

function Unpin-AppFromTaskbar {
    param (
        [string]$appPath
    )
    $shell = New-Object -ComObject Shell.Application
    $folderPath = Split-Path $appPath
    $exeName = Split-Path $appPath -Leaf

    $folder = $shell.Namespace($folderPath)
    $item = $folder.ParseName($exeName)

    if ($item -ne $null) {
        $item.InvokeVerb("taskbarunpin")
        Write-Output "$exeName unpinned from taskbar."
    } else {
        Write-Output "Error: $exeName not found."
    }
}

Unpin-AppFromTaskbar -appPath "C:\Program Files\Internet Explorer\iexplore.exe"

function Pin-AppToTaskbar {
    param (
        [string]$appPath
    )
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Get-Item $appPath).DirectoryName)
    $item = $folder.ParseName((Get-Item $appPath).Name)
    $item.InvokeVerb("taskbarpin")
}

$notepadPPPath = "C:\Program Files\Notepad++\notepad++.exe"
Pin-AppToTaskbar -appPath $notepadPPPath

# $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
# Pin-AppToTaskbar -appPath $chromePath

# $cygwinPath = "C:\Cygwin64\Cygwin.bat"
# Pin-AppToTaskbar -appPath $cygwinPath

# $powershellISEPath = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
# Pin-AppToTaskbar -appPath $powershellISEPath


# Install Azure CLI
$azureCLIInstaller = "AzureCLI.msi"
$azureCLIUrl = "https://aka.ms/installazurecliwindows"
Invoke-WebRequest -Uri $azureCLIUrl -OutFile "C:\$azureCLIInstaller"
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\$azureCLIInstaller /quiet" -Wait
Write-Output "Azure CLI installed successfully." | Out-File -FilePath "C:\userdata_azurecli_log.txt" -Append

###
# Install Windows Updates
###
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
Install-Module PSWindowsUpdate -Force -Scope CurrentUser
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

Write-Output "Rebooting..."

Stop-Transcript

Restart-Computer -Force
