--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:  get the ACL List of the database
-- Date:   02.2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
--http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_networkacl_adm.htm#CHDJFJFF
--http://www.oracle.com/webfolder/technetwork/de/community/dbadmin/tipps/acl/index.html
--http://www.oracleflash.com/36/Oracle-11g-Access-Control-List-for-External-Network-Services.html

column acl       format a40 heading "ACL"
column host      format a16 
column principal format a16
column privilege format a10
column is_grant  format a8
column lower_port format a12 heading "Lower Port"
column upper_port format a12 heading "Upper Port"

set lines 1000

select acl 
    , host 
	 , to_char(lower_port) lower_port
	 , to_char(upper_port) upper_port
 from DBA_NETWORK_ACLS
/

select acl 
    , principal 
	 , privilege 
	 , is_grant 
from DBA_NETWORK_ACL_PRIVILEGES
/

