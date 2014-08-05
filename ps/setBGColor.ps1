#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:  set the Color Schema of the act session
#
# Date:   29.07.2014
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#
 	.NOTES
		Created: 07.2014 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
			(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
			
			to start the script bypass the security:
			%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File d:\PowerShell\certScripts.ps1
			
	.SYNOPSIS
		Script to set the background
	.DESCRIPTION
		Script to set the background
	.COMPONENT
		Oracle Maintainance Scripts
#>

#==============================================================================
# "White",
$POS_COLORS=@("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","Yellow")
$orig_color=(get-host).UI.RawUI.BackgroundColor

$color_count=1

if ( $args[0]) { 
 #nix
}
else {
    (get-host).UI.RawUI.BackgroundColor= "White"
	foreach ( $element in ($POS_COLORS | sort -Unique) ) {
			Write-host -ForegroundColor "$element"    ( "BG Color : [{0,-11}] :: {1,2}"  -f $element,$color_count )
			$color_count+=1
	}
	(get-host).UI.RawUI.BackgroundColor=$orig_color
}

$valid_answer="false"

do {
 	# called with command parameter one
 	if ( $args[0]) {
 		 $answer =  $args[0]
 	}
 	else {	   
		$answer=Read-Host ("{0,-35}:" -f "Please enter the Number BG Color")
 		$answer=$answer.toUpper() 	
	}
 	
 	$valid_answer="false"
	
	if ($answer -imatch "^[EQ]$" ) {
		return
	}	
 	# check if the answer is in the range of the List above
 	try {
 		if ($answer -imatch "^[1234567890Q].*$" ) {
		    $valid_answer="true"
 		}			
 	}
 	catch {
 		$valid_answer="false"
 	}
 	
 	if ($valid_answer.equals("false")) {
 		Write-host -ForegroundColor "red" "Please enter a valid choice from the list above !"
 	}	
}
until ($valid_answer.equals("true"))


(get-host).UI.RawUI.BackgroundColor = $POS_COLORS[$answer-1]  

clear
