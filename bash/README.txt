# ==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   generic Backup Script for file backups
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
# ==============================================================================

1. Configure Environment

	- copy .profile to the oracle Home

	- edit the .profile
		check the Oracle Path and the complete environment ( ASM etc.)
		
	- edit .bash_profile like the example .bash_profile or replace the .bash_profile
		 add/check:
			# .bash_profile
			. .profile
			echo -e "\033[33m USE setdb to set Oracle Profile!\033[0m"
	- if you not like the title of the xterm window and the changed command prompt
      please uncomment the all of the "prompt" function	

	- copy the folder sql to the Oracle Home directory 
 		
		
2. Relogin as oracle user
	
	Now You can set the Oracle environment with the shell command "setdb"
	test with sqlplus a connection to the database

	You can recreate the configuration with the command "setdbConfigure"
	