@echo off
setlocal enabledelayedexpansion

:: List of IP addresses
set ipList=10.66.0.131 10.66.0.141 10.66.0.142 10.66.0.133 10.66.0.14 10.66.0.13 10.66.0.129 10.66.0.136 10.66.0.134 10.66.0.138 10.66.0.139 10.66.0.135 10.66.0.140 10.66.0.132 10.66.0.137 10.66.0.130

:: Starting drive letter
set driveLetter=F

:: Iterate over IP addresses and assign drive letters
for %%i in (%ipList%) do (
    net use !driveLetter!: \\%%i\bm1 /persist:yes
    echo Mapped \\%%i\bm1 to drive !driveLetter!:
    set /a driveLetter=!driveLetter!+1
)

endlocal
pause
