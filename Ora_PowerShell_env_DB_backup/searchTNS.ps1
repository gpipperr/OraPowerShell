write-host -ForegroundColor "green" "Search tnsname $env:TNS_ADMIN\tnsnames.ora for : $args"
Select-String $env:TNS_ADMIN\tnsnames.ora -pattern "^\w+$args\w+[=]"

#"\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6}"



