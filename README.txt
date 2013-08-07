#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Gunther's script library
# Date:   07.August 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
The file structure:

* Windows Powershell
Script libary for Oracle Maintainace Tasks for Windows

ps\ 
	backup   	# the orapowershell Backup library
	lib      	# generic library	
	scripts  	# scripts

* Linux Bash
Script libary for Oracle Maintainace Tasks for Linux

bash\
	backup 		# the bash version of the backups scripts
	lib    		# generic scripts library
	scripts     # scripts
	create_db 	# Create a database 
	ONoSQL      # Oracle NoSQL Create and maintain scripts
	
* SQL Scripts
SQL*Plus Scripts for the Windows and the Linux enviroment
Please copy these script to the sql folder in your windows or linux home enviroment

sql\

Usage:

Windows
Copy/extract the content of the ps folder to a directory like d:\orapowershell 
Read the README for Windows in this folder for the setup of the enviroment

Linux
Copy/extract the content of the bash folder to the oracle home directory on your Linux server
Read the ~/README.txt for the setup of the enviroment