############################################ Global Defaults  ###################################
# Edit this parameter
#
# Fix 
# use  /etc/oracle/olr.loc if exits to get the actual CRS HOME
# use id to get the user home path
# 

export NLS_LANG=american_america.al32utf8


# guess oracle base
if [ -d "/opt/oracle" ]; then
	ORACLE_BASE="/opt/oracle"
elif [ -d "/u01/app/oracle" ]; then
	ORACLE_BASE="/u01/app/oracle"
elif [ -d "/var/oracle" ]; then
	ORACLE_BASE="/var/oracle"
elif [ -d "/u00/app/oracle	" ]; then
	ORACLE_BASE="/u00/app/oracle"	
else
	ORACLE_BASE="~"
fi

export ORACLE_BASE

#################################################################################################

if [ -f "/etc/oraInst.loc" ]; then
	# Read the Oracle Inventory if exists
	. /etc/oraInst.loc
	export ORACLE_INVENTORY_HOME=${inventory_loc}
elif 	[ -f "/var/opt/oracle/oraInst.loc" ]; then
	# Read the Oracle Inventory if exists
	. /var/opt/oracle/oraInst.loc
	export ORACLE_INVENTORY_HOME=${inventory_loc}
else
	if [ -d "${ORACLE_BASE}/oraInventory" ]; then
		export ORACLE_INVENTORY_HOME=${ORACLE_BASE}/oraInventory
	else
		printf "\033[31m%s\033[0m\n" "Oracle Inventory not found!"	
	fi
fi

# set the sqlpath if exits

if [ -d "/home/$USER/sql" ]; then
	export SQLPATH=/home/$USER/sql
elif [ -d "/export/home/$USER/sql" ]; then
	export SQLPATH=/export/home/$USER/sql
else
 printf "\033[31m%s\033[0m\n"  "No SQL direcory found!"	
fi	

export ORACLE_PATH=${SQLPATH}

export ORACLE_HOSTNAME=`hostname`

export ADR_BASE=${ORACLE_BASE}

ORIG_PATH=$PATH

############################################ Helper functions ###################################
printDBEnv(){
	printf "%s" "    "		
	PRINT_TEXT="${1} ---> ${3}"
	printf "\033[32m%s \033[0m" "${PRINT_TEXT}"
	STRG_COUNT=${#PRINT_TEXT}	
	while [[  ${STRG_COUNT} -lt 17  ]]; do
		 printf "%s" " "
		let "STRG_COUNT+=1"
	done
	printf "\033[31m%s \033[0m"   "Home: "
	printf "\033[32m%s \033[0m\n" "${2:(-17)}"	
}

#normal
printLine() {
	if [ ! -n "$1" ]; then
		printf "\033[35m%s\033[0m\n" "-----------------------------------"
	else
		printf "%s" "   "		
		while [ "$1" != "" ]; do
			printf "%s " $1 
			shift
		done		
		printf  "%s\n" ""
	fi	
}
# 1 Prompt
# 2 list lenght
# 3 seperator
# 4 text

printList() {
	  printf "%s" "    "		
		
		PRINT_TEXT=${1}	
		
		printf "%s" "${PRINT_TEXT}"
		
		STRG_COUNT=${#PRINT_TEXT}	
		
		while [[  ${STRG_COUNT} -lt $2  ]]; do
		 printf "%s" " "
		 let "STRG_COUNT+=1"
	  done
		
		printf "\033[31m%s \033[0m"   "$3"
		printf "\033[32m%s \033[0m\n" "$4"	

}

#red
printError() {
	if [ ! -n "$1" ]; then
		printf "\033[31m%s\033[0m\n" "-----------------------------------"
	else
		printf "\033[31m%s\033[0m" "!! "		
		while [ "$1" != "" ]; do
			printf "\033[31m%s \033[0m" $1 
			shift
		done
		printf  "%s\n" ""
	fi	
}
#green
printLineSuccess() {
	if [ ! -n "$1" ]; then
		printf "\033[32m%s\033[0m\n" "-----------------------------------"
	else
		printf "\033[32m%s\033[0m" "!! "		
		while [ "$1" != "" ]; do
			printf "\033[32m%s \033[0m" $1 
			shift
		done
		printf  "%s\n" ""
	fi	
}


#################### create auto defaults ##################################

##########  Configure the default file .profile_default

setdbConfigure() 
{


BASH_OS_VERSION=`uname`

if [ -d "/home/oracle" ]; then
	SCRIPT_HOME=/home/oracle
elif [ -d "/export/home/oracle" ]; then
	SCRIPT_HOME=/export/home/oracle
else
 printf "\033[31m%s\033[0m\n"  "No Script Home found!"	
fi	

if [ -f "${SCRIPT_HOME}/.profile_conf" ]; then
	printLineSuccess
	printLineSuccess "A configuration exists"
	printLineSuccess
	askYesNo "Overwrite the configration ?" "NO"
	printLineSuccess
	OVERWRITE_PROFIL=${YES_NO_ANSWER}
		
else
		OVERWRITE_PROFIL="YES"
fi

if [ "${OVERWRITE_PROFIL}" = "YES" ]; then

  CONFIGUREDATE=`date`
	
	echo "#############################################" >  ~/.profile_conf
    echo "# Configuration created at ${CONFIGUREDATE}  " >> ~/.profile_conf
    echo "#############################################" >> ~/.profile_conf
	
	 unset DATABASE_ENV
     unset ASM_INSTANCESID	
	 
	# check the grid home
	ORAINVENTORY_LIST=`grep "CRS" ${ORACLE_INVENTORY_HOME}/ContentsXML/inventory.xml | awk '{ print($2 "#" $3);}' | sed 's/"//g'`
	 
	for 	ORA_HOME_STRING in $ORAINVENTORY_LIST
	do
		LOC_POS=`expr ${ORA_HOME_STRING} : '.*LOC'`
		let "LOC_POS=${LOC_POS}+1"
		#printLine "LOC POS" "$LOC_POS"
		LOC_PATH=${ORA_HOME_STRING:$LOC_POS}		 
		#printLine "PATH" ${LOC_PATH}
		CRS_ASM_HOME=${LOC_PATH}
		#printLine
		let "LOC_POS=${LOC_POS}-10"
		#printLine "LOC POS" "$LOC_POS"
		LOC_NAME=${ORA_HOME_STRING:5:$LOC_POS}
		#printLine "LOC" ${LOC_NAME}
		CRS_HOME_NAME=${LOC_NAME}
		#printLine
	done
	 
	if [ -d "${CRS_ASM_HOME}" ]; then
			ASM_ENV=true
			
		if [ -f "${CRS_ASM_HOME}/bin/cemutlo" ]; then
			CLUSTER_NAME=`${CRS_ASM_HOME}/bin/cemutlo -n`
		else
			RAC_ENV=false
			CLUSTER_NAME=false
			VIPNODES=${ORACLE_HOSTNAME}
			NODE_ID=
		fi

		if [ "${#CLUSTER_NAME}" -gt 2 ]; then
        
			printError " found Cluster ${CLUSTER_NAME}"
			RAC_ENV=true
		
			if [ "${CRS_HOME_NAME}" = "OraCrs10g_home" ] ; then
				# in 10g the srvctl not work like expected
				# remember node 1
				VIPNODES=`hostname`
				# FIX and test!
				#VIPNODES=`${CRS_ASM_HOME}/bin/olsnodes`
			else
				VIPNODES=`${CRS_ASM_HOME}/bin/srvctl status nodeapps | grep 'VIP' | grep 'on node' | awk '{ print $7 }'`
				#VIPNODES=`${CRS_ASM_HOME}/bin/olsnodes`
			fi
			
		else
			printError " No Cluster enviroment"
			RAC_ENV=false
			CLUSTER_NAME=false
			VIPNODES=${ORACLE_HOSTNAME}	
			NODE_ID=
		fi	
	else
		ASM_ENV=false
		RAC_ENV=false
		CLUSTER_NAME=false
		VIPNODES=${ORACLE_HOSTNAME}	
		NODE_ID=	
	fi 

	#ask the operator for the node id of this host - only for rac enviroment!
	if [ "${RAC_ENV}" = "true" ]; then
		printf " +please enter the node id for this node %s for the RAC Cluster ${CLUSTER_NAME}: " "${ORACLE_HOSTNAME}"  
		read NODE_ID
		if [ ! -n "${NODE_ID}" ]; then
			printError "Please answer with a valid node id! -> Check config after creation"
			printf " +please enter the node id for this node %s for the RAC Cluster ${CLUSTER_NAME}: " "${ORACLE_HOSTNAME}"  
			read NODE_ID
		fi  
		echo "export NODE_ID=${NODE_ID}" >> ~/.profile_conf	
	else
		echo "export NODE_ID=" >> ~/.profile_conf	
	fi
	
	if [ "${ASM_ENV}" = "true" ]; then
		# try to get the asm instance SID
		if [ "${RAC_ENV}" != "true" ]; then
			if [ "${BASH_OS_VERSION}" = "SunOS" ]; then
				ASM_INSTANCESID=`ls ${CRS_ASM_HOME}/dbs | grep hc_ | sed 's/hc_//g' | sed 's/.dat//g'`	
			else
				ASM_INSTANCESID=`ls ${CRS_ASM_HOME}/dbs | grep -e hc_ | sed 's/hc_//g' | sed 's/.dat//g'`	
			fi	
		fi
		
		if [ ! -n "${ASM_INSTANCESID}" ]; then
				ASM_INSTANCESID=+ASM${NODE_ID}
		fi
		
		echo "export ASM_INSTANCESID=${ASM_INSTANCESID}" 	>> ~/.profile_conf			
	fi
	
	echo "export CLUSTER_NAME=${CLUSTER_NAME}" 			>> ~/.profile_conf	
	echo "export RAC_ENV=${RAC_ENV}" 					>> ~/.profile_conf	
	echo "export VIPNODES=\"${VIPNODES}\"" 				>> ~/.profile_conf	
	echo "export ASM_ENV=${ASM_ENV}" 					>> ~/.profile_conf
	echo "export CRS_HOME_NAME=${CRS_HOME_NAME}" 		>> ~/.profile_conf
	echo "export CRS_ASM_HOME=${CRS_ASM_HOME}" 		>> ~/.profile_conf
  
	
	########## write config ############
	## check for oracle homes
	## search over inventory
	## 	
	
	if [ -d "${ORACLE_INVENTORY_HOME}/ContentsXML" ]; then
	 # analyse the inventory
	 ORAINVENTORY_LIST=`grep "HOME NAME" ${ORACLE_INVENTORY_HOME}/ContentsXML/inventory.xml | awk '{ print($2 "#" $3);}' | sed 's/"//g'`
	
	 # create the db configuration # Parameter DATABASE[NR of DB] = [ORACLE_HOME ORACLE_SID ORACLE_DBNAME NLS_LANG ]
	 ORA_HOME_COUNTER=0
	 
		for 	ORA_HOME_STRING in $ORAINVENTORY_LIST
		do
			##printError ${ORA_HOME_STRING}
			##printError
	   
			## subtract the string
			LOC_POS=`expr ${ORA_HOME_STRING} : '.*LOC'`
			
			let "LOC_POS=${LOC_POS}+1"
			##printLine "LOC POS" "$LOC_POS"
			LOC_PATH=${ORA_HOME_STRING:$LOC_POS}		 
			##printLine "PATH" ${LOC_PATH}
			##printLine
			
			let "LOC_POS=${LOC_POS}-10"
			##printLine "LOC POS" "$LOC_POS"
			LOC_NAME=${ORA_HOME_STRING:5:$LOC_POS}		 
			##printLine "LOC" ${LOC_NAME}
			##printLine
		
		 
			if [ "${LOC_NAME}" = "Ora11g_gridinfrahome1" ]; then
				#echo "#export CRS_ASM_HOME=${LOC_PATH}" >> ~/.profile_conf		
				printLine "Ignore the Oracle Home ${LOC_NAME}"
			else
		  		 
				# set the default home, take the first home found
				if [ "${ORA_HOME_COUNTER}" = "0" ]; then
				echo "export DEFAULT_ORACLE_HOME=${LOC_PATH}" >> ~/.profile_conf			
				fi
				
				if [ "${BASH_OS_VERSION}" = "SunOS" ]; then
					ORADB_LIST=`ls ${LOC_PATH}/dbs  | grep orapw | sed 's/orapw//g'`
				else
					ORADB_LIST=`ls ${LOC_PATH}/dbs  | grep -e orapw | sed 's/orapw//g'`		
					if [ "${ORADB_LIST}" = "" ]; then			
				    
						printError "----------------------------"
						printError "DATABASE_ENV[${ORA_HOME_COUNTER}] - NO Password files in DB Home found? - DB PWD File ERROR or no DB?"
						printError "Please check the  ${LOC_PATH}/dbs"
						printError "----------------------------"
						printError "Use init.ora of the databases:"
						ORADB_LIST=`ls ${LOC_PATH}/dbs  | grep -v init.ora | grep -e init | sed 's/init//g' | sed 's/.ora//g' `						
				    fi
					
				fi
				
				if [ "${ORADB_LIST}" != "" ]; then
					for ORAHOMESID in $ORADB_LIST
					do
						if [ "${RAC_ENV}" = "true" ]; then
							ORADBNAME=`echo ${ORAHOMESID} | sed 's/[0-9]$//g'`
							echo "DATABASE_ENV[${ORA_HOME_COUNTER}]=\"${LOC_PATH} ${ORAHOMESID} ${ORADBNAME} .UTF8\""  >> ~/.profile_conf		
						else
							echo "DATABASE_ENV[${ORA_HOME_COUNTER}]=\"${LOC_PATH} ${ORAHOMESID} ${ORAHOMESID} .UTF8\""  >> ~/.profile_conf		
						fi
						let "ORA_HOME_COUNTER=${ORA_HOME_COUNTER}+1"
					done
				else
			
					# set the oracle environment without a SID if no DB is installed yet		
									
					echo "DATABASE_ENV[${ORA_HOME_COUNTER}]=\"${LOC_PATH} "-" "-" .UTF8\""  >> ~/.profile_conf
					let "ORA_HOME_COUNTER=${ORA_HOME_COUNTER}+1"
				fi
			fi	
		done	 	
		printLineSuccess
		printLineSuccess "Rewrite configuration please check config file"
		printLineSuccess	 
		cat ~/.profile_conf
	else
		printError "Oracle Inventory can not be read, please edit the ~/.profile_conf it manualy"	
	fi 	
	
	# Reload config
	. ~/.profile_conf
	. ~/.profile	
	
	# set the defaults
	export ORACLE_HOME=${DEFAULT_ORACLE_HOME}
	
	if [ "${ASM_ENV}" = "true" ]; then
		export TNS_ADMIN=${CRS_ASM_HOME}/network/admin
	else
		export TNS_ADMIN=${ORACLE_HOME}/network/admin
	fi
	
fi
}

######## Set the DB Enviroment ##################
#################################################
setdb ()
{
printLineSuccess
printList "Current ORACLE SID "  "20" ":" "${ORACLE_SID}"
printLineSuccess
	
DB_ANSWER=${1}

ELEMENT_COUNT=${#DATABASE_ENV[@]}

if [ -z "${ELEMENT_COUNT}" ]; then
	ELEMENT_COUNT=0
fi

if [ -z "$1" ];	then
	INDEX=0
	
	if [ "${ASM_ENV}" = "true" ]; then
		CHOOSE_INDEX=2
	else
		CHOOSE_INDEX=1
	fi
	
	if [ "${RAC_ENV}" = "true" ]; then
		printError "Oracle Cluster installed: $CLUSTER_NAME"
	fi

	if [ "${ELEMENT_COUNT}" -gt "0" ]; then
		printLine "Possible New Environments:"
		if [ "${ASM_ENV}" = "true" ]; then
			# 10g ASM not in CRS Home
			if [ "${CRS_HOME_NAME}" = "OraCrs10g_home" ] ; then
				printDBEnv "1" "${CRS_ASM_HOME}" ""
			else
				printDBEnv "1" "${CRS_ASM_HOME}" "${ASM_INSTANCESID}"
			fi
		fi
		while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
			do    # List the databases
			printDBEnv "${CHOOSE_INDEX}" ${DATABASE_ENV[${INDEX}]}
			let "INDEX = $INDEX + 1"
			let "CHOOSE_INDEX=$CHOOSE_INDEX +1"		
		done
		readSelection "Selection" "1"  
	else
		if [ "${ASM_ENV}" = "true" ]; then
			DB_ANSWER="1"
		else
			DB_ANSWER="99"
		fi	
	fi
	
else
  if ! [[ "${DB_ANSWER}" =~ ^[0-9]+$ ]] ; then 
		 printError "Please use as parameter a vaild number from 1 to 9!"
		 DB_ANSWER="99"
	fi	      			
fi
	
if [ "${ASM_ENV}" = "true" ]; then
	let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"
fi

if [ "${DB_ANSWER}" -gt "${ELEMENT_COUNT}" ]; then
	 printError "Oracle Enviroment not changed"
	 whichdb 
else
	if [ "${ASM_ENV}" = "true" ]; then
	 let  "INDEX = $DB_ANSWER - 2"
	else
		let "INDEX = $DB_ANSWER - 1"
	fi
	if [ "$ASM_ENV" = "true" ]; then
		if [ "${DB_ANSWER}" = "1" ]; then
			if [ "${CRS_HOME_NAME}" = "OraCrs10g_home" ] ; then
				setDBEnv ${CRS_ASM_HOME} "" ""
			else
				setDBEnv ${CRS_ASM_HOME} ${ASM_INSTANCESID} +ASM
			fi
		else	
			setDBEnv ${DATABASE_ENV[${INDEX}]}
		fi
	else
		setDBEnv ${DATABASE_ENV[${INDEX}]}
	fi

	export PATH=$ORIG_PATH:$ORACLE_HOME/bin

	printLineSuccess
	printList "New ORACLE SID set"  "20" ":" "${ORACLE_SID}"
	printList "New ORACLE HOME set" "20" ":" "{$ORACLE_HOME}"
	printLineSuccess
	
fi

# change the prompt if the function was defined in .bash_profile
declare -f -F myprompt > /dev/null
if [ "$?" -eq "0" ]; then
  myprompt
fi

}

whichdb()
{
	printLine
	printList "Current ORACLE SID"  "20" ":" "${ORACLE_SID}"
	printLine
}

setDBEnv()
{
	export ORACLE_HOME=$1
	export ORACLE_SID=$2
	export ORACLE_UNQNAME=$3    	
}

#

###########################
# ask the user
askYesNo() {
  USER_QUESTION=$1
	QUESTION_DEFAULT=$2	
	if [ ! -n "${QUESTION_DEFAULT}" ]; then
	 QUESTION_DEFAULT="NO"
	fi
	LIMIT=10             
	ANSWER_COUNTER=1
	while [ "$ANSWER_COUNTER" -le $LIMIT ]
	do
		printf "   ${USER_QUESTION}   [%s]:" "${QUESTION_DEFAULT}" 
		read YES_NO_ANSWER
		if [ ! -n "${YES_NO_ANSWER}" ]; then
			YES_NO_ANSWER=${QUESTION_DEFAULT}
		fi
		if [ ! -n "${YES_NO_ANSWER}" ]; then
			printError "Please enter a answer for the question :  ${USER_QUESTION}"
		else
		   if [ "${YES_NO_ANSWER}" == 'NO' ]; then
			  break      
			 else
			  if [ "${YES_NO_ANSWER}" == 'YES' ]; then
				 break
				else
				 printError "Please enter as answer YES or NO !"
			  fi	
      fi				
		fi	
		echo -n "$ANSWER_COUNTER "
		let "ANSWER_COUNTER+=1"
	done  
	if [ ! -n "${YES_NO_ANSWER}" ]; then
		printError "Without a answer  for this question ${USER_QUESTION} for you can not configure the enviroment!"
	fi	
}
#######  ask for the number #######
readSelection() {
  USER_QUESTION=$1
	QUESTION_DEFAULT=$2	
	if [ ! -n "${QUESTION_DEFAULT}" ]; then
	 QUESTION_DEFAULT="1"
	fi
	LIMIT=10             
	ANSWER_COUNTER=1
	while [ "$ANSWER_COUNTER" -le $LIMIT ]
	do
		printf "   ${USER_QUESTION}   [%s]:" "${QUESTION_DEFAULT}" 
		read DB_ANSWER
		if [ ! -n "${DB_ANSWER}" ]; then
			DB_ANSWER=${QUESTION_DEFAULT}
		fi
		if [ ! -n "${DB_ANSWER}" ]; then
			printError "Please enter a answer for the question :  ${USER_QUESTION}"
		else
		  if  [[ "${DB_ANSWER}" =~ ^[0-9]+$ ]] ; then 
			  break      
			else			
				 printError "Please enter as answer 1 to 9 !"
			fi	      				
		fi	
		echo -n "$ANSWER_COUNTER "
		let "ANSWER_COUNTER+=1"
	done  
	if [ ! -n "${DB_ANSWER}" ]; then
		printError "Without a answer  for this question ${USER_QUESTION} you can not work with the database!"	
	fi	
}
##################################################

########### Load defaults ########################

if [ -f ~/.profile_conf ]; then
  . ~/.profile_conf
else
 setdbConfigure
fi

#################################################

export ORACLE_HOME=${DEFAULT_ORACLE_HOME}

if [ "${ASM_ENV}" = "true" ]; then
	export TNS_ADMIN=${CRS_ASM_HOME}/network/admin
else
	export TNS_ADMIN=${ORACLE_HOME}/network/admin	
fi

#################################################
trace(){
cd $ADR_BASE
adrci exec="show homes"
}
#################### END ##############################
