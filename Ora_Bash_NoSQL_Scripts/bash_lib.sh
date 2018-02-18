#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#

##################  GET Defaults ####################################

################### Prepare Enviroment ##############################



#####################################################################
# check Configuration
doCheck () {
	ELEMENT_COUNT=${#STORE_NODE[@]}
	INDEX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
		do    # List all the elements in the array.
		#check if host exists  
		echo -- check NoSQL Store Node ${STORE_NODE[$INDEX]}
		ping -c 1 ${STORE_NODE[$INDEX]} > /dev/null
		if [ "$?" -ne "0" ]; then 
			echo "Store node ${STORE_NODE[$INDEX]} not reachable!" 
			exit 2 
		fi
		# check for directory
		ssh  ${STORE_NODE[$INDEX]} "ls ${STORE_ROOT[$INDEX]}" > /dev/null
		if [ "$?" -ne "0" ]; then 
			echo "Store Root ${STORE_ROOT[$INDEX]} on  ${STORE_NODE[$INDEX]} not exists!" 
			exit 3
		fi
		ssh  ${STORE_NODE[$INDEX]} "ls ${STORE_HOME[$INDEX]}" > /dev/null
		if [ "$?" -ne "0" ]; then 
			echo "Store Root ${STORE_HOME[$INDEX]} on  ${STORE_NODE[$INDEX]} not exists!" 
			exit 4 
		fi
		
		let "INDEX = $INDEX + 1"
	done
}

#####################################################################
# do the work on the node
doStore () {
	# start the nodes
	ELEMENT_COUNT=${#STORE_NODE[@]}
	INDEX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
		do    # List all the elements in the array.
			echo -- ${COMMAND_TITLE} for NoSQL Store ${STORE_NAME[$INDEX]} on ${STORE_NODE[$INDEX]}  at "`date`" ------------------  
			
			KVROOTI=${STORE_ROOT[$INDEX]}
			KVHOMEI=${STORE_HOME[$INDEX]}			
			STORENAMEI=${STORE_NAME[$INDEX]}	
			
			COMMANDI=${COMMAND//#KVROOTI#/${KVROOTI}}
			COMMANDI=${COMMANDI//#KVHOMEI#/${KVHOMEI}}
			COMMANDI=${COMMANDI//#STORENAME#/${STORENAMEI}}
			
			echo -- use Command:: ${COMMANDI}
			ssh  ${COMMANDUSR}@${STORE_NODE[$INDEX]} "${COMMANDI}"
			let "INDEX = $INDEX + 1"
	done
}

#####################################################################
# wait paramter <seconds> 
waitStart() {
	printLine "Waiting ...for $1 seconds"
	INDEXCOUNTER=0;
	WAITUNTIL=$1
	while [ "$INDEXCOUNTER" -lt "$WAITUNTIL" ]; do 
		printf "*"
		sleep 1
		let "INDEXCOUNTER = $INDEXCOUNTER + 1"
	done
	printf  "%s\n" ""
}
#####################################################################
# YES NO Prompt
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
#####################################################################
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

#####################################################################
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
#####################################################################
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
#####################################################################
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