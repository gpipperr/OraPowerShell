--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   OEM SQL Script Overview
-- Date:   
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
#The OEM Query Scripts
=================

OEM Repository
----------------

oem/get_target_types.sql  		- get all deployed target types in the Repository
oem/get_target_properties.sql - get the properties of a target  - Parameter 1 the Target Type 
oem/get_target_info.sql       - get the properties of a target with sample values  - Parameter 1 the Target Type     


Oracle Agent on Database side
--------------------
-- On Target DB
oem/check_agent.sql          - check the internal setting of the Oracle Agent


Oracle DB Serverside Metrics
-------------------
-- On Target DB
oem/unset_all_metric_thresholds.sql  - unset the thresholds all all values of on SID - Parameter 1  SID 
-- On OEM
oem/get_all_server_push_alerts.sql  - get all metrics that are db server defined


-------------------------------------------------------------------------------
#