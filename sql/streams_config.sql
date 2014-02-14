--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the status of streams
-- Date:   02.2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
-- 
-- http://docs.oracle.com/cd/E11882_01/server.112/e10705/man_gen_rep.htm#STREP013
--

column capture_name             heading 'capture|process|name' format a15
column rule_set_owner           heading 'positive|rule owner'  format a15
column rule_set_name            heading 'positive|rule set'    format a15
column negative_rule_set_owner  heading 'negative|rule owner'  format a15
column negative_rule_set_name   heading 'negative|rule set'    format a15
 
select capture_name
      , rule_set_owner
      , rule_set_name 
      , negative_rule_set_owner
      , negative_rule_set_name
from dba_capture
/

select * from dba_capture_parameters
/

column apply_name              heading 'apply|process|name'  format a15
column rule_set_owner          heading 'positive|rule owner' format a15
column rule_set_name           heading 'positive|rule set'   format a15
column negative_rule_set_owner heading 'negative|rule owner' format a15
column negative_rule_set_name  heading 'negative|rule set'   format a15
 
select apply_name
      , rule_set_owner
      , rule_set_name 
      , negative_rule_set_owner
      , negative_rule_set_name
 from dba_apply
 /

select * from dba_apply_parameters
/