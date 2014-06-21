# ==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Gunther's NoSQL script library
# Date:   07.August 2012
# Site:   http://orapowershell.codeplex.com
# ==============================================================================

######### Oracle NoSQL Helper Scripts ############

--------------  Scripts  to create a NoSQL Store -------

Scripts for the maintenance of an Oracle NoSQL 2.0 Environment

Scripts:

noSQLStore.sh => Script for maintenance
nodelist.conf => Configuration of the nodes of a store

createStore.sh => Script to create a store
deleteStore.sh => Script to delete a store
store.conf     => Main Properties of the store


Helper Scripts
bash_lib          => Bash Macros
iptables.conf     => iptables settings for testing purpose
startStopNoSQL.sh => Start/Stop script for init.d usage (need adjustments for your environment!) 

Usage:

- Edit the file nodelist.conf to your planned environment
- Edit the file store.conf    to your store creation settings
- Create the store with the script createStore.sh


----------------------------------------------------------






