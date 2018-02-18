**Attention! Watch the project structure**

* Folder ps     => MS Windows PowerSchell scripts
* Folder bash  => Linux bash script
* Folder sql     => Generic SQL scripts for SQL*Plus - copy the Content to the ps or bash "sql“ folder


# **Setup the PowerShell script part:**

# Copy the whole content of the script subfolder „ps" to a folder like d:\scripts\ 
# Read the documentation under the doc folder (see [01-OraPowerShell-Setup.docx](Documentation_01-OraPowerShell-Setup.docx) )
# copy the template XML's to a new file with a name ( without "template"
## like {backup_config_template.xml} to {backup_config.xml}
# Edit the xml files under the conf folder 
## see [Overview of the configuration file backup_config.xml](Overview-of-the-configuration-file-backup_config.xml)
## see [Overview of the configuration file backup_file_config.xml](Overview-of-the-configuration-file-backup_file_config.xml)
## see [Overview of the configuration file mail_config.xml](Overview-of-the-configuration-file-mail_config.xml)
# Edit the $Profile of your PowerShell environment to load the modules 
# Register the Event Source in a administrative session (lib/registerEventSource.ps1) 
# Test the first backup and check the logs under the log folder 
# Alternative: Sign the code with the certScripts.ps1 helper Script
## see [Code signing](Code-signing)
# Create the task to run the backup automatically 
# Check the log files that everything is correct

**Update**

**If code signing is in use:** 
Please set security to remote signed, you have to resign your scripts and reset the security!

To update an existing installation, please replace all scripts with the new version.


# Copy the whole content of the script folder structure to your folder like d:\scripts\ 
## No xml Configuration will be overwritten
# Compare your xml configuration with the template xml's
## Check the version attribute in the first xml node of each xml file!
# Check the log files that everything is correct
