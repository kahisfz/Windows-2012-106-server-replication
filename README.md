# Windows-2012-2016-2019-server-replication
In this tutorial, i have built two Windows 2016 servers using a pair of Supermicro Server (2xXeon CPU's and 128 GB RAM in both), and a single 24 port Netgear 10 GB switch. I have also tested same by connecting both server through a CAT 7 cable over 10 Gbps and 1 Gbps networks cards. For best performnce I used SSD's Array, but it will work on NAS, Hyper Converged Storeage or Windows Storage Direct.
 
Let Us say, Primary server name is: Truro
and the Secondary server name is: Exeter
Lets get started…
Step 1: Build your host servers
•	Build two physical host servers – they need to be running the same version of Windows Server 2019, 2016, 2012 R2, or 2012 (which has less functionality).
•	Install the Hyper-V role on both.
•	Make sure both servers are fully patched though Windows update.
•	See if any of the hyper-v hotfixes apply to your situation
If you are doing this in a clustered environment, you will need to know the replication broker name on each cluster.
 
Step 2: Download MakeCert
Download makecert (extract from the full SDK), http://www.microsoft.com/en-us/download/details.aspx?id=8279
or, download both 32bit and 64bit versions from here (you’ll want 64bit): https://1drv.ms/f/s!AqQjKR39YBWmoD68gEVRVmtNisE_
Step 3: Prepare the server directories
On both servers, make the following file structure:
C:\makecert
C:\makecert\copy
C:\makecert\import
Copy makecert.exe to c:\makecert on both servers
 
Step 4: Making the certificates
Using an admin command prompt (do not use Powershell on server 2019, 2016, 2012 R2, or 2012).
Run the following commands on the Primary Server:
c:\makecert\makecert -pe -n "CN=PrimaryTestRootCA" -ss root -sr LocalMachine -sky signature -r "c:\makecert\PrimaryTestRootCA.cer"
 
Then run this command (change the text in bold to match your server name);
c:\makecert\makecert -pe -n "CN=TRURO" -ss my -sr LocalMachine -sky exchange -eku 1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2 -in "PrimaryTestRootCA" -is root -ir LocalMachine -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 "c:\makecert\PrimaryTestCert.cer"
If you’re using certificates in a domain environment,  you will need to replace “CN=TRURO” with “CN=TRURO.DOMAIN.LOCAL” for this to work correctly.
 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f
 
On the primary server you will see the following:
 
Next, run these commands on the Replica Server:
c:\makecert\makecert -pe -n "CN=ReplicaTestRootCA" -ss root -sr LocalMachine -sky signature -r c:\makecert\ReplicaTestRootCA.cer"
 
c:\makecert\makecert -pe -n "CN=EXETER" -ss my -sr LocalMachine -sky exchange -eku 1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2 -in "ReplicaTestRootCA" -is root -ir LocalMachine -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 C:\makecert\ReplicaTestCert.cer
If you’re using certificates in a domain environment,  you will need to replace “CN=EXETER” with “CN=EXETER.DOMAIN.LOCAL” for this to work correctly.
 
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f
 
On the replica server you will see the following:
 
If you hit any issues at this stage; you can open a new mmc console, add the certificates snap in (local computer), head to Trusted Root Certification Authorities, Certificates. Find the ReplicaTestRootCA or PrimaryTestRootCA certificate and delete them, then re-running the above commands once corrected.
Step 5: Export the certificates
On both the primary and replica servers
Launch an MMC
click File > Add/Remove Snap-in…
 
In the Add or Remove Snap-ins window, select Certificates from the Available Snap-ins list;
 
Click Add >; the Certificates snap-in window will appear;
In the Certificates snap-in window, click the Computer account radio button; click Next to continue;
 
In the Select Computer window, make sure the Local computer radio button is clicked; then click Finish;
 
In the Add or Remove Snap-ins window, click OK.
 
In the Microsoft Management Console on the primary server, expose the contents of Certificates (Local Computer), which can be found under the Console Root directory:
Expose the contents of the Personal directory; click the Certificates directory;
 
Right-click on the Truro certificate – PrimaryTestRootCA.cer; in the context menu that appears, mouse over All Tasks >; In the sub-menu that appears, click Export…
 
In the wizard, click next
 
In the Certificate Export Wizard that appears, click the Yes, Export the private key radio button and click Next;
 
Check and click next
 
Enter a password, click next
 
Export the key to to c:\makecert\copy\truroserver.pfx
 
Click finish
 
click ok
 
Repeat the above steps for the Replica server (Exeter).
Step 6: Import the certificates
On the primary server (Truro)
Copy:
PrimaryTestCert
PrimaryTestRootCA.cer
TruroServer.pfx
To the replica servers (Exeter) c:\makecert\import directory
On the replica server (Exeter)
Copy:
ReplicaTestCert
ReplicaTestRootCA.cer
ExeterServer.pfx
To the replica servers (Truro) c:\makecert\import directory
This is what you should now see on your Primary server (Truro):
 
run in admin cmd on Primary Server
certutil -addstore -f Root C:\makecert\import\ReplicaTestRootCA.cer
 
In the MMC on the primary server, make sure your still in Certificates (Local Computer)
Personal directory;
 
On the wizard that appears, click next.
 
Navigate and select the exeterserver.pfx file (you’ll need to select the dropdown menu to all items before it will appear).
 
Enter the password you set during the export
 
Click next
 
Click finish
 
Click ok.
 
Repeat for the Replica server (summary below):
run in admin cmd on Replica Server
certutil -addstore -f Root C:\makecert\import\PrimaryTestRootCA.cer
In the MMC on the replica server, make sure your still in Certificates (Local Computer)
Personal directory;
Right click on Personal directory, mouse over All Tasks >; in the submenu that appears, click Import…;
Locate the TruroServer.pfx file. enter the password (as per the export section)
 
Step 7: Configuring Hyper-V replication
On both primary and replica servers:
In Hyper-V manager, right click on the host server and select Hyper-V settings (in a cluster, open Failover Cluster Manager, rmb on the Hyper-V Replica Broker and select replication settings).
 
Select Replication Configuration Enabled as a Replica Server
Check the box – Enable this computer as a replica server
Select Use certificate-based Authentication (HTTPS)
Select the Allow replication from any authenticated server check box.
 
Then choose “Select Certificate…”
Make sure Truro is selected.
 
On the next screen, click ok.
 
Step 8: Check the firewall settings
Check the firewall rules are configured to allow hyperv replication. (Control Panel, Windows Firewall, Advanced). – both should have green ticks (if not, right click and enable).
 
Repeat on the replica server.
Step 9: Configuring the VM
Configure replication on the VM (right click, enable replication)
 
In the wizard, click next
 
Enter the name of the replica server (ie Exeter)
 
Select Certificate
 
 
 
Select the vhds you wish to replicate (you may wish to exclude swap partition drives if you have those configured)
 
Choose the replication frequency (30 seconds, 5 minutes or 15 minutes).
 
choose whether you need any recovery points (useful if you need to roll back the server to a previous state).
 
you may wish to seed the initial replica if your working on slow links.
 
Review and confirm
 
Step 10: Checking replication status and health
Primary server status: Normal
 
Right click on the VM – select view replication health
 
Replication should be normal
 
Congratulations…. You have completed Hyper-V replication configured between two workgroup computers.
In case of any issue/query please let me know.
