# ==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Gunther's NoSQL script library
# Date:   07.August 2012
# Site:   http://orapowershell.codeplex.com
# ==============================================================================

######### Oracle NoSQL Helper Scripts ############

--------------  Scripts  to create a NoSQL Store -------

Scripts for the maintainace of an Oracle NoSQL Enviroment

Scripts:

noSQLStore.sh => Script for maintaince
nodelist.conf => Configuration of the nodes of a store

createStore.sh => Script to create a store
deleteStore.sh => Script to delete a store
store.conf     => Main Properites of the store


Helper Scripts
bash_lib          => Bash Macros
iptables.conf     => iptables settings for testing purpose
startStopNoSQL.sh => Start/Stop script for init.d usage (need adustments for your enviroment!) 

Usage:

- Edit the file nodelist.conf to your planned enviroment
- Edit the file store.conf    to your store creation settings
- Create the store with the script createStore.sh


----------------------------------------------------------






