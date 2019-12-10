#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#

##################  GET Defaults ###################################

################### Prepare Environment ############################

# Home of the scripts
SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS=`dirname "$SCRIPTPATH{}"`
export SCRIPTS

##  read default config 
CONFFILE=${SCRIPTS}/default.conf
. ${CONFFILE}


# Host name
DBHOST_NAME=`hostname`
export DBHOST_NAME

# get SYSTEMIDENTIFIER 
SYSTEMIDENTIFIER=`ls -l /dev/disk/by-uuid/ | awk '{ print $9 }'  | tail -1`
export SYSTEMIDENTIFIER


# ASM instance ?
DB_SMON_PROCESS_ID=`ps -Af | grep asm_smon_+ASM | grep -v grep| wc -l`
if [ "${DB_SMON_PROCESS_ID}" = "1" ]; then
  ASM_ENV=true
	#
	# fix gep ASM instance from ??
	ASMORACLE_SID="+ASM"
	
	#
	#	fix grep ASM Home from ??? ######
	
	if [ -d "${S_ASM_HOME}" ]; then
		ASM_HOME=${S_ASM_HOME}
	elif [ -d "/u01/app/11.2.0/grid" ]; then
	  	ASM_HOME="/u01/app/11.2.0/grid"
	elif [ -d "/u01/app/11.2.0.3/grid" ]; then
	  	ASM_HOME="/u01/app/11.2.0.3/grid"
	elif [ -d "/u01/app/11.2.0.4/grid" ]; then
	  	ASM_HOME="/u01/app/11.2.0.4/grid"
	else
	   echo "ASM Instance found but no ASM HOME - check default.conf" 
	   exit 1
	fi
	
	if [ -d "${ASM_HOME}" ]; then
	     echo "-- Info :: ASM Instance found : use as ASM HOME - ${ASM_HOME}" 
	else
		echo "-- Error :: ASM Instance found but no ASM HOME - check default.conf" 
		exit 1
	fi
else
 	ASM_ENV=false
fi

export ASM_ENV
export ASM_HOME
export ASMORACLE_SID

# RAC ENV
# 
#
if [ -f "${ASM_HOME}/bin/cemutlo" ]; then
	CLUSTER_NAME=`${ASM_HOME}/bin/cemutlo -n`
	RAC_ENV=true
	VIPNODES=`${ASM_HOME}/bin/srvctl status nodeapps | grep 'VIP' | grep 'on node' | awk '{ print $7 }'`
else
	RAC_ENV=false
	CLUSTER_NAME=false
	VIPNODES=${DBHOST_NAME}
fi

export CLUSTER_NAME
export RAC_ENV
export VIPNODES


# ScanListenername 
# -- if rac get out the scanlistener name with oracle tools, if not take the db hostname
if [ ${RAC_ENV} = 'true' ]; then
	SCAN_LISTNER=`${ASM_HOME}/bin/srvctl config scan  | head -1 | awk  '{ print($3) }' | sed 's/,//g'`
else
 SCAN_LISTENER=${DBHOST_NAME}
fi
export SCAN_LISTENER

#Check configured Oracle Home
if [ -d "${S_ORACLE_HOME}" ]; then
	echo "-- Info :: Oracle HOME found  : use as ORACLE HOME - ${S_ORACLE_HOME}" 
else
    echo "Oracle HOME not found - check default.conf => S_ORACLE_HOME=${S_ORACLE_HOME}" 
    exit 1
fi

if [ -d "${S_ORACLE_BASE}" ]; then
	echo "-- Info :: Oracle BASE found  : use as ORACLE BASE - ${S_ORACLE_BASE}" 
else
    echo "Oracle BASE not found - check default.conf => S_ORACLE_BASE=${S_ORACLE_BASE}" 
    exit 1
fi

############  Helper functions #################################

# Common System check
# check enviroment
checkEnv () {

    # Check if user is oracle!
		id | grep oracle
		if [ "$?" = "1" ]; then
		 printError "Only the user oracle can use this scripts" 
		 printError "Actual user:"
		 id
		 exit 1
		fi
		
	  # check if SCRIPT POSITON is valid
		if [ ! -d ${SCRIPTS} ]; then
			echo "Scripts Directory ${SCRIPTS} not exist"
			echo "May be script not start in bash or over symlink?? "
			exit 1
		fi
		# check of existens and readabitlity of installation files
     
		if [ ! -f "${SCRIPTS}/CreateDB.sql" ]; then
		  echo "Scripts to install the ${SCHEMA_TO_INSTALL} User ${SCRIPTS}/${SCHEMA_TO_INSTALL}/${SCHEMA_TO_INSTALL}CreateSchema.sql not exist"
	  	echo "Do You copy the full software stack?"
			exit 1
		fi
		
		grep setdb /home/oracle/.profile > /dev/null
		if [ "$?" -ne "0" ]; then 
			echo "GPI Oracle default are not installed - setdb in .profile is missing - please read the Oracle install manual" 
		  exit 1 
		fi	
		
		#check the password lib
	   #if ! [ -x "$(pwscore oracle 1)" ]; then
	   # echo "Password Checker not installed! Use to install: yum install libpwquality" 
       # exit 1
	   #fi
}
	 
# check if you can connect as sys to the database
checkDBConnect() {

  printLine "Check for ASM"
	# ignore case for testing
	ORACLE_DBNAME_TEST=`echo ${ORACLE_SID} | tr '[A-Z]' '[a-z]'`
  # if ASM  exits with not possilbe
	if [ "${ORACLE_DBNAME_TEST:0:4}" = "+asm" ]; then
			echo "You have chossen the wrong database ASM can not contain schemas - Your SID :: ${ORACLE_SID} - Please choose the right DB!" 
			exit 1
	else
	 printLineSuccess "Sucess!"
	fi	
  printLine "Test Connect to database" "${ORACLE_SID}"
	# test connect to the DB
TEST_CONNECT=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
	set heading  off
	set pagesize 0
	set feedback off	
	select 'Sucess! DB Connection to database '||global_name||' established' from global_name;
	exit;
EOScipt`
		
	if [ "$?" -ne "0" ]; then 
			echo "Can not connect to the Oracle database with the given SID ${ORACLE_SID} - Fix the DB connection first" 
		  exit 1
	else
	 printLineSuccess ${TEST_CONNECT}
	fi
ORACLE_DBNAME=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
				set heading off
				set pagesize 0
				set feedback off	
				select global_name from global_name;
				exit;
EOScipt`

		ORACLE_DBNAME="${ORACLE_DBNAME#"${ORACLE_DBNAME%%[![:space:]]*}"}"   
		ORACLE_DBNAME="${ORACLE_DBNAME%"${ORACLE_DBNAME##*[![:space:]]}"}"   
	
  	printLine "Verify database valid for schema" "${SCHEMA_TO_INSTALL}" "${ORACLE_DBNAME}"
		# ignore case for testing
		ORACLE_DBNAME_TEST=`echo ${ORACLE_DBNAME} | tr '[A-Z]' '[a-z]'`
		SCHEMA_TEST=`echo ${SCHEMA_TO_INSTALL} | tr '[A-Z]' '[a-z]'`
	
		# if name of DB is not like the schema name like the default ask the installer => realy install here?
		if [ "${ORACLE_DBNAME_TEST:0:2}" != "${SCHEMA_TEST:0:2}"  ]; then
			echo  "You are shure that you want chose the db ${ORACLE_DBNAME} for the installation ?"
			read ANSWER
			if [ ${ANSWER} != 'yes']; then
			 echo  "You answer ${ANSWER} was not yes - exiting installation"
			 exit 1
			fi
		else
		printLineSuccess "Sucess!"
		fi
		printLine "Verify that auditlog tablespace is installed" "on" "${ORACLE_DBNAME}"
		#check if Auditlog Tablespace was created if not exit	 
ORACLE_AUDITLOG=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
				set heading off
				set pagesize 0
				set feedback off	
				select count(*) from dba_tablespaces where tablespace_name like 'AUDIT%';
				exit;
EOScipt`
		ORACLE_AUDITLOG="${ORACLE_AUDITLOG#"${ORACLE_AUDITLOG%%[![:space:]]*}"}"   
		ORACLE_AUDITLOG="${ORACLE_AUDITLOG%"${ORACLE_AUDITLOG##*[![:space:]]}"}"
		if [ "${ORACLE_AUDITLOG}" = "0" ]; then
			echo "You not not have finished the DB installation - the AUDITLOG tablespace is missing - consult the installation guide!" 
			exit 1
		else
		printLineSuccess "Sucess!"
		fi

		# get DB Version
		versiontab=\$version
DB_VERSION=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
	set heading  off
	set pagesize 0
	set feedback off	
  select banner from  sys.v_$versiontab where banner like '%atabase%' and rownum=1;
	exit
EOScipt`	
export DB_VERSION

# Enterprise Edition?
DB_EDITON=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
	set heading  off
	set pagesize 0
	set feedback off	
	select decode( trim(lower(product)),'oracle database 11g enterprise edition','EE','SE') from product_component_version where product like '%atabase%' and rownum=1;
	exit
EOScipt`	
export DB_EDITON

		
}
	
#  -- check if the chosen location exits, if a file url is choosen and ASM is present ask again
checkLocations(){
 printLine "check the database location " "${1}"
 if [ ${ASM_ENV} = 'false' ]; then	
    printLine "check directory" "${1}"
		if [ ! -d ${1} ]; then
				printError
				printError "Data Directory" "${1}" "not exist"
				printError "Exit installation - please check location carefully before start of installation"
				printError
				exit 1
		else
			printLineSuccess "Sucess!"
		fi		
	else
	  asmtab=\$asm_diskgroup
		printLine "check ${1} on ASM database"
		CHECK_DISK_GROUP=`echo "set heading off	
    set pagesize 0
		set feedback off		
		select count(*) from sys.v$asmtab where name=replace(upper('${1}'),'+','');
		exit;" | ${ORACLE_HOME}/bin/sqlplus -s / as sysasm`
		
		 
  	CHECK_DISK_GROUP="${CHECK_DISK_GROUP#"${CHECK_DISK_GROUP%%[![:space:]]*}"}"   
		CHECK_DISK_GROUP="${CHECK_DISK_GROUP%"${CHECK_DISK_GROUP##*[![:space:]]}"}" 
		if [ "${CHECK_DISK_GROUP}" = "0" ]; then
				printError
				printError "The ASM Diskgroup" "${1}" "is missing - please check location carefully before start of installation"
				printError
				exit 1
		else
		 
		  	printLineSuccess "Sucess!"
				
		
		   CHECK_DISK_GROUP=`echo "set heading off	
				set pagesize 0
				set feedback off		
				select to_char(round(TOTAL_MB/1024,2))||' MB - '|| to_char(round(FREE_MB/1024,2)) || ' MB free '|| to_char(FREE_MB) ||' MB will be used' from sys.v$asmtab where name=replace(upper('${1}'),'+','');
				exit;" | ${ORACLE_HOME}/bin/sqlplus -s / as sysasm`
		   
			  printLine " Size on this location::   ${CHECK_DISK_GROUP}"					  
				
				DISK_GROUP_SIZE=${CHECK_DISK_GROUP}		
		fi		 
	fi		 
}

# check the password of a user
checkUserDBPassword(){
  	
	TEST_USER=${1}
	TEST_PASSWD=${2}
	
	if [ ${TEST_USER} = 'SYS' ]; then
	 TEST_USER="${1}/${2} as sysdba"
	else
	 TEST_USER="${1}/${2}"
	fi
	
	printLine "Test Connect to database" "${ORACLE_SID}" "for the user" ${TEST_USER}

	TEST_CONNECT="SUCESS"
	
#test connect to the DB
TEST_CONNECT=`${ORACLE_HOME}/bin/sqlplus -s ${TEST_USER} << EOScipt
	set heading  off
	set pagesize 0
	set feedback off	
	select 'Sucess! DB Connection to database '||global_name||' established for user ${1}' from global_name;
	exit
EOScipt`
	
  if [ "$?" -ne "0" ]; then 
		printError "Can not connect to the Oracle database with the given user ${1} and your password ${TEST_PASSWD}" 		
		printError "${TEST_CONNECT:0:40}...."
		CAN_CONNECT=false			
	else
	  printLineSuccess ${TEST_CONNECT}
		CAN_CONNECT=true
	fi
  
}

checkASMUserDBPassword(){
  	
	TEST_USER=${1}
	TEST_PASSWD=${2}
	
	if [ "${TEST_USER}" = 'SYS' ]; then
	 TEST_USER="${1}/${2} as SYSASM"
	else
	 TEST_USER="${1}/${2}"
	fi
	
	ORACLE_SAV_SID=${ORACLE_SID}
	
	printLine "Test Connect to ASM database" "${ASMORACLE_SID}" "for the user" ${TEST_USER}
  
	TEST_CONNECT="SUCESS"
	
	#test connect to the DB
	asmtab=\$instance
	
	#printLine "DEBUG :: ${ASM_HOME}/bin/sqlplus -s ${TEST_USER}"
	
TEST_CONNECT=`
    ${ASM_HOME}/bin/sqlplus -s ${TEST_USER} << EOScipt
		set heading  off
		set pagesize 0
		set feedback off	
		select 'Sucess! DB Connection to database '||INSTANCE_NAME||' established for user ${1}' from v$asmtab;
		exit	
EOScipt`


	
  if [ "$?" -ne "0" ]; then 
		printError "Can not connect to the Oracle database with the given user ${1} and your password ${TEST_PASSWD}" 		
		printError "${TEST_CONNECT:0:40}...."
		CAN_CONNECT=false			
	else
	  printLineSuccess ${TEST_CONNECT}
		CAN_CONNECT=true
	fi
  
}


###################################
# "USER Tablespace" "${S_FILE_DATA_LOCATION}" "${S_USER_TAB_LOC}" "${S_ASM_DATA_LOCATION}"
askDatafileLocation () {
	
	A_PROMPT=$1
  A_PATH=$2
	A_FILENNAME=$3
	A_ASM_LOC=$4
	
	printLine  "Set the ${A_PROMPT} location" 
	
	printf " +please enter the location for the %s of the Database\n" "${A_PROMPT}"
	
	if [ "${ASM_ENV}" = 'false' ]; then	
	 if [[ "${A_PROMPT}" = "Flash Recovery" || "${A_PROMPT}" = "Redo Log Destination 1" || "${A_PROMPT}" = "Redo Log Destination 2" ]]; then
	 		printf "   [%s]:" "${A_PATH}/${A_FILENNAME}"		
	 else
	 		printf "   [%s]:" "${A_PATH}/${ORACLE_DBNAME}/${A_FILENNAME}"
	 fi
	else
		printf "   [%s]:" "${A_ASM_LOC}"
	fi
	
	read ANSWER_DAT_LOCATION
	
	if [ ! -n "${ANSWER_DAT_LOCATION}" ]; then
		if [ "${ASM_ENV}" = 'false' ]; then	
			if [[ "${A_PROMPT}" = "Flash Recovery" || "${A_PROMPT}" = "Redo Log Destination 1" || "${A_PROMPT}" = "Redo Log Destination 2" ]]; then
				ANSWER_DAT_LOCATION=${A_PATH}/${A_FILENNAME}
			else
				ANSWER_DAT_LOCATION=${A_PATH}/${ORACLE_DBNAME}/${A_FILENNAME}
			fi			
		else
		  ANSWER_DAT_LOCATION=${A_ASM_LOC}
		fi	
	fi	
	if [ "${ASM_ENV}" = 'true' ]; then	
	  
	  #check on leading + if missing add the +
		if [[ "${ANSWER_DAT_LOCATION}" = *+* ]];
		then
			ANSWER_DAT_LOCATION=${ANSWER_DAT_LOCATION}
		else
			ANSWER_DAT_LOCATION=+${ANSWER_DAT_LOCATION}
		fi
		checkLocations ${ANSWER_DAT_LOCATION}  
	 else
		# FIX? ----------- FIX -------------
		#checkLocations ${A_PATH}  
		if [ -d "${A_PATH}/${ORACLE_DBNAME}" ]; then		
			printLine "${ANSWER_DAT_LOCATION} exists"
		else
      printLine "Location ${ANSWER_DAT_LOCATION} not exists, will be generated"		
		fi		
	fi
	
}

################################################################################
# User defaultpassword alternativPasswort
askPassword() {
  
	USER_CHECK=$1
	USER_NAME=$2
	USER_DEFAULT_PWD=$3
	USER_ALTERNATIV_PWD=$4
	USER_PROMPT=$5
	
	#why not a big rex ? I'm to stupid ....
	#min 8 signs
	LENGTH_PW_REGEX="(^.{8,255}$)"
	PWD_LENGTH=false
	# min a number
	NUMBER_PW_REGEX="(.*[0-9])"
	PWD_NUMBER=false
	# min a spezial char
	SPEZIAL_PW_REGEX="(.*\W)"
	PWD_SPEZIAL=false
	
	
	if [ ! -n "${USER_DEFAULT_PWD}" ]; then
	 USER_DEFAULT_PWD=$USER_ALTERNATIV_PWD
	fi
	
	LIMIT=10             
	ANSWER_COUNTER=1
	
	printError "Use a strong Password, at least 8 char , at least one digit , at least 1 special char"
	
	while [ "$ANSWER_COUNTER" -le $LIMIT ]
	do
		printf "User ${USER_PROMPT}: ${USER_NAME}   [%s]:" "${USER_DEFAULT_PWD}" 
		read USER_PWD_ANSWER
		if [ ! -n "${USER_PWD_ANSWER}" ]; then
			USER_PWD_ANSWER=${USER_DEFAULT_PWD}
		fi
		if [ ! -n "${USER_PWD_ANSWER}" ]; then
			printError "Please enter a password for ${USER_NAME}!"
		else
		    # if new password (no CHECK Or ASMCHECK PWD)
			if [ "${USER_CHECK}" != 'CHECK' ] && [ "${USER_CHECK}" != 'ASMCHECK' ] ; then
			  
				if [[ "${USER_PWD_ANSWER}" =~ ${LENGTH_PW_REGEX} ]]; then
					printf "Password Length > 8           - check OK\n"
					PWD_LENGTH=true
				else
					printf "Use a strong Password, at least 8 char Password to short\n"
				fi

				if [[ "${USER_PWD_ANSWER}" =~ ${NUMBER_PW_REGEX} ]]; then
					printf "Password contains number       - check OK\n"
					PWD_NUMBER=true
				else
					printf "Use a strong Password, at least 1 number!\n"
				fi

				if [[ "${USER_PWD_ANSWER}" =~ ${SPEZIAL_PW_REGEX} ]]; then
					printf "Password contains special Char  - check OK\n"
					PWD_SPEZIAL=true
				else
					printf "Use a strong Password, at least one special char < ASCII 127!\n"
				fi


				if [ "${PWD_LENGTH}" = "true" ] && [ "${PWD_NUMBER}" = "true" ] && [ "${PWD_SPEZIAL}" = "true" ]; then
					printf "Password is ok and can be used!\n"
					break
				else
					printf "Use a strong Password, this password not fit!\n"
				fi 		
			fi
			if [ "${USER_CHECK}" = 'CHECK' ]; then
				checkUserDBPassword "${USER_NAME}" "${USER_PWD_ANSWER}"
				if [ "${CAN_CONNECT}" = "true" ]; then
					break
				fi
			else
			  if [ "${USER_CHECK}" = 'ASMCHECK' ]; then
				 checkASMUserDBPassword "${USER_NAME}" "${USER_PWD_ANSWER}"
					if [ "${CAN_CONNECT}" = "true" ]; then
						break
					fi
			  fi 
           fi			
		fi	
		echo -n "$ANSWER_COUNTER "
		let "ANSWER_COUNTER+=1"
	done  
	
	if [ ! -n "${USER_PWD_ANSWER}" ]; then
		printError "Without a password for ${USER_NAME} for you can not install the schema!"
		exit 1
	fi
	
}

################################################################################
# User defaultpassword alternativPasswort
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
		printError "Without a answer  for this question ${USER_QUESTION} for you can not install the schema!"
		exit 1
	fi	
}

# get the -a Parameter with all storage locations without a +, sorted unique
getCommaList () {
 COMMA_LIST=`echo $*|tr " " "\n"|sort|uniq|awk '{ gsub(/+/, "") ; print }'|tr "\n" ","|sed 's/\(.*\),/\1/'`
}

###########################################################################
# Password file handling
encryptPWDFile () {
	if [ -f "/usr/bin/openssl" ]; then
		openssl des3 -salt -in  ${PWDFILE} -out ${PWDFILE}.des3 -pass pass:"${SYSTEMIDENTIFIER}" > /dev/null
		#debug printf "%s encrypt file :: \n%s to \n%s.des3 \n" "--" "${PWDFILE}" "${PWDFILE}" 
		rm ${PWDFILE} 
	else
		printError "Openssl not exits - password file will be not encrypted"
 fi
}
	
dencryptPWDFile() {
 if [ -f "/usr/bin/openssl" ]; then
	openssl des3 -d -salt -in ${PWDFILE}.des3 -out ${PWDFILE} -pass pass:"${SYSTEMIDENTIFIER}" > /dev/null
  #debug printf "%s decrypt file :: \n%s.des3 to \n%s \n" "--" "${PWDFILE}" "${PWDFILE}" 
 else
  printError "Openssl not exits - password file will be not dencrypted"
 fi  
}

#normal
printLine() {
	if [ ! -n "$1" ]; then
		printf "\033[35m%s\033[0m\n" "----------------------------------------------------------------------------"
	else
		printf "%s" "-- "		
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
		printf "\033[31m%s\033[0m\n" "----------------------------------------------------------------------------"
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
		printf "\033[32m%s\033[0m\n" "----------------------------------------------------------------------------"
	else
		printf "\033[32m%s\033[0m" "!! "		
		while [ "$1" != "" ]; do
			printf "\033[32m%s \033[0m" $1 
			shift
		done
		printf  "%s\n" ""
	fi	
}

# Trim a string
trimString() {
	TRIMSTRING=${1}
	TRIMSTRING="${TRIMSTRING#"${TRIMSTRING%%[![:space:]]*}"}"   
	TRIMSTRING="${TRIMSTRING%"${TRIMSTRING##*[![:space:]]}"}"   
	echo ${TRIMSTRING}
}
##############################  Error Handler ############################

#exception_handler(){
#
# echo "---------- `date` --- Error -----------------------"
#}
#trap 'exception_handler' ERR
#set -e
#EXCEPTION_RAISED=false


############################ information helpers for bash programming ####

#!/bin/sh
############################################################
# Print the ASCII Color Table
############################################################
# originally by AntiGenX
# from: http://forums.macosxhints.com/showthread.php?t=17068
#
# edits and cleanup by catfish
#

getAsciTable() {
	for i in 0 1 4 5 7; do
		case $i in
			0) MODE="Normal";;
			1) MODE="Bold";;
			4) MODE="Underline";;
			5) MODE="Blink";;
			7) MODE="Inverse";;
			*) MODE="undefined";;
		esac
		echo
		echo "----------------------------------------------------------------"
		printf " Mode: %-12s Code: ESC[%s;Foreground;Background\n" ${MODE} $i
		echo "----------------------------------------------------------------"
		for fore in 30 31 32 33 34 35 36 37; do
			for back in 40 41 42 43 44 45 46 47; do
				printf '\033[%s;%s;%sm %02s;%02s ' $i $fore $back $fore $back
			done
			printf '\033[0m'
			echo
		done
	done
	echo
}






