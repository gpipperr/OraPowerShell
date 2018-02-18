PowerShell library for backup and maintenance Oracle Database environment (File, RAC, ASM, GRID) under Microsoft Windows 2008 - a very easy Oracle backup script

**Oracle PowerShell Script Library for backup and maintenance a Oracle database**

**New Project structure**
* PowerSchell Scripts in Folder "ps"
* bash maintenance scripts in Folder "bash"
* Generic SQL scripts for SQL*Plus in the Folder "sql"

**The PowerShell Scripts:**

The main idea of this script library is the easy use of the PowerShell to generate he backup scripts to backup the Oracle Database. 

The whole configuration is done with xml files.

The password of the users will be encrypted.

You can perform the backup as Oracle "SYS" user or create your own user.

**Implemented Feature**

**Backup**
* Generate and run backup scripts 
	* RMan backup of the database and the archivelogs
	* Backup all possible meta information about the DB installation
	* RMan backup of the archivelogs as separate task
	* Export DB users with datapump
	* If ASM is in use save the meta information of the ASM home
	* If Grid/RAC is in use save the meta information of the GRID home
	* Check the alert log for errors
	* Generate summary report and mail the report

* VSS Backup script for special environments

* Simple File Backup for special environments

**DB handling**

* Powershell DB environment cmdlet (setdb) to set the Oracle environment in the PowerShell

* Read the Oracle Database with the .net library and write to a csv file

* Script cleanLogfiles11g to clean the XML Logs and some traces of the DB

**Script handling**
* One script to sign the code and set the security => certScripts.ps1 is

**Current Work:**
* Documentation is ongoing
* Integration of my bash scripts for Oracle Backup and environment


Know issues:
* Grid environment backup not fully implemented / tested
* If not sys export the data, the generation of the directory object is not automatically supported
* filter attribute on username configuration for datapump export not implemented
* for file copy, connect to a share must be possible without password
* ADRCI cannot cut the trace log files of the DB (alert.log) and the trace log file of the listener

Next Features:
* Script to generate SQL*Net certificate authorization (Secure External Password Store see [http://www.pipperr.de/dokuwiki/doku.php?id=dba:passwort_schuetzen](http://www.pipperr.de/dokuwiki/doku.php?id=dba:passwort_schuetzen) )
* Configuration script to generate the configuration out of the environment like the oracle inventory
