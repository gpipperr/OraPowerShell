#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   generic Backup Script for file backups
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

=================  Ora PowerShell Library =====================================

#### Security:   ####

(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )

  To switch it off (as administrator)
  
  get-Executionpolicy -list
  set-ExecutionPolicy -scope CurrentUser RemoteSigned

BETTER => 	Sign your code!
	
	Manually:
	Set-AuthenticodeSignature <my_filename> @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
	
	With a Script:
	use the helper script certScripts.ps1
  

### Configuration ####

#Oracle Backup

To configure the Oracle Backup copy the file conf/backup_config_template.xml to conf/backup_config.xml and edit the file

#VSS and File Backup

To configure the File Backup copy the file conf/backup_file_config_template.xml to conf/backup_file_config.xml and edit the file

#cmdlet to configure the environment

To configure the setdb environment copy the file conf/oracle_homes_template.xml to conf/oracle_homes.xml and edit the file

# Status E-Mail configuration

To configure the mail server copy the conf/mail_config_template.xml to conf/mail_config.xml and edit the file

#Search Pattern
To configure the search pattern you can adjust the file search_pattern.xml

***** Script Overview *****


Directory structure:

. 			=> All main Scripts
.\cert		=> Folder for your certificate - default empty
.\conf		=> xml configuration
.\doc		=> documentation of the configuration parameters
.\generated	=> folder for auto generated scripts - in the begin this folder is empty
.\lib		=> the function library for the main scripts
.\log		=> all auto generated logs
.\sql		=> Sql Script ( sql*pus use this folder if you use setdb via SQLPATH )
.\test		=> some test cases for development

#Main Scripts

profile.ps1				=> Profile Script for the PowerShell environment, add your personal settings here
--
setdb.psm1				=> the shell function to set the  Oracle environment to work with different Oracle homes
--
runOracleBackup.ps1		=> default : Backup the complete all databases configured in the ./conf/backup_config.xml
						   If called with the parameter ARCHIVE only the archivelogs are saved

runSimpleFileBackup.ps1	=> Copy Files from one or more locations to the backup folder , configured in the ./conf/backup_file_config.xml

runVssFileBackup.ps1	=> Copy Files from a backup VSS drive to the backup folder , configured in the ./conf/backup_file_config.xml
--
cleanLogfiles11g.ps1	=> Clean the log files of a oracle 11g instance
--
certScripts.ps1			=> Helper Script to create certificates and the global security settings like the MD5 hash check file
--
checkDiscAligment.ps1   => Check Alignment of internal and SAN Disks 
--
setBGColor.ps1			=> set the background color of the console


#SQL Script library:

You can use the sql scripts with sqlplus (sqlplus>@<scriptname>) the location of the script will be found over the environment variable SQLPATH

status.sql				=> Status of the Instance(s)
invalid.sql	            => check for invalid objects
statistic.sql           => show the statistic of the database

The prompt of SQL*Plus will be set with the "login.sql", automatically called from Sql*Plus.

The following Scripts will be used from the backup Scripts:
info.sql               => Spool out of meta information of the database
infoASM.sql            => Spool out of Meta information of the ASM environment

Setup
If you need separate rman user you can use the create_rman_user.sql script.



*********** Use the ZIP function ********************


If you like to use the zip library download from http://powershellzip.codeplex.com	the zip lib and copy the file ICSharpCode.SharpZipLib.dll to the directory .\lib\zip


