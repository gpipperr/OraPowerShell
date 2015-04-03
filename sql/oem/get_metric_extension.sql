--==============================================================================
--
--
--==============================================================================

column target_type format a10
column name format a30
column display_name format a30
column extype format a10

select  mg.target_type
      , decode(mg.me_type,1,'Metrik Ext','Config Ext') as extype
      , mg.name
      , mg.latest_prod_version 
 from em_mext_groups mg
  where mg.name='ccs_c_FB9EB8968BC969CDE043178E330A0D5A'
order by  mg.me_type
/

select m.name
     , m.version
     , m.target_type
     , m.display_name     
	  , m.DESCRIPTION
  from em_mext_versions m
 where m.version = (select max(i.version) from em_mext_versions i where i.name = m.name)
 and m.name='ccs_c_FB9EB8968BC969CDE043178E330A0D5A'
order by m.target_type
/
 
 
 