//this is a work in process, the target is to make a single script/bat file that will run and determin the role of server as primary or replica
//Also it shoul able to import and export the created certificates
//it should also able to add trusted IP of servers in %windows%/system32/etc/drivers/host file and in windows firewall
//the basic syntact is here
//on main server
mkdir c:\makecert
PowerShell.exe "Invoke-WebRequest -Uri https://www.dropbox.com/s/7ylu9wn0j020oqq/makecert.exe?dl=1 -OutFile C:\makecert\makecert.exe ; Get-Item c:\makecert\*
mkdir c:\makecert\copy
mkdir c:\makecert\import
c:\makecert\makecert -pe -n "CN=PrimaryRepRootCA" -ss root -sr LocalMachine -sky signature -r "c:\makecert\PrimaryRepRootCA.cer"
c:\makecert\makecert -pe -n "CN=Server1" -ss my -sr LocalMachine -sky exchange -eku 1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2 -in "PrimaryRepRootCA" -is root -ir LocalMachine -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 "c:\makecert\PrimaryRepCert.cer"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f


//on replica server
mkdir c:\makecert
PowerShell.exe "Invoke-WebRequest -Uri https://www.dropbox.com/s/7ylu9wn0j020oqq/makecert.exe?dl=1 -OutFile C:\makecert\makecert.exe ; Get-Item c:\makecert\*
mkdir c:\makecert\copy
mkdir c:\makecert\import
c:\makecert\makecert -pe -n "CN=SecondRepRootCA" -ss root -sr LocalMachine -sky signature -r c:\makecert\SecondRepRootCA.cer"
c:\makecert\makecert -pe -n "CN=Server2" -ss my -sr LocalMachine -sky exchange -eku 1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2 -in "SecondRepRootCA" -is root -ir LocalMachine -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 C:\makecert\SecondRepRootCA.cer"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f



//Manual work (need automation)
//export certifcatres from both servers as pfx and then import crosswise and run the following commands 
//step 2 on Main Server
certutil -addstore -f Root C:\makecert\import\SecondRepRootCA.cer

//Step2 on Replica Server
certutil -addstore -f Root C:\makecert\import\PrimaryRepRootCA.cer

//incase of error
//get-item cert:\LocalMachine\root\*
//Remove-Item -Path cert:\LocalMachine\root\F6DEEA97F4870774069B5F0628D180D175A16E0B

//trusted server
//winrm set winrm/config/client @{TrustedHosts="Server2-Replica"} 
