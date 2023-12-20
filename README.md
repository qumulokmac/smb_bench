# smb_bench
SMB Benchmark Framework for ANQ

This README is a WIP 


1/ Create the RDP files using ...

2/ Mount SMB shares
        - Log onto Maestro
        - Update the nodes.conf and workers.conf files in C:\FIO
        - Run the powershell script C:\FIO\rmount-q.ps1 to create the mounts on all of the workers
        - Reboot all of the Windows Servers (Workers) so the mount persists
                # az vm restart --ids $(az vm list -g mrcoop-rg --query "[].id" -o tsv)

2/ Install smb_bench and setup the cygwin environment (Maestro)
        - git clone smb_bench under the users cygwin home directory
        - Create %userprofile%\vimfiles\vimrc (in windows)
                CMD> mkdir  %userprofile%\vimfiles\

        - Copy the VIM config file:
                cygwin>  cp ~/ini/vimrc /cygdrive/c/Users/mrcooper/vimfiles/
                - Close and re-open the cygwin window

3/ Configure smb_bench
        - Copy the workers.conf & nodes.conf to ~/ini
                cygwin> cp -p /cygdrive/c/FIO/*.conf ~/ini
        - Create the template INI file in ~/ini
        - Edit the settings in
        - Run ./make-fiojobs-one-fio.sh
        - Start the benchmark
                - Open Powershell ISE on all Windows Workers
                - In Powershell, open c:\FIO\runall.ps1
                - Once ready, click start on all workers (until this is automated)


