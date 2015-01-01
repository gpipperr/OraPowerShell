
select  mg.target_type
      , decode(mg.me_type,1,'Metrik Ext','Config Ext')
      , mg.name
      , mg.latest_prod_version 
 from em_mext_groups mg
order by  mg.me_type
/

select m.name
     , m.version
     , m.target_type
     , m.display_name     
  from em_mext_versions m
 where m.version = (select max(i.version) from em_mext_versions i where i.name = m.name)
order by m.target_type
/
 
 
 