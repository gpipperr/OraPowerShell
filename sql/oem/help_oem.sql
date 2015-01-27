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

oem/get_target.sql               - get infos for a target

oem/get_target_types.sql  		   - get all deployed target types in the Repository
oem/get_target_properties.sql    - get the properties of a target  - Parameter 1 the Target Type 
oem/get_target_info.sql          - get the properties of a target with sample values  - Parameter 1 the Target Type     

oem/get_host_targets.sql         - get all Targets on one host
oem/get_upload_status_target.sql - get the upload status of all targets on a host

oem/get_target_oracle_home.sql   - get the targets to a oracle home target name - Parameter 1 - part of the Oracle Home Target Name


oem/get_metric_extension.sql         - get all user defined metric extentsion

oem/get_all_server_push_alerts.sql   - get all metrics that are db server defined

oem/get_open_incidents.sql           - get all open incidents

Oracle Agent on Database side
--------------------

oem/check_agent.sql                     - check the internal setting of the Oracle Agent
oem/check_missing_alert_log_rights.sql  - check Report to get all DB Instances with missing alert.log
oem/check_oracle_home_integrity.sql     - check if the oracle home settings on a snapshot of the target properties are the same as on the target atself 

-------------------------------------------------------------------------------
#