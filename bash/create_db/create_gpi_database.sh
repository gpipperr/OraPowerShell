################# Database creation script ##########################
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#####################################################################
#  Database Installer for a new Database
# Version $Rev:$
#
####################################################################

## environment ######################################################

########### source the helper functions ###########################

. installdb_helper.sh

###################################################################

##  read default config 
CONFFILE=${SCRIPTS}/default.conf
. ${CONFFILE}

# Load ora init defaults
. ${SCRIPTS}/initora.conf

# read default db configuration file 
. ~/.profile

unset SQLPATH

###################################################################
printLine  "-------------------------------------------------"
printLine  "Welcome to the installation of the Database v2.2"
printLine  "-------------------------------------------------"

# check primary configuration
printLine "Check environment ....."
checkEnv
printLine "............... finish"

################### GPIDB #####################################################



PWDFILE=${SCRIPTS}/password.conf
export PWDFILE

## Read encrypted password conf it exits in to memory #########################

if [ -f "${PWDFILE}.des3" ]; then
	dencryptPWDFile
	. ${PWDFILE}
	rm ${PWDFILE}
else
  if [ -f "${PWDFILE}" ]; then
		. ${PWDFILE}
		rm ${PWDFILE}
	else
	 printLine "no preconfiguration password.conf found"
	fi
fi

printLine

###############################################################################

###############################################################################

printLine  "Check on installed ASM enviroment"

if [ "${ASM_ENV}" = "true" ]; then
	printLine  "ASM Enviroment dedected - DB will be installed in ASM modus"
	setdb 1 
	printLine  "Please enter the password of the SYS user of the ASM instance"
	askPassword "ASMCHECK" "SYS" "${S_SYSASM_USER_PWD}" "" "for ASM"
	SYSASM_USER_PWD=${USER_PWD_ANSWER}
	printLine
fi


printf "  please enter the Name of the database you like to install [%s]:" "${S_DATABASE_NAME}"
read ORACLE_DBNAME
if [ ! -n "${ORACLE_DBNAME}" ]; then
	ORACLE_DBNAME=${S_DATABASE_NAME}
fi

#FIX Check for valid names!
#like helper method checkDBConnect - DB should not running, 8 Chars long etc.

#Check if DB exists!
DB_SMON_PROCESS_ID=`ps -Af | grep ora_smon_${ORACLE_DBNAME} | grep -v grep| wc -l`

if [ "${DB_SMON_PROCESS_ID}" = "1" ]; then
 printError "DB ${ORACLE_DBNAME} is running - stop installation"
 exit 1
fi

if [ -f "${ORACLE_HOME}/dbs/hc_${ORACLE_DBNAME}.dat" ]; then
	printError "DB ${ORACLE_DBNAME} HC file exists - stop installation"
  exit 1
fi

# check for exisiting files  on ASM
if [ "${ASM_ENV}" = "true" ]; then

	printLine	
  printLine "Check for existings files for the DB Name::${ORACLE_DBNAME}"
	disktab=\$asm_alias
	checkDBexists=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
                set pagesize 0
								set heading  off
								set feedback off
                select count(*) from v$disktab where upper(name) like '${ORACLE_DBNAME}';
                exit;
EOScipt`

	if [ "${checkDBexists}" -gt "0" ]; then
		printError
		printError "DB Files in ASM for the ${ORACLE_DBNAME} exits - Check Naming or clean enviroment!"
		printError
   exit 1
  fi
	
fi

printLineSuccess
printLineSuccess "Check the name resolution of the DB host"
printLineSuccess

ping -c 1 `hostname`

if [ "$?" -ne "0" ]; then
	printError
	printError "the hostname can not be resolved"
	printError `hostname`
	printError "- check DNS - exit installation"
	printError
	exit 1
fi				

# Check if the 	 listner name can be resolved
if [ ${RAC_ENV} = 'true' ]; then
 
	printLineSuccess
	printLineSuccess "Check the name resolution of the Scan Listner "${SCAN_LISTNER}""
	printLineSuccess
  
	ping -c 1 "${SCAN_LISTNER}"

	if [ "$?" -ne "0" ]; then
		printError
		printError "the hostname can not be resolved"
		printError "${SCAN_LISTNER}"
		printError "- check DNS - exit installation"
		printError
		exit 1
	fi	

fi

printLineSuccess
printLineSuccess "Check the Status of the Oracle Listener"
printLineSuccess
if [ -f "${ORACLE_HOME}/bin/lsnrctl" ]; then
	${ORACLE_HOME}/bin/lsnrctl status
	if [ "$?" -ne "0" ]; then
		if [ "${ASM_ENV}" = "true" ]; then
			printError
			printError "Listener for the DB ${ORACLE_DBNAME} is NOT running - start/Configure Listener!"
			printError
			exit 1
		else
	   printError 
		 printError "try to start the listener and check again"
		 ${ORACLE_HOME}/bin/lsnrctl start
		 ${ORACLE_HOME}/bin/lsnrctl status
		 if [ "$?" -ne "0" ]; then
			printError
			printError "Listener for the DB ${ORACLE_DBNAME} could not be start - check configuration of the listener!"
			printError
		 fi
		fi 	
	fi
else
  printError "Listener Control for ${ORACLE_HOME}/bin/lsnrctl not found - Configure enviroment!"	
  exit 1
fi

printLineSuccess 
printLineSuccess

printf "  please enter the Edition of the database you like to install \n  EE for Enterprise or SE for Standard [%s]: " "${S_DB_EDITON}"
read DB_EDITON

if [ ! -n "${DB_EDITON}" ]; then
	DB_EDITON=${S_DB_EDITON}
fi

if [ "${DB_EDITON}" != 'EE' ]; then
	if [ "${DB_EDITON}" != 'SE' ]; then
		printError "Please enter as answer EE or SE ! - Exit installation"
		exit 1	
	fi
fi

#FIX Check for the DB edition needs to be implemented over the software

printLine	
printLine   "Environment"
printList  "Database" "20"  ":" 	"${ORACLE_DBNAME}"

if [ ${RAC_ENV} = 'true' ]; then
  for NODE in $VIPNODES
  do
		printList "Hostnames" "20"  ":" 	"${NODE}"		
	done
else
	 printList   "Hostname" "20"  ":" 	"${DBHOST_NAME}"
fi


if [ "${ASM_ENV}" = "true" ]; then
  if [ "${RAC_ENV}" = "true" ]; then
	  printList   "Scanlistner" "20"  ":" 	"${SCAN_LISTNER}" 
		printList   "DB Type" "20"  ":" 	"RAC - Real Application Cluster"
	else
	 printList   "DB Type" "20"  ":" 	"Single Instance"
	fi	
	printList   "DB Storage" "20"  ":" 	"ASM Storage"
	
else
	printList   "DB Type" "20"  ":" 	"Single Instance"
	printList   "DB Storage" "20"  ":" 	"Filesystem Storage"
fi


printList   "DB Version" "20"  ":" 	"${DB_VERSION}"
printList   "DB Edition" "20"  ":" 	"${DB_EDITON}"


if [ "${ASM_ENV}" = "true" ]; then
  printLine	
  printLine "Possible data location on the asm instance " "${ORACLE_SID} :"
	disktab=\$asm_diskgroup
	datalocations=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
                set pagesize 0
								set heading  off
								set feedback off
                select name from v$disktab group by name;
                exit;
EOScipt`

printLineSuccess ${datalocations}

fi
printLine	
printLine "Define the Character Set of your database"
printf    "  please enter the Charset of the database you like to install [%s]: " "${S_CHARACTER_SET}"
read CHARACTER_SET

if [ ! -n "${CHARACTER_SET}" ]; then
	CHARACTER_SET=${S_CHARACTER_SET}
fi

printLine	
printLine	 "Define the storage locations for the datafiles of your database"

askDatafileLocation "Redo Log Destination 1" "${S_FILE_DATA_LOCATION}" "${S_REDOLOG_DEST1}" "${S_ASM_REDOLOG_DEST1}"
REDOLOG_DEST1=${ANSWER_DAT_LOCATION}

askDatafileLocation "Redo Log Destination 2" "${S_FILE_DATA_LOCATION}" "${S_REDOLOG_DEST2}" "${S_ASM_REDOLOG_DEST2}"
REDOLOG_DEST2=${ANSWER_DAT_LOCATION}

askDatafileLocation "System Tablespace" "${S_FILE_DATA_LOCATION}" "${S_SYSTEM_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
SYSTEM_TAB_LOC=${ANSWER_DAT_LOCATION}

askDatafileLocation "SYSAUX Tablespace" "${S_FILE_DATA_LOCATION}" "${S_SYSAUX_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
SYSAUX_TAB_LOC=${ANSWER_DAT_LOCATION}

askDatafileLocation "AUDITLOG Tablespace" "${S_FILE_DATA_LOCATION}" "${S_AUDIT_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
AUDIT_TAB_LOC=${ANSWER_DAT_LOCATION}




if [ ${RAC_ENV} = 'true' ]; then
		RAC_COUNTER=1
		for NODE in $VIPNODES
		do	
			askDatafileLocation "TEMP ${RAC_COUNTER} Tablespace" "${S_FILE_DATA_LOCATION}" "${S_TEMP01_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
			eval "TEMP0${RAC_COUNTER}_TAB_LOC=${ANSWER_DAT_LOCATION}"
			askDatafileLocation "UNDO ${RAC_COUNTER} Tablespace" "${S_FILE_DATA_LOCATION}" "${S_UNDO01_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
			eval "UNDO0${RAC_COUNTER}_TAB_LOC=${ANSWER_DAT_LOCATION}"
			let "RAC_COUNTER+=1"
		done
	else
		askDatafileLocation "TEMP Tablespace" "${S_FILE_DATA_LOCATION}" "${S_TEMP01_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
		TEMP01_TAB_LOC=${ANSWER_DAT_LOCATION}
		askDatafileLocation "UNDO 1 Tablespace" "${S_FILE_DATA_LOCATION}" "${S_UNDO01_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
		UNDO01_TAB_LOC=${ANSWER_DAT_LOCATION}
fi


askDatafileLocation "USER Tablespace" "${S_FILE_DATA_LOCATION}" "${S_USER_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
USER_TAB_LOC=${ANSWER_DAT_LOCATION}

askDatafileLocation "Flash Recovery" "${S_ORACLE_BASE}" "${S_FLASH_RECO_LOC}" "${S_ASM_FLASH_LOCATION}"
FLASH_RECO_LOC=${ANSWER_DAT_LOCATION}

# Rember Size of FLASH Location
if [ "${ASM_ENV}" = "true" ]; then
	FLASH_RECO_SIZE=`echo ${DISK_GROUP_SIZE} | awk '{ print($7); }'`
	FLASH_RECO_SIZE=${FLASH_RECO_SIZE}M
else
 FLASH_RECO_SIZE=${S_FLASH_RECO_SIZE}
fi


######################## ORACLE HOME and SID ##################################
printLine 
printLine "Use as ORACLE_HOME for the DB Install the path from default.conf :: " "${S_ORACLE_HOME}"
ORACLE_HOME="${S_ORACLE_HOME}"
export ORACLE_HOME
printLine "Use as ORACLE BASE for the DB Install the path from default.conf :: " "${S_ORACLE_BASE}"
ORACLE_BASE="${S_ORACLE_BASE}"

askYesNo "Use this Oracle Home and Oracle Base?" "NO"
printError
if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  ""
else
 printError
 printError "If you like an other home, please edit the default.conf file"
 printError
 exit 1
fi


if [ ${RAC_ENV} = 'true' ]; then
  for NODE in $VIPNODES
  do
		ORACLE_SID=${ORACLE_DBNAME}1
	done
else
	 ORACLE_SID=${ORACLE_DBNAME}	 
fi
export ORACLE_SID
printLine   " Instance  :  	${ORACLE_SID}"


###############################################################################

printLine		
printLine  "Oracle System User Passwords"
printLine


#SYS PWD
askPassword "NOCHECK" "SYS" "${S_SYS_USER_PWD}" ""
SYS_USER_PWD=${USER_PWD_ANSWER}

askPassword "NOCHECK" "SYSTEM" "${S_SYSTEM_USER_PWD}" ""
SYSTEM_USER_PWD=${USER_PWD_ANSWER}

askPassword "NOCHECK" "SYSMAN" "${S_SYSMAN_USER_PWD}" ""
SYSMAN_USER_PWD=${USER_PWD_ANSWER}

askPassword "NOCHECK" "DBSNMP" "${S_DBSNMP_USER_PWD}" ""
DBSNMP_USER_PWD=${USER_PWD_ANSWER}

################################# store config ################################


echo "S_DATABASE_HOSTNAME=${DBHOST_NAME}" 			 >   ${CONFFILE}
echo "S_DATABASE_NAME=${ORACLE_DBNAME}" 		 	>>   ${CONFFILE}
echo "S_CHARACTER_SET=${CHARACTER_SET}"				>>   ${CONFFILE}
echo "S_ORACLE_BASE=${ORACLE_BASE}"  				>>  ${CONFFILE}
echo "S_ORACLE_HOME=${ORACLE_HOME}"  				>>  ${CONFFILE}
echo "S_DB_EDITON=${DB_EDITON}"  			    	>>  ${CONFFILE}

echo "S_DATABASE_SCANLISTNER=${SCAN_LISTNER}"  		>>  ${CONFFILE}
echo "S_FILE_DATA_LOCATION=${ORACLE_BASE}/oradata"  >>  ${CONFFILE}

echo "S_ASM_HOME=${ASM_HOME}"  			    		>>  ${CONFFILE}

if [ "${ASM_ENV}" = "true" ]; then
	echo "S_ASM_DATA_LOCATION=${S_ASM_DATA_LOCATION}"  >>  ${CONFFILE}
	echo "S_ASM_REDOLOG_DEST1=${REDOLOG_DEST1}" 			 >>  ${CONFFILE}
	echo "S_ASM_REDOLOG_DEST2=${REDOLOG_DEST2}" 			 >>  ${CONFFILE}
fi

echo "S_REDOLOG_DEST1=${S_REDOLOG_DEST1}" 		>>  ${CONFFILE}
echo "S_REDOLOG_DEST2=${S_REDOLOG_DEST2}" 		>>  ${CONFFILE}
echo "S_SYSTEM_TAB_LOC=${S_SYSTEM_TAB_LOC}" 	>>  ${CONFFILE}
echo "S_SYSAUX_TAB_LOC=${S_SYSAUX_TAB_LOC}" 	>>  ${CONFFILE}
echo "S_AUDIT_TAB_LOC=${S_AUDIT_TAB_LOC}" 	    >>  ${CONFFILE}

echo "S_USER_TAB_LOC=${S_USER_TAB_LOC}" 			>>  ${CONFFILE}

echo "S_FLASH_RECO_LOC=${S_FLASH_RECO_LOC}" 			>>  ${CONFFILE}
echo "S_FLASH_RECO_SIZE=${FLASH_RECO_SIZE}" 		>>  ${CONFFILE}
echo "S_ASM_FLASH_LOCATION=${FLASH_RECO_LOC}" 	>>  ${CONFFILE}


if [ ${RAC_ENV} = 'true' ]; then
  RAC_COUNTER=1
  for NODE in $VIPNODES
  do
	  if [ "${RAC_COUNTER}" = 1 ]; then
			echo "S_TEMP${RAC_COUNTER}_TAB_LOC=${TEMP1_TAB_LOC}" 	>>  ${CONFFILE}
			echo "S_UNDO${RAC_COUNTER}_TAB_LOC=${UNDO1_TAB_LOC}" 	>>  ${CONFFILE}
	  fi
		if [ "${RAC_COUNTER}" = 2 ]; then
			echo "S_TEMP${RAC_COUNTER}_TAB_LOC=${TEMP2_TAB_LOC}" 	>>  ${CONFFILE}
			echo "S_UNDO${RAC_COUNTER}_TAB_LOC=${UNDO2_TAB_LOC}" 	>>  ${CONFFILE}
	  fi
		if [ "${RAC_COUNTER}" = 3 ]; then
			echo "S_TEMP${RAC_COUNTER}_TAB_LOC=${TEMP3_TAB_LOC}" 	>>  ${CONFFILE}
			echo "S_UNDO${RAC_COUNTER}_TAB_LOC=${UNDO3_TAB_LOC}" 	>>  ${CONFFILE}
	  fi
		if [ "${RAC_COUNTER}" = 4 ]; then
			echo "S_TEMP${RAC_COUNTER}_TAB_LOC=${TEMP4_TAB_LOC}" 	>>  ${CONFFILE}
			echo "S_UNDO${RAC_COUNTER}_TAB_LOC=${UNDO4_TAB_LOC}" 	>>  ${CONFFILE}
	  fi		
		let "RAC_COUNTER+=1"
	done
else
	echo "S_UNDO01_TAB_LOC=${S_UNDO01_TAB_LOC}" 	>>  ${CONFFILE}	
	echo "S_TEMP01_TAB_LOC=${S_TEMP01_TAB_LOC}" 	>>  ${CONFFILE}	
fi

##################################################################

echo "S_SYS_USER_PWD=${SYS_USER_PWD}" 					 >  ${PWDFILE}
echo "S_SYSASM_USER_PWD=${SYSASM_USER_PWD}" 		>>  ${PWDFILE}
echo "S_DBSNMP_USER_PWD=${DBSNMP_USER_PWD}" 		>>  ${PWDFILE}
echo "S_SYSMAN_USER_PWD=${SYSMAN_USER_PWD}" 		>>  ${PWDFILE}
echo "S_SYSTEM_USER_PWD=${SYSTEM_USER_PWD}" 		>>  ${PWDFILE}


##################################################################

printLine

# encrypt the password files
encryptPWDFile

##################################################################
printLine
printLine  "Create the nessesary directories"

OLD_UMASK=`umask`
umask 0027

ORA_DIR_LIST[1]=${ORACLE_BASE}/admin/${ORACLE_DBNAME}/adump
ORA_DIR_LIST[2]=${ORACLE_BASE}/admin/${ORACLE_DBNAME}/dpdump
ORA_DIR_LIST[3]=${ORACLE_BASE}/admin/${ORACLE_DBNAME}/pfile
ORA_DIR_LIST[4]=${ORACLE_BASE}/admin/${ORACLE_DBNAME}/pfile
ORA_DIR_LIST[5]=${ORACLE_BASE}/cfgtoollogs/dbca/${ORACLE_DBNAME}


if [ ${RAC_ENV} = "true" ]; then
  for NODE in ${VIPNODES[@]}
  do
	  for ORA_DIR in ${ORA_DIR_LIST[@]}
		 do
			ssh ${NODE} mkdir -p ${ORA_DIR}	
			printLine  "Create directory on ${NODE} :: ${ORA_DIR}"			
		done
	done
else
	for ORA_DIR in ${ORA_DIR_LIST[@]}
		 do
		 if [ ! -d "${ORA_DIR}" ]; then
			mkdir -p ${ORA_DIR}				
			if [ "$?" -ne "0" ]; then
				printError "Cannot create the Directory ${ORA_DIR} - check the path (rights?)"
				exit 1
			else
			 	printLine  "Create directory :: ${ORA_DIR}"
			fi	
		fi	
	done
fi

# Create path if not exists
if [ "${ASM_ENV}" = "false" ]; then

	if [ ! -d "${FLASH_RECO_LOC}/${ORACLE_DBNAME}" ]; then
		mkdir -p ${FLASH_RECO_LOC}/${ORACLE_DBNAME}				
		if [ "$?" -ne "0" ]; then
				printError "Cannot create the Directory ${FLASH_RECO_LOC}/${ORACLE_DBNAME}	 - check the path (rights?)"
				exit 1
		else
			printLine  "Create directory :: ${FLASH_RECO_LOC}/${ORACLE_DBNAME}"
		fi	
	fi

	if [ ! -d "${ORACLE_BASE}/oradata/${ORACLE_DBNAME}" ]; then
		mkdir -p ${ORACLE_BASE}/oradata/${ORACLE_DBNAME}				
		if [ "$?" -ne "0" ]; then
				printError "Cannot create the Directory ${ORACLE_BASE}/oradata/${ORACLE_DBNAME} - check the path (rights?)"
				exit 1
		else
			printLine  "Create directory :: ${ORACLE_BASE}/oradata/${ORACLE_DBNAME}"
		fi	
	fi	
	
	if [ ! -d "${REDOLOG_DEST1}/${ORACLE_DBNAME}" ]; then
		mkdir -p ${REDOLOG_DEST1}/${ORACLE_DBNAME}
		if [ "$?" -ne "0" ]; then
				printError "Cannot create the Directory ${REDOLOG_DEST1}/${ORACLE_DBNAME} - check the path (rights?)"
				exit 1
		else
			printLine  "Create directory :: ${REDOLOG_DEST1}/${ORACLE_DBNAME}"
		fi		
	else
	  if [ -f "${REDOLOG_DEST1}/${ORACLE_DBNAME}/control01.ctl" ]; then
			printError
			printError "controlfile ${REDOLOG_DEST1}/${ORACLE_DBNAME}/control01.ctl for this DB still exists! Check for old DB and cleanup enviroment!"
			printError
			exit -1
		fi
	fi		
	
	if [ ! -d "${REDOLOG_DEST2}/${ORACLE_DBNAME}" ]; then
		mkdir -p ${REDOLOG_DEST2}/${ORACLE_DBNAME}
		if [ "$?" -ne "0" ]; then
				printError "Cannot create the Directory ${REDOLOG_DEST2}/${ORACLE_DBNAME} - check the path (rights?)"
				exit 1
		else
			printLine  "Create directory :: ${REDOLOG_DEST2}/${ORACLE_DBNAME}"
		fi		
	else
	  if [ -f "${REDOLOG_DEST2}/${ORACLE_DBNAME}/control02.ctl" ]; then
			printError
			printError "controlfile ${REDOLOG_DEST2}/${ORACLE_DBNAME}/control02.ctl for this DB still exists! Check for old DB and cleanup enviroment!"
			printError
			exit -1
		fi
	fi
	
  if [ -f "${ORACLE_BASE}/oradata/${ORACLE_DBNAME}/control03.ctl" ]; then
			printError
			printError "controlfile ${ORACLE_BASE}/oradata/${ORACLE_DBNAME}/control03.ctl for this DB still exists! Check for old DB and cleanup enviroment!"
			printError
			exit -1
		fi	
fi
printLine
printLine  "Start the installation of the database with the following parameter:"

printList  "Oracle Home" 			"22" 		":"  ${ORACLE_HOME} 
printList  "Oracle DB Name" 	"22"	 ":"	${ORACLE_DBNAME} 
printList  "Oracle DB Edition" 	"22"	 ":"	${DB_EDITON}

printLine

if [ ${RAC_ENV} = 'true' ]; then
	printList "Oracle Rac" "22" ":" "Will be installed"
	RAC_COUNTER=1
	for NODE in $VIPNODES
  do
	  printList "RAC Node ${RAC_COUNTER}" "22" ":" ${NODE}
		let "RAC_COUNTER+=1"
	done
else
 printList "Oracle Rac" "22" ":" "No RAC Enviroment"
fi

printLine
printList  "Main Character Set"     "22" ":"    ${CHARACTER_SET} 
printLine
printList  "Compatible Parameter"    "22" ":"   ${S_COMPATIBLE}
printList  "Blocksize  Parameter"    "22" ":"   ${S_DB_BLOCK_SIZE}  

printLine
printList  "System Tablespace"      "22" ":"	 ${SYSTEM_TAB_LOC} 
printList  "Sysaux Tablespace"      "22" ":"	 ${SYSAUX_TAB_LOC} 
printList  "Auditlog Tablespace"    "22" ":"	 ${AUDIT_TAB_LOC} 

printList  "Temp Tablespace"        "22" ":"	 ${TEMP01_TAB_LOC} 
printList  "Undo Tablespace"        "22" ":"	 ${UNDO01_TAB_LOC} 
printList  "Redolog destination 1"  "22" ":"	 ${REDOLOG_DEST1}/${ORACLE_DBNAME}
printList  "Redolog destination 2"  "22" ":"	 ${REDOLOG_DEST2}/${ORACLE_DBNAME}
printList  "FLASH Recovery Area"    "22" ":"	 ${FLASH_RECO_LOC}
printList  "Diagnostic Destination" "22" ":"	 ${ORACLE_BASE}
printError
askYesNo "Do you want to start the DB creation?" "NO"
printError
if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  "Start ........... "
else
 printError
 printError "You cancel the creation of the DB with the answer ${YES_NO_ANSWER}"
 printError
 exit 1
fi

umask ${OLD_UMASK}

PATH=${ORACLE_HOME}/bin:$PATH; export PATH

 
#############  create the init.ora #############


# calculate memoray size
#
SYSTEM_MEMORY=`free -m | grep Mem | awk '{ print($2); }'`

if [ "${SYSTEM_MEMORY}" -lt "16000" ]; then
 let "MEMORY_TARGET=SYSTEM_MEMORY/100*40"
elif [ "${SYSTEM_MEMORY}" -lt "24000" ]; then
  MEMORY_TARGET="12000"
elif [ "${SYSTEM_MEMORY}" -lt "32000" ]; then
  MEMORY_TARGET="20000"
else
 MEMORY_TARGET="24000"
fi

# if Enviroment very small (example VM test env.) use min 800M
if [ "${MEMORY_TARGET}" -lt "750" ]; then
	MEMORY_TARGET="800"
fi

# Check if the shared memory is configured properly
# get only the first value
SHARED_MEMORY=$(df -k | grep tmpfs | head -1 | awk '{print($2)/1024;}')
#round
SHARED_MEMORY=$(echo $SHARED_MEMORY | awk '{print int($1)}')
#Check
if [[ "${SHARED_MEMORY}" -lt "${MEMORY_TARGET}" ]]; then
  printError
  printError "Your current size of the shared memory (${SHARED_MEMORY} MB) is smaller than the allocated memory target (${MEMORY_TARGET} MB) for the Oracle DB instance."
  printError "Possible solution : As root, increase the shared memory /dev/shm mountpoint size (also set the size in /etc/fstab), then remount (tmpfs)"
  printError
  exit 1
fi

echo "log_archive_format=%t_%s_%r.dbf"  >  ${SCRIPTS}/init.ora
echo "db_block_size=${S_DB_BLOCK_SIZE}"	>> ${SCRIPTS}/init.ora
echo "open_cursors=${S_OPEN_CURSORS}"	>> ${SCRIPTS}/init.ora
echo "db_domain=\"\""					>> ${SCRIPTS}/init.ora
echo "db_name=\"${ORACLE_DBNAME}\""		>> ${SCRIPTS}/init.ora

if [ "${ASM_ENV}" = "true" ]; then
	echo "control_files=(\"${REDOLOG_DEST1}/${ORACLE_DBNAME}/control01.ctl\",\"${REDOLOG_DEST2}/${ORACLE_DBNAME}/control02.ctl\",\"${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/control03.ctl\")"  >> ${SCRIPTS}/init.ora
else
	echo "control_files=(\"${REDOLOG_DEST1}/${ORACLE_DBNAME}/control01.ctl\",\"${REDOLOG_DEST2}/${ORACLE_DBNAME}/control02.ctl\",\"${ORACLE_BASE}/oradata/${ORACLE_DBNAME}/control03.ctl\")" >> ${SCRIPTS}/init.ora
fi

echo "db_recovery_file_dest=\"${FLASH_RECO_LOC}\"" 	    >> ${SCRIPTS}/init.ora

echo "db_recovery_file_dest_size=${FLASH_RECO_SIZE}" 	>> ${SCRIPTS}/init.ora

echo "compatible=${S_COMPATIBLE}" 						>> ${SCRIPTS}/init.ora
echo "diagnostic_dest=\"${ORACLE_BASE}\"" 		        >> ${SCRIPTS}/init.ora

echo "sga_target=${MEMORY_TARGET}M"				        >> ${SCRIPTS}/init.ora
echo "processes=${S_PROCESSES}" 					    >> ${SCRIPTS}/init.ora
echo "sessions=${S_SESSIONS}" 						    >> ${SCRIPTS}/init.ora

echo "audit_file_dest=\"${ORACLE_BASE}/admin/${ORACLE_DBNAME}/adump\"" >> ${SCRIPTS}/init.ora
echo "audit_trail=db" 													>> ${SCRIPTS}/init.ora
echo "remote_login_passwordfile=EXCLUSIVE" 			>> ${SCRIPTS}/init.ora

## gpi  init.ora settings

echo "undo_retention=1800" 							>> ${SCRIPTS}/init.ora

if [ "${DB_EDITON}" = 'EE' ]; then
	echo "fast_start_mttr_target=600" 		>> ${SCRIPTS}/init.ora
fi;

echo "audit_sys_operations=false" 		>> ${SCRIPTS}/init.ora
echo "audit_trail=DB"									>> ${SCRIPTS}/init.ora


if [ ${RAC_ENV} = 'true' ]; then
	RAC_COUNTER=1
	for NODE in $VIPNODES
  do
		echo "${ORACLE_DBNAME}${RAC_COUNTER}.instance_number=${RAC_COUNTER}" 				>> ${SCRIPTS}/init.ora
		echo "${ORACLE_DBNAME}${RAC_COUNTER}.thread=${RAC_COUNTER}"									>> ${SCRIPTS}/init.ora
		echo "${ORACLE_DBNAME}${RAC_COUNTER}.undo_tablespace=UNDOTBS${RAC_COUNTER}"	>> ${SCRIPTS}/init.ora
		if [ "${DB_EDITON}" = 'EE' ]; then
			echo "${ORACLE_DBNAME}${RAC_COUNTER}.instance_groups=IGroup${ORACLE_DBNAME}${RAC_COUNTER}"					>> ${SCRIPTS}/init.ora
			echo "${ORACLE_DBNAME}${RAC_COUNTER}.parallel_instance_group=IGroup${ORACLE_DBNAME}${RAC_COUNTER}"	>> ${SCRIPTS}/init.ora
		fi;
		let "RAC_COUNTER+=1"
	done
else
	echo "undo_tablespace=UNDOTBS1" >> ${SCRIPTS}/init.ora
fi


##################################START DB SCRIPTS    #############################################

# create the password file
printLine
printLine  "Create the Oracle DB password File"
if [ ${RAC_ENV} = "true" ]; then
 ## if cluster copy to the other nodes
 typeset -i cnode=1
 for NODE in $VIPNODES
  do 
	  # to fix the "Unable to find error file." message with call oracle orapwd over ssh, set ORACLE_HOME 
		ssh ${NODE} "export ORACLE_HOME=${ORACLE_HOME}; ${ORACLE_HOME}/bin/orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_DBNAME}${cnode} force=y	 password=${SYS_USER_PWD}"
		cnode=cnode+1
	done
else
	${ORACLE_HOME}/bin/orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_DBNAME} force=y password=${SYS_USER_PWD}
fi
printLine

##################################################################

# ASM setting for user rights and grep all storage locations
printLine
printLine  "Generate the ASM settings if nessesary"

if [ "${ASM_ENV}" = "true" ]; then
	${ASM_HOME}/bin/setasmgidwrap o=${ORACLE_HOME}/bin/oracle
   # get a list of all used disk for the srvctl command
  getCommaList ${REDOLOG_DEST1} ${REDOLOG_DEST2} ${SYSTEM_TAB_LOC} ${SYSAUX_TAB_LOC} ${TEMP01_TAB_LOC} ${UNDO01_TAB_LOC} ${UNDO02_TAB_LOC} ${UNDO03_TAB_LOC} ${FLASH_RECO_LOC}
  A_PARAMETER_LOCATIONS=${COMMA_LIST}
	
fi

printLine

############################################

printLine
printLine  "If RAC enviroment :: add database to cluster registry"

## RAC
if [ ${RAC_ENV} = 'true' ]; then
 ${ORACLE_HOME}/bin/srvctl add database -d ${ORACLE_DBNAME} -o ${ORACLE_HOME} -p ${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/spfile${ORACLE_DBNAME}.ora -n ${ORACLE_DBNAME} -a ${A_PARAMETER_LOCATIONS}
 
 RAC_COUNTER=1
 for NODE in $VIPNODES
  do
	${ORACLE_HOME}/bin/srvctl add instance -d ${ORACLE_DBNAME} -i ${ORACLE_DBNAME}${RAC_COUNTER} -n ${NODE}
	let "RAC_COUNTER+=1"
 done 
 
 ${ORACLE_HOME}/bin/srvctl disable database -d ${ORACLE_DBNAME}

fi 
printLine


# Basic DB
printLine
printLine  "Start Oracle DB Creation"
######
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/CreateDB.sql ${SYS_USER_PWD} ${ORACLE_DBNAME} ${REDOLOG_DEST1} ${REDOLOG_DEST2} ${SYSTEM_TAB_LOC} ${SYSAUX_TAB_LOC}  ${TEMP01_TAB_LOC} ${UNDO01_TAB_LOC} ${CHARACTER_SET}

printLine  "Start Oracle DB Files"
# DB files
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/CreateDBFiles.sql ${SYS_USER_PWD} ${USER_TAB_LOC}

printLine  "Start Oracle UNDO Files"
# RAC other files
if [ ${RAC_ENV} = 'true' ]; then

 typeset -i RAC_COUNTER=1
 for NODE in $VIPNODES
  do
		if [ $RAC_COUNTER > 1 ]; then
			${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/CreateUndoFiles.sql ${SYS_USER_PWD}	 ${UNDO02_TAB_LOC} $RAC_COUNTER
		fi
		RAC_COUNTER=RAC_COUNTER+1
	done 	
fi

# Catalog and options

printLine  "Start Oracle Create Catalog - Take round about 40min"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/CreateDBCatalog.sql ${SYS_USER_PWD}  ${SYSTEM_USER_PWD}
printLine "create Java enviroment"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/JServer.sql         ${SYS_USER_PWD}
printLine "create Oracle text enviroment"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/context.sql         ${SYS_USER_PWD}
printLine "setup XML DB Java"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/xdb_protocol.sql    ${SYS_USER_PWD}
printLine "setup ord data"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/ordinst.sql         ${SYS_USER_PWD}
printLine "setup Intermedia"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/interMedia.sql      ${SYS_USER_PWD}

if [ "${DB_EDITON}" = 'EE' ]; then
	printLine "setup cwm"
	${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/cwmlite.sql         ${SYS_USER_PWD}
	printLine "setup Spatial"
	${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/spatial.sql         ${SYS_USER_PWD}
fi
printLine "setup emRepository"
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/emRepository.sql    ${SYS_USER_PWD} ${ORACLE_HOME} ${SYSMAN_USER_PWD}

if [ ${RAC_ENV} = 'true' ]; then
  printLine "create Cluster DB Views"
	${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/CreateClustDBViews.sql ${SYS_USER_PWD}
fi


if [ "${ASM_ENV}" = "true" ]; then
  if [ ${RAC_ENV} = 'false' ]; then
		printLine "Add database to the ASM Grid Control"
		${ORACLE_HOME}/bin/srvctl add database -d ${ORACLE_DBNAME} -o ${ORACLE_HOME} -p ${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/spfile${ORACLE_DBNAME}.ora -n ${ORACLE_DBNAME} -a ${A_PARAMETER_LOCATIONS}
  fi	 
fi

# create the init.ora
if [ "${ASM_ENV}" = "true" ]; then
	if [ ${RAC_ENV} = 'true' ]; then
	 RAC_COUNTER=1	 
	 for NODE in $VIPNODES
		do
			echo "SPFILE='${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/spfile${ORACLE_DBNAME}.ora'" > /tmp/init${ORACLE_DBNAME}${RAC_COUNTER}.ora
			scp /tmp/init${ORACLE_DBNAME}${RAC_COUNTER}.ora ${NODE}:${ORACLE_HOME}/dbs/init${ORACLE_DBNAME}${RAC_COUNTER}.ora			
			let "RAC_COUNTER+=1"		
		done
	else
		echo "SPFILE='${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/spfile${ORACLE_DBNAME}.ora'" > ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
	fi	
fi

#
##RAC
# add to init .ora
if [ ${RAC_ENV} = 'true' ]; then
	echo "cluster_database=true" 							  	>> ${SCRIPTS}/init.ora
	echo "remote_listener=${SCAN_LISTNER}:1521"  >> ${SCRIPTS}/init.ora
fi

# lock account
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/lockAccount.sql  ${SYS_USER_PWD}


#Enable Archiving  and create spfile
if [ "${ASM_ENV}" = "true" ]; then
	SPFILE_LOCATION="${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/spfile${ORACLE_DBNAME}.ora"
	TRACK_FILE_LOCATION="${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/db_track${ORACLE_DBNAME}.dmp"
else
	SPFILE_LOCATION="${ORACLE_HOME}/dbs/spfile${ORACLE_DBNAME}.ora"
	# FIX IT - TESTING required!
	TRACK_FILE_LOCATION="${SYSTEM_TAB_LOC}/${ORACLE_DBNAME}/db_track${ORACLE_DBNAME}.dmp"
fi
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/postDBCreation.sql ${SYS_USER_PWD} 
${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/createSPFile.sql   ${SYS_USER_PWD} ${SPFILE_LOCATION}

${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/gpi_setup.sql ${SYS_USER_PWD}  ${AUDIT_TAB_LOC}

if [ "${DB_EDITON}" = 'EE' ]; then
	${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/gpi_setup_ee.sql ${SYS_USER_PWD} ${TRACK_FILE_LOCATION}
fi;


if [ ${RAC_ENV} = 'true' ]; then
	# if RAC add nodes add threads 
	typeset -i RAC_COUNTER=1
	for NODE in $VIPNODES
  do
		if [ $RAC_COUNTER = 2 ];
		then 
			${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/addThread1.sql ${SYS_USER_PWD} ${ORACLE_DBNAME} ${REDOLOG_DEST1} ${REDOLOG_DEST2}
		fi
		if [ $RAC_COUNTER = 3 ]; 
		then
			${ORACLE_HOME}/bin/sqlplus /nolog @${SCRIPTS}/addThread2.sql ${SYS_USER_PWD} ${ORACLE_DBNAME} ${REDOLOG_DEST1} ${REDOLOG_DEST2}
		fi
		RAC_COUNTER=RAC_COUNTER+1
	done 	
fi

# Add DB to the ASM or Cluster control
if [ "${ASM_ENV}" = "true" ]; then
  #if [ ${RAC_ENV} = 'false' ]; then
	${ORACLE_HOME}/bin/srvctl enable database -d ${ORACLE_DBNAME}
	${ORACLE_HOME}/bin/srvctl start  database -d ${ORACLE_DBNAME}
	#fi
fi

# create the enterprise manager
#  Check the definition of the ASM USER PASSWORD! SYSASM_USER_PWD!!
if [ ${RAC_ENV} = 'true' ]; then
	${ORACLE_HOME}/bin/emca -config dbcontrol db -silent -cluster -ASM_USER_ROLE SYSDBA -ASM_USER_NAME ASMSNMP -CLUSTER_NAME ${CLUSTER_NAME} -LOG_FILE ${SCRIPTS}/emConfig.log -SID ${ORACLE_SID} -ASM_SID +ASM1 -DB_UNIQUE_NAME ${ORACLE_DBNAME} -EM_HOME ${ORACLE_HOME} -SERVICE_NAME ${ORACLE_DBNAME} -ASM_PORT 1521 -PORT 1521 -LISTENER_OH ${ASM_HOME} -LISTENER LISTENER -ORACLE_HOME ${ORACLE_HOME} -HOST ${DBHOST_NAME} -ASM_OH ${ASM_HOME} -SYS_PWD ${SYS_USER_PWD} -DBSNMP_PWD ${DBSNMP_USER_PWD} -SYSMAN_PWD ${SYSMAN_USER_PWD} -ASM_USER_PWD ${SYSASM_USER_PWD}
else
	if [ "${ASM_ENV}" = "true" ]; then
		${ORACLE_HOME}/bin/emca -config dbcontrol db -silent -ASM_USER_ROLE SYSDBA -ASM_USER_NAME ASMSNMP -LOG_FILE ${SCRIPTS}/emConfig.log -SID ${ORACLE_SID} -ASM_SID +ASM -DB_UNIQUE_NAME ${ORACLE_DBNAME} -EM_HOME ${ORACLE_HOME} -SERVICE_NAME ${ORACLE_DBNAME} -ASM_PORT 1521 -PORT 1521 -LISTENER_OH ${ASM_HOME} -LISTENER LISTENER -ORACLE_HOME ${ORACLE_HOME} -HOST ${DBHOST_NAME} -ASM_OH ${ASM_HOME} -SYS_PWD ${SYS_USER_PWD} -DBSNMP_PWD ${DBSNMP_USER_PWD} -SYSMAN_PWD ${SYSMAN_USER_PWD} -ASM_USER_PWD ${SYS_USER_PWD}
	else
		${ORACLE_HOME}/bin/emca -config dbcontrol db -silent -DB_UNIQUE_NAME ${ORACLE_DBNAME} -PORT 1521 -EM_HOME ${ORACLE_HOME} -LISTENER LISTENER -SERVICE_NAME ${ORACLE_DBNAME} -SID ${ORACLE_SID} -ORACLE_HOME ${ORACLE_HOME} -HOST ${DBHOST_NAME} -LISTENER_OH ${ORACLE_HOME} -SYS_PWD ${SYS_USER_PWD} -DBSNMP_PWD ${DBSNMP_USER_PWD} -SYSMAN_PWD ${SYSMAN_USER_PWD}
	fi 
fi

# edit /etc/oratab
if [ ${RAC_ENV} = 'true' ]; then
 for NODE in $VIPNODES
  do 
		ssh ${NODE} echo  "${ORACLE_DBNAME}:${ORACLE_HOME}:Y" >> /etc/oratab
	done	
else
	echo  "${ORACLE_DBNAME}:${ORACLE_HOME}:Y" >> /etc/oratab
fi

# Start script if only on file system
if [ "${RAC_ENV}" = "false" ]; then
 if [ "${ASM_ENV}" = "false" ]; then
	printError
  printError " Please copy as root  => \" cp ${SCRIPTS}/startdatabase_single_instance.sh /etc/init.d/oracle\" as root"
  printError " Enable Start/Stop with runlevel editor \"chkconfig oracle\" as root"	
	printError
 fi
fi

# Configure the enviroment 
printLineSuccess
printLineSuccess " -- the .profile enviroment need to be adjusted please answer YES!"


if [ "${RAC_ENV}" = "true" ]; then
 	for NODE in ${VIPNODES[@]}
		do		
		printLineSuccess
		printLineSuccess  "Refresh configuration on this node => ${NODE}"			
		ssh ${NODE} ". .profile; setdbConfigure"				
		printLineSuccess
	done
else	
	setdbConfigure
fi

# Reload configuration
. /home/oracle/.profile
printLineSuccess

###################################  FINISH ###################################

printLineSuccess
printLineSuccess  "-- Installation finished ! Please check logfiles under ${SCRIPTS}"
printLineSuccess

###############################################################################