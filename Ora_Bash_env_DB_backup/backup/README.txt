#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#

Check that this directories are exits in the script directory
./lck
./log

!



Prepare Backup

1. Configuration

If you use this script to backup a real applicatoin cluster environment:

Check that you have definied a snapshot controlfile name located on the ASM that can be read from both nodes!

like RMAN> CONFIGURE SNAPSHOT CONTROLFILE NAME TO '+RECO/snapcf_GPIDBIP.f';


- Edit the ~/backup/initbackup.conf file
		- set the BACKUP_DEST Parameter
		- edit the calls for the backup of each DB
		- Validate the calling of the ASM and Grid Backup if necessary
		- Check if on the  BACKUP_DEST the folders exists and the oracle user have the right rights!
	 
	 - Set the sudo rights like descript in the db installation guide, see example above, check carefully that you comment out the "Defaults  requiretty"!


2. Set the sudo rights		

	 Look carefully that the example path for the root commands (see line Cmnd_Alias ORACLE ) is the same like in your environment!



Example:	 
as user root do "visudo", check  carefully the directories:
		 
..
# GPI Oracle Backup Script 15.11.2010
#Defaults    requiretty

..
## Alias Section (on one Line!)
## ORACLE
Cmnd_Alias ORACLE = /u01/app/11.2.0.3/grid/bin/ocrcheck, /u01/app/11.2.0.3/grid/bin/ocrcheck.bin, /u01/app/11.2.0.3/grid/bin/ocrconfig, /u01/app/11.2.0.3/grid/bin/ocrconfig.bin, /u01/app/11.2.0.3/grid/bin/ocrdump , /u01/app/11.2.0.3/grid/bin/ocrdump.bin,/usr/bin/scp,/usr/sbin/oracleasm, /usr/sbin/sanlun, /usr/sbin/blkid,/usr/bin/lsblk
...

for SE Edtion
Cmnd_Alias ORACLE = /usr/bin/scp,/usr/sbin/sanlun,/usr/sbin/blkid,/usr/bin/lsblk



#Command Section
# Allow Oracle DBA run root related stuff
%dba ALL = NOPASSWD: ORACLE
..

 ---------------------------
3. Cronjob
	
- Set the cronjob
	 
# M H  D M
# Oracle Backup
0 21 * * * /home/oracle/backup/runBackup.sh
#backup and delete archivelog every hour at 30
#30 * * * * /home/oracle/backup/runArchivelogBackup.sh
#backup and delete archivelog every two hours
0 */2 * * * /home/oracle/backup/runArchivelogBackup.sh	
	

---------------------------

4. For Oracle 12c Cluster create a diag home for asmcmd wiht the correct read right like:

[grid@gpidb02:~ ]$ mkdir /opt/oracle/diag/asmcmd
[grid@gpidb02:~ ]$ cd /opt/12.1.0.2/grid/log/diag
[grid@gpidb02:diag ]$ ln -s /opt/oracle/diag/asmcmd asmcmd
[grid@gpidb02:diag ]$ chmod g+w /opt/oracle/diag/asmcmd

On each Host of the cluster!

---------------------------
