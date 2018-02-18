#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Gunther's script library for the administration
#         and development of the Oracle Database / Oracle Apex Development / Oracle SQLcl / Oracle NoSQL
# Date:   February 2018
# Site:   www.pipperr.de/dokuwiki/
#==============================================================================

The file structure:

Ora_PowerShell_env_DB_backup  => Windows Powershell

Script libary for Oracle Maintainace Tasks for Windows

    	#orapowershell Backup library
	

#---------------------

Ora_Bash_env_DB_backup

Script libary for Oracle Maintainace Tasks for Linux for the Oracle RDBMS

	backup 		# the bash version of the backups scripts for the Oracle database


#---------------------
	
Ora_Bash_create_database

Script libary to create a Oracle Database (SE/EE) RAC/ASM/Single DB 11g / 12c(on Container)

#---------------------

Ora_Bash_NoSQL_Scripts

Script libary to Maintain Oracle NoSQL Database

#---------------------

SQLPLUS_SQLCL_sql_scripts

SQL Scripts
SQL*Plus and sqlCl Scripts for the Windows and the Linux enviroment
Please copy these script to the sql folder (Enviroment variable SQLPATH) in your Windows or Linux home enviroment
 Sql - to get an overview over all SQL scripts see help.sql 

#---------------------


Phy_simple_ImageLoader_script

	PersonalIMGLoader
    Script to load images from a drive


    DBIMGLoader
	Load documents to a table as BFILE and extract all possible meta data from the dokuments or images


#---------------------


#==============================================================================
Usage:

Windows
Copy/extract the content of the ps folder to a directory like d:\orapowershell 
Read the README for Windows in this folder for the setup of the enviroment

Linux
Copy/extract the content of the bash folder to the oracle home directory on your Linux server
Read the ~/README.txt for the setup of the environment