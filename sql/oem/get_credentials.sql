
column target_type format a20
column user_name     format a20
column credential_set_name format a20


SELECT t.target_name
     , tc.user_name
	  , tc.credential_set_name
 FROM SYSMAN.MGMT_TARGET_CREDENTIALS tc
    , SYSMAN.MGMT_TARGETS t
WHERE tc.target_guid=t.target_guid
  --and tc.user_name = 'SYSMAN'
order by 1,2  
/

column target_type format a20
column set_name     format a20
column cred_type_name format a20
column cred_type_target_type format a20
		

SELECT  cst.target_type   
      , cst.set_name      
      , cst.cred_type_name
      , cst.cred_type_target_type
		, cs.target_type_meta_ver
 FROM  em_credential_set_types cst,
       mgmt_credential_sets cs
 WHERE cst.target_type             = cs.target_type
         AND cst.set_name            = cs.set_name
         AND cs.target_type_meta_ver =
         (
                 SELECT  MAX_TYPE_META_VER
                 FROM    mgmt_target_types tt
                 WHERE   cs.target_type = tt.target_type
         )
and cs.target_type='oracle_database'
/

select t.target_name
     , tc.user_name
     , tc.set_name
     , nc.cred_name 
  from  em_target_creds tc
      , MGMT_TARGETS    t
      , EM_NC_CREDS     nc
 where tc.target_guid = t.target_guid
   and t.target_type = 'host'
   and nc.cred_guid=tc.cred_guid
   and tc.user_name='<SYSTEM>'
   and tc.set_name='HostCredsPriv'
/	
			
select * from em_credential_set_types where target_type='oracle_database'
/
			
