#==============================================================================
# Author: Gunther PippFrr ( http://www.pipperr.de )
# Desc:   generic Backup Script for file backups
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

Ora PowerShell Library


Security:  (see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
  To switch it off (as administrator)
  
  get-Executionpolicy -list
  set-ExecutionPolicy -scope CurrentUser RemoteSigned

OR
  Sign your code!

 Set-AuthenticodeSignature <my_filename> @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]

***** Script Overview *****

Configuration:

#Oracle Backup

To configure the Oracle Backup copy the file conf/backup_config_template.xml to conf/backup_config.xml and edit the file

#VSS and File Backup

To configure the File Backup copy the file conf/backup_file_config_template.xml to conf/backup_file_config.xml and edit the file

#cmdlet to configure the enviroment

To configure the setdb enviroment copy the file conf/oracle_homes_template.xml to conf/oracle_homes.xml and edit the file

#Satus E-Mail configuration

To configure the mail server copy the the conf/mail_config_template.xml to conf/mail_config.xml and edit the file
