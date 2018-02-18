#!/bin/sh
# 
# create a script to relocate services
# 
# get the timing of the script
START=`date +%s%N`

#DEBUG + Timing in seconds
#export PS4='+[${SECONDS}s][${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -x;

#DEBUG + Timing in ms
#N=`date +%s%N`; export PS4='+[$(((`date +%s%N`-$N)/1000000))ms][${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -x;


########################## Helper Functions ########################################

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
printListError() {
	  printf "%s" "    "		
		
		PRINT_TEXT=${1}	
		
		printf "%s" "${PRINT_TEXT}"
		
		STRG_COUNT=${#PRINT_TEXT}	
		
		while [[  ${STRG_COUNT} -lt $2  ]]; do
		 printf "%s" " "
		 let "STRG_COUNT+=1"
	  done
		
		printf "\033[31m%s \033[0m"   "$3"
		printf "\033[31m%s \033[0m\n" "$4"	

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


# search in an array
# frist name of array
# search string
getIndex() {
   local array="$1[@]"
   local search=$2
   local count=0
   local index=-1
   for ielement in "${!array}"; do
      if [[ $ielement == $search ]]; then
         index=$count
         break
      fi
   let "count = $count + 1"	
   done
   GLOBAL_IDX=$index
}

printHelp() {
	printLine
	printLine " Usage: $( basename $0 ) -[h|a|r|f|s|t|p] [-n INSTANCE_NAME1,INSTANCE_NAME2]"
	printLine " Options:"
	printLine "     -h help usage print"
	printLine "     -a automatically relocates/stop/start the specified relocate activities"
	printLine "     -r reports needed srvctl commands for relocation (default) not auto relocates!"
	printLine "     -f free up this node, service will be distributed to the other nodes in a round-robin manner"
  	printLine "            all service will be distributed to the other nodes in the cluster - if -f option round robin re-distribution"
	printLine "     -n new <INSTANCE_NAME> to be defined as single target for service relocation in - only valid with -f"
	printLine "     -s silent - no info output - only the commands - not implemented"
	printLine "     -t timing - show the last status change of the service"
	printLine "     -p show the serve pools"	
	printLine
}


##########################################################################
# Environment
OLD_IFS=$IFS


##########################################################################
# Get Cluster Home
ORA_CRS_HOME=$( awk -F= '/crs_home/{print $2}' /etc/oracle/olr.loc )
ORA_CRS_BIN="$ORA_CRS_HOME/bin" ; 

##########################################################################
#set the db name
if [ ! -n "${DB_NAME}" ]; then
 printError "Oracle DB Name is not set! Please set environment variable DB_NAME!"
 exit 1
else 
	ORA_DB_NAME=${DB_NAME}
	# convert to lower case
	ORA_DB_RESOURCE_NAME=$(echo ${DB_NAME} | tr "[:upper:]" "[:lower:]")	
	ORA_DB_RESOURCE_NAME="ora.${ORA_DB_RESOURCE_NAME}"	
fi

##########################################################################
# Read the parameter 

typeset COMMAND_PARAM="harfstpn:"
 
# falls nicht uebergeben wurden mit exit beenden
#if ( ! getopts "${COMMAND_PARAM}" opt); then
#    echo "Usage: `basename $0` options -n <new Instance List> / use -h for help";    
#fi
 
# Read the parameter
AUTO_FIX="NO"
REPORT="YES"
MOVE_SRV="NO"
MOVE_SRV_MODE="OFF"
SILENT_MODE="NO"
TIMING_SRV="NO"
SHOW_SERVER_POOL="NO"
 
while getopts "${COMMAND_PARAM}"  opt; do
  case $opt in
	f)
		printLine "Script call with -f"
		printLine "Free a node from running services"
		MOVE_SRV="YES"
		MOVE_SRV_MODE="AUTO"
		
		;;
	s)
		printLine "Script call with -s"
		SILENT_MODE="YES"
		printLine "not yet implemented"
		exit 1
		;;
	n)
		printLine "Script call with -n"
		printLine "Use only this instances in this list $OPTARG for the movement of a service"
		MOVE_SRV_MODE="INSTANCELIST"
		MOVE_SRV="YES"
		N_PARAMETER_VALUE=$OPTARG
		;;
   r)
      printLine "Script call with -r"
		printLine "Script will show only the srvctl commands"
		REPORT="YES"
      ;;
   a)
		printLine "Script call with -a"
      printLine "Script will fix all issues and call the srvctl commands"
		AUTO_FIX="YES"
		;;
   t)
		printLine "Script call with -t"
      printLine "Script will show timing information for the last service change"
		TIMING_SRV="YES"
		;;
   p)
		printLine "Script call with -p"
      printLine "Script will show server pools"
		SHOW_SERVER_POOL="YES"
		;;
	h)
      printLine "Script call with -h"
		printHelp	
		exit 1
      ;;  
   \?)
      printLine "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
   :)
      printLine "Option -$OPTARG requires an argument."
		printHelp	
		exit 1
      ;;
	*)
      printLine "Invalid option: -$OPTARG" 
		printHelp	
      exit 1
      ;;
  esac
done

##########################################################################
# check the actual status of all Instances of the database
declare -a INST_HOST
declare -a INST_NAME

INST_STATUS=$( ${ORACLE_HOME}/bin/srvctl status database -d ${ORA_DB_NAME} )
printLine 
printLine "Status of the database" ":" "${ORA_DB_NAME}"
ELEMENT_COUNT=0
IFS=$'\n'
for INST  in ${INST_STATUS[@]}; 
do
  	printLine "$INST"
	#Instance SPGPBDW1 is running on node pblsdxw01
	INST_HOST[$ELEMENT_COUNT]=$( echo $INST | awk '{print $7}')
	INST_NAME[$ELEMENT_COUNT]=$( echo $INST | awk '{print $2}')
	let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"		
done
IFS=$OLD_IFS

printLine


##########################################################################
# create instance List if parameter f and n are set

declare -a MOVED_INST_NAMES
MY_HOSTNAME=$( echo ${HOSTNAME} | awk -F. '{ print $1 }' )
# -f
if [ "$MOVE_SRV_MODE" == "AUTO" ]; then
	printLine
	printLine " Remove the actual host ${MY_HOSTNAME} from the possible instances"
	
	MOVED_INST_NAMES=("${INST_NAME[@]}")
	
	# in this list the instance of the running host must be deleted	
   getIndex  INST_HOST ${MY_HOSTNAME}
	# remove the entry
	MOVED_INST_NAMES=(${MOVED_INST_NAMES[@]:0:$GLOBAL_IDX} ${MOVED_INST_NAMES[@]:$(($GLOBAL_IDX + 1))})			
	
	printLine "Use for the move this instances ::" ${MOVED_INST_NAMES[@]}
	printLine
	let "MOVED_POS_COUNT = ${#MOVED_INST_NAMES[@]} - 1"
fi
# -n 
if [ "$MOVE_SRV_MODE" == "INSTANCELIST" ]; then
  	printLine
	printLine "-n ${N_PARAMETER_VALUE} is called"
	ELEMENT_COUNT=0
	IFS=",;:"
	for elem in ${N_PARAMETER_VALUE};
	do
		MOVED_INST_NAMES[$ELEMENT_COUNT]=$elem
		let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"	
	done
	IFS=$OLD_IFS

	printLine "Use for the move this instances ::" ${MOVED_INST_NAMES[@]}
	printLine	
	let "MOVED_POS_COUNT = ${#MOVED_INST_NAMES[@]} - 1"
fi


##########################################################################
#get all registered services for the DB Resource

declare -a SERVICE_RESOURCES
declare -a WRONG_SRV
declare -a WRONG_SRV_INST
declare -a WRONG_SRV_NEW_INST

declare -a STOPPED_SRV
declare -a STOPPED_SRV_NEW_INST


declare -a MOVED_SRV
declare -a MOVED_SRV_INST
declare -a MOVED_SRV_NEW_INST
declare -a MOVED_SRV_MODE


#Counter for wrong services
WRONG_SRV_COUNT=0
STOP_SRV_COUNT=0
MOVED_SRV_COUNT=0
MOVED_SRV_NEXT_INSTANCE=0

##########################################################################
# get all services for this DB
SERVICE_RESOURCES=$( ${ORA_CRS_BIN}/crsctl status resource   -w "TYPE = ora.service.type" | grep NAME  | grep ${ORA_DB_RESOURCE_NAME} | awk -F= '{ print $2 }' )

#get the state of all registered services

for SRV  in ${SERVICE_RESOURCES[@]};
 do
  
	# get the Service Name 
	SERVICE_NAME=$( ${ORA_CRS_BIN}/crsctl status resource ${SRV}  -f | grep "^SERVICE_NAME=" | awk -F= '{ print $2 }' )
		
	#get the registered server Pool 
   if [ "${SHOW_SERVER_POOL}" == "YES" ]; then
	  SRV_POOL=$( ${ORA_CRS_BIN}/crsctl status resource ${SRV}  -p | grep SERVER_POOLS | awk -F= '{ print $2 }' )
	  SRV_POOL_SERVER=$(${ORA_CRS_BIN}/crsctl status serverpool ${SRV_POOL} -f | grep ACTIVE_SERVERS| awk -F= '{ print $2 }')
	fi

   RPREF_INSTANCES=$( ${ORACLE_HOME}/bin/srvctl config service -s ${SERVICE_NAME}  -d ${ORA_DB_NAME} | grep "Preferred instances" | awk '{ print $3 }'| sed -e s/","/" "/g )
	  
	printLine  "Check the Service      :" "${SERVICE_NAME}"	  # "${SRV}" " :: "
	if [ "${SHOW_SERVER_POOL}" == "YES" ]; then
      printLine "   Server Pool         :" "${SRV_POOL}"  	 
	   printLine "   Server in the Pool  :" "${SRV_POOL_SERVER}"  	 
	fi

   printLine "   Preferred Instances :" "${RPREF_INSTANCES}"  	 
	  
	#get the State of the service
	RSRV_STATES=$( ${ORA_CRS_BIN}/crsctl status resource ${SRV}  -l | grep STATE  | awk -F= '{ print $2 }'| awk '{ print $3}' )
   if [ "${TIMING_SRV}" == "YES" ]; then
	  RLAST_STATE_CHANGES=$( ${ORA_CRS_BIN}/crsctl status resource ${SRV}  -v | grep LAST_STATE_CHANGE  | awk -F= '{ print $2}' )
	fi

	# Copy to a array
	# why in this way? To stupid to find one line of code solution with bash ...
	#
	declare -a SRV_STATES
	declare -a LAST_STATE_CHANGES
	declare -a PREF_INSTANCES

	ELEMENT_COUNT=0
	for elem in ${RPREF_INSTANCES[@]};
	do
		PREF_INSTANCES[$ELEMENT_COUNT]=$elem
		let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"	
	done
	
	ELEMENT_COUNT=0
	for elem in ${RSRV_STATES[@]};
	do
		SRV_STATES[$ELEMENT_COUNT]=$elem
		let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"	
	done
        
   if [ "${TIMING_SRV}" == "YES" ]; then
	  ELEMENT_COUNT=0
	  IFS=$'\n'
	  for elem in ${RLAST_STATE_CHANGES[@]};
	  do
		LAST_STATE_CHANGES[$ELEMENT_COUNT]=$elem
		let "ELEMENT_COUNT = $ELEMENT_COUNT + 1"	
	   done
	  IFS=$OLD_IFS
   fi

	ELEMENT_COUNT=${#SRV_STATES[@]}
	INDEX=0
	GLOBAL_IDX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do
		#get the server pool
		getIndex  INST_HOST ${SRV_STATES[${INDEX}]}	
		ACT_INSTANCE=${INST_NAME[$GLOBAL_IDX]}
		printList "On-line on"   25 ":" "${SRV_STATES[${INDEX}]}  - ${ACT_INSTANCE}"
      if [ "${TIMING_SRV}" == "YES" ]; then
		   printList "Last changed/since" 25 ":" "${LAST_STATE_CHANGES[${INDEX}]}"
      fi  	 
		
		# check if running on prefered instance
		getIndex PREF_INSTANCES ${ACT_INSTANCE}
		if [ "$GLOBAL_IDX" -eq "-1" ]; then
	    	        # remember the service  and wrong instance			
			WRONG_SRV[$WRONG_SRV_COUNT]=${SERVICE_NAME}
                        WRONG_SRV_INST[$WRONG_SRV_COUNT]=${ACT_INSTANCE}         
			#
			# get the new instance
			#
			WRONG_SRV_NEW_INST[$WRONG_SRV_COUNT]=${PREF_INSTANCES[0]}
			
			#
			#printError "Running on wrong instance ${WRONG_SRV_INST[$WRONG_SRV_COUNT]}, will be moved to ${WRONG_SRV_NEW_INST[$WRONG_SRV_COUNT]}"
         printListError "Status" 25 ":" "[ WRONG ]"
			printListError "New Instance" 25 ":" "${WRONG_SRV_NEW_INST[$WRONG_SRV_COUNT]}" 			
			
			#remove from PREF_INSTANCES and reorder the arry
			PREF_INSTANCES=(${PREF_INSTANCES[@]:0:0} ${PREF_INSTANCES[@]:$((1))})		
			
			let "WRONG_SRV_COUNT = $WRONG_SRV_COUNT + 1"			
		else
 			printList "Status" 25 ":" "[  OK  ]" 
       			#printLineSuccess "OK"				
			#remove from PREF_INSTANCES and reorder the arry
			PREF_INSTANCES=(${PREF_INSTANCES[@]:0:$GLOBAL_IDX} ${PREF_INSTANCES[@]:$(($GLOBAL_IDX + 1))})		
		fi		
		################################
		# if Instance have to bee moved
		if [ "${MOVE_SRV}" == "YES" ]; then
		 	
			printLine "Check this service if we have to move it away from this host"
			
			# check if the service have to be moved to a new instance
			getIndex MOVED_INST_NAMES ${ACT_INSTANCE}
			if [ "$GLOBAL_IDX" -eq "-1" ]; then
				
				# move
				MOVED_SRV[$MOVED_SRV_COUNT]=${SERVICE_NAME}
				MOVED_SRV_INST[$MOVED_SRV_COUNT]=${ACT_INSTANCE}
				#new Instance
				MOVED_SRV_NEW_INST[$MOVED_SRV_COUNT]=${MOVED_INST_NAMES[$MOVED_SRV_NEXT_INSTANCE]}
				 			
				 
				#check if the instance runs at the moment on one of the moved instances
				#if not do a RELOCATE if not possible stop the service on this node!				 			
				# check if the service is still running on the new server!
				# if yes we need only a stop
				# check with  srvctl status service -d SPGPBDW -s S_ADRMGMT_DE_DW
				STATUS_NEW_INST=$( ${ORACLE_HOME}/bin/srvctl status service -d ${ORA_DB_NAME} -s  ${MOVED_SRV[$MOVED_SRV_COUNT]} )
				# if instr  STATUS_NEW_INST MOVED_SRV[$MOVED_SRV_COUNT] MOVED_SRV_NEW_INST[$MOVED_SRV_COUNT] must be false
				if [[ ${STATUS_NEW_INST} == *"${MOVED_SRV_NEW_INST[$MOVED_SRV_COUNT]}"* ]] ; then
					MOVED_SRV_MODE[$MOVED_SRV_COUNT]="STOPONLY"								
					printError "This service will to be stoped on ${MOVED_SRV_INST[$MOVED_SRV_COUNT]} with the mode ${MOVED_SRV_MODE[$MOVED_SRV_COUNT]}"
				else
					MOVED_SRV_MODE[$MOVED_SRV_COUNT]="RELOCATE"	
					printError "This service will to be moved to ${MOVED_SRV_NEW_INST[$MOVED_SRV_COUNT]}  with the mode ${MOVED_SRV_MODE[$MOVED_SRV_COUNT]}"
					# Round robin over the MOVED_INST_NAMES Array for the load balancing only if a new service will be started
					if [ "${MOVED_SRV_NEXT_INSTANCE}" -lt "${MOVED_POS_COUNT}" ];then
						let "MOVED_SRV_NEXT_INSTANCE = $MOVED_SRV_NEXT_INSTANCE + 1"	
					else
						MOVED_SRV_NEXT_INSTANCE=0
					fi
				fi
				
				let "MOVED_SRV_COUNT = $MOVED_SRV_COUNT + 1"
				
			else
				#printLineSuccess "Service on this Instance fine"
            printList "Status" 25 ":" "[  OK  ]"
			fi
		
		fi # end MOVE_SRV
				
		let "INDEX = $INDEX + 1"	
	done # STATE
        # the PREF_INSTANCES should be empty now if all was ok
	# if not a service was not started on a instance!
	ELEMENT_COUNT=${#PREF_INSTANCES[@]}
	INDEX=0
	GLOBAL_IDX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do 
	   printError "Service is not running on the Instance ${PREF_INSTANCES[$INDEX]}" 
		STOPPED_SRV[$STOP_SRV_COUNT]=${SERVICE_NAME}
		STOPPED_SRV_NEW_INST[$STOP_SRV_COUNT]=${PREF_INSTANCES[$INDEX]}
		
		let "STOP_SRV_COUNT = $STOP_SRV_COUNT + 1"	
		let "INDEX = $INDEX + 1"	
	done # STATE
		
	unset SRV_STATES
	unset LAST_STATE_CHANGES
	unset PREF_INSTANCES
	
	printLine 
  
done # SRV
##########################################################################
# generate fix Script for wrong services 

ELEMENT_COUNT=${#WRONG_SRV[@]}
INDEX=0
if [ "${REPORT}" == "YES" ];
	then
	printLine
	printLine "Fix Commands to transfer service to other instance"
fi	
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
do
	# Report
	if [ "${REPORT}" == "YES" ];
	then
		echo "${ORACLE_HOME}/bin/srvctl relocate service  -s  ${WRONG_SRV[$INDEX]} -d  ${ORA_DB_NAME}  -i  ${WRONG_SRV_INST[$INDEX]}  -t ${WRONG_SRV_NEW_INST[$INDEX]}"
	fi
   # Auto fix	
	if [ "${AUTO_FIX}" == "YES" ];
	then
		printLine "call Command::"
		 ${ORACLE_HOME}/bin/srvctl relocate service  -s  ${WRONG_SRV[$INDEX]} -d  ${ORA_DB_NAME}  -i  ${WRONG_SRV_INST[$INDEX]}  -t ${WRONG_SRV_NEW_INST[$INDEX]}
	fi
	let "INDEX = $INDEX + 1"			
done # fix section
if [ "${REPORT}" == "YES" ];
	then
	printLine
fi				

######################################################################
# generate start Script for missing services 

ELEMENT_COUNT=${#STOPPED_SRV[@]}
INDEX=0

if [ "${REPORT}" == "YES" ];
	then
	printLine
	printLine "Fix Commands to start service on missing instance"
fi	
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
do
	# Report
	if [ "${REPORT}" == "YES" ];
	then
		echo  "${ORACLE_HOME}/bin/srvctl start service -s  ${STOPPED_SRV[$INDEX]} -d  ${ORA_DB_NAME}   -i  ${STOPPED_SRV_NEW_INST[$INDEX]} "
	fi
	# Auto fix	
	if [ "${AUTO_FIX}" == "YES" ];
	then
		printLine "call Command::"
		${ORACLE_HOME}/bin/srvctl start service -s  ${STOPPED_SRV[$INDEX]} -d  ${ORA_DB_NAME}   -i  ${STOPPED_SRV_NEW_INST[$INDEX]}
	fi	
	let "INDEX = $INDEX + 1"			
done # fix section
if [ "${REPORT}" == "YES" ];
	then
	printLine
fi				

######################################################################
# generate start Script to move running  services to new instances

ELEMENT_COUNT=${#MOVED_SRV[@]}
INDEX=0

if [ "${REPORT}" == "YES" ];
	then
	printLine
	printLine "Fix Commands to move service on new instance to free a node"
fi	
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
do
	# Report
	if [ "${REPORT}" == "YES" ];
	then
	  if [ "${MOVED_SRV_MODE[$INDEX]}" == "RELOCATE" ]; then
			echo "${ORACLE_HOME}/bin/srvctl relocate service  -s  ${MOVED_SRV[$INDEX]} -d  ${ORA_DB_NAME}  -i  ${MOVED_SRV_INST[$INDEX]}   -t  ${MOVED_SRV_NEW_INST[$INDEX]}"	   
	  else
			echo "${ORACLE_HOME}/bin/srvctl  stop service  -s  ${MOVED_SRV[$INDEX]} -d  ${ORA_DB_NAME}  -i  ${MOVED_SRV_INST[$INDEX]}"	   
	  fi
	fi
	# Auto fix	
	if [ "${AUTO_FIX}" == "YES" ];
	then
		printLine "call Command::"
		if [ "${MOVED_SRV_MODE[$INDEX]}" == "RELOCATE" ]; then
			${ORACLE_HOME}/bin/srvctl relocate service  -s  ${MOVED_SRV[$INDEX]} -d  ${ORA_DB_NAME}   -i  ${MOVED_SRV_INST[$INDEX]} -t  ${MOVED_SRV_NEW_INST[$INDEX]}		
		else
			${ORACLE_HOME}/bin/srvctl  stop service  -s  ${MOVED_SRV[$INDEX]} -d  ${ORA_DB_NAME}    -i  ${MOVED_SRV_INST[$INDEX]}
		fi	
	fi	
	let "INDEX = $INDEX + 1"			
done # fix section
if [ "${REPORT}" == "YES" ];
	then
	printLine
fi		

###############################################################
# remember the execution time

END=`date +%s%N`
ELAPSED=`echo "scale=8; ($END - $START) / 1000000000" | bc`

printLine "Script finished after :: $ELAPSED s"

######################################################################

