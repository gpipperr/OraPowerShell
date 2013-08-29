---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
------- Name        :  used_options_details.sql
------- Usage       :  sqlplus -s <UserName/Password> @used_options_details.sql
-------                           > <output file>
------- Description :  This script provides detailed report of features used by each  
-------                Database Options/Management Packs for Oracle Database 
-------                11g Release 2 only. You need DBA role to execute the 
-------                script.The report is based on DBA_FEATURE_USAGE_STATISTICS view.  
-------                Note that the feature usage data in the view is updated once 
-------                a week, so it may take up to 7 days for the report to show 
-------                recent usage of options and/or packs.
-------                The "Currently Used" column is derived from currently_used column 
-------                of DBA_FEATURE_USAGE_STATISTICS View. It denotes if the feature in
-------                question was used during the last sampling interval by version.
-------  
------- Disclaimer  :  The following report will provide you an overview of the
-------                licensable Database Options and Enterprise Management
-------                Packs that were identified as used by your organization.
-------                This is to be used for informational purposes only and
-------                this does not represent your license entitlement or
-------                requirement. If any discrepancy is noticed in the 
-------                Options usage reporting please contact 
-------                License Management Services (LMS) representative at 
-------                http://www.oracle.com/us/corporate/license-management-services/index.html
-------
-------                The Options Usage data in  some cases return false
-------                positives, please see MOS DOC ID 1309070.1 for more
-------                information. This is may be due to inclusion of usage
-------                by sample schemas (such as HR, PM, SH...) or system/
-------                /internal usage. If you find a discrepancy in the
-------                report, use the supplied < used_options_details.sql > to narrow 
-------                down the cause of incorrect reporting. Please report it to 
-------                Oracle Support and contact LMS representative.
-------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

SET LINESIZE 350;
SET PAGESIZE 1000;
SET FEEDBACK OFF;
SET COLSEP '|';



COL "Option/Management Pack" FORMAT A60;
COL "Used" FORMAT A5;
COL "Feature being Used" FORMAT A50;
COL "Currently Used" FORMAT A14;
COL "Last Usage Date" FORMAT A18;
COL "Last Sample Date" FORMAT A18;
COL "Host Name" FORMAT A30;


with features as(
select a OPTIONS, b NAME  from
(
select 'Active Data Guard' a,  'Active Data Guard - Real-Time Query on Physical Standby' b from dual
union all 
select 'Advanced Compression', 'HeapCompression' from dual
union all
select 'Advanced Compression', 'Backup BZIP2 Compression' from dual
union all 
select 'Advanced Compression', 'Backup DEFAULT Compression' from dual
union all 
select 'Advanced Compression', 'Backup HIGH Compression' from dual
union all
select 'Advanced Compression', 'Backup LOW Compression' from dual
union all
select 'Advanced Compression', 'Backup MEDIUM Compression' from dual
union all
select 'Advanced Compression', 'Backup ZLIB, Compression' from dual
union all 
select 'Advanced Compression', 'SecureFile Compression (user)' from dual
union all
select 'Advanced Compression', 'SecureFile Deduplication (user)' from dual
union all
select 'Advanced Compression',        'Data Guard' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Export)' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Import)' from dual
union all
select 'Advanced Security',	'ASO native encryption and checksumming' from dual
union all
select 'Advanced Security', 'Transparent Data Encryption' from dual
union all
select 'Advanced Security', 'Encrypted Tablespaces' from dual
union all
select 'Advanced Security', 'Backup Encryption' from dual
union all
select 'Advanced Security', 'SecureFile Encryption (user)' from dual
union all
select 'Change Management Pack (GC)',	'Change Management Pack (GC)' from dual
union all
select 'Data Masking Pack',	'Data Masking Pack (GC)' from dual
union all
select 'Data Mining',	'Data Mining' from dual
union all
select 'Diagnostic Pack',  	'Diagnostic Pack' from dual
union all
select 'Diagnostic Pack',  	'ADDM' from dual
union all
select 'Diagnostic Pack',  	'AWR Baseline' from dual
union all
select 'Diagnostic Pack',  	'AWR Baseline Template' from dual
union all
select 'Diagnostic Pack',  	'AWR Report' from dual
union all
select 'Diagnostic Pack',  	'Baseline Adaptive Thresholds' from dual
union all
select 'Diagnostic Pack',  	'Baseline Static Computations' from dual
union all
select 'Tuning Pack',  	'Tuning Pack' from dual
union all
select 'Tuning Pack',  	'Real-Time SQL Monitoring' from dual
union all
select 'Tuning Pack',  	'SQL Tuning Advisor' from dual
union all
select 'Tuning Pack',  	'SQL Access Advisor' from dual
union all
select 'Tuning Pack',  	'SQL Profile' from dual
union all
select 'Tuning Pack',  	'Automatic SQL Tuning Advisor' from dual
union all
select 'Database Vault',  	'Oracle Database Vault' from dual
union all
select 'WebLogic Server Management Pack Enterprise Edition',  	'EM AS Provisioning and Patch Automation (GC)' from dual
union all
select 'Configuration Management Pack for Oracle Database',  	'EM Config Management Pack (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack for Database',  	'EM Database Provisioning and Patch Automation (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack',  	'EM Standalone Provisioning and Patch Automation Pack (GC)' from dual
union all
select 'Exadata',  	'Exadata' from dual
union all
select 'Label Security',  	'Label Security' from dual
union all
select 'OLAP',  	'OLAP - Analytic Workspaces' from dual
union all
select 'Partitioning',  	'Partitioning (user)' from dual
union all
select 'Real Application Clusters',  	'Real Application Clusters (RAC)' from dual
union all
select 'Real Application Testing',  	'Database Replay: Workload Capture' from dual
union all
select 'Real Application Testing',  	'Database Replay: Workload Replay' from dual
union all
select 'Real Application Testing',  	'SQL Performance Analyzer' from dual
union all
select 'Spatial'	,'Spatial (Not used because this does not differential usage of spatial over locator, which is free)' from dual
union all
select 'Total Recall',	'Flashback Data Archive' from dual
)
)
select 
   t.o "Option/Management Pack",
   t.u "Used",
   t.n "Feature being Used",
   t.v "Version",
   t.cu "Currently Used",
   t.du "Detected Usage",
   t.lud "Last Usage Date",
   t.ts "Total Samples",
   t.lsd "Last Sample Date",
   d.DBID "DBID",
   d.name "DB Name",
   i.version "Curr DB Version",
   i.host_name "Host Name",
   to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') "ReportGen Time"
from (
select f.OPTIONS o,  
       'YES' u,
       f_stat.version v,
       case when f_stat.name in ('Oracle Utility Datapump (Export)', 'Oracle Utility Datapump (Import)') then 'Data Pump Compression'
            when f_stat.name in ('Data Guard') then 'Data Guard Network Compression'
            else f_stat.name 
       end n,
       f_stat.CURRENTLY_USED cu,
       (f_stat.DETECTED_USAGES) du,
       to_char(f_stat.LAST_USAGE_DATE, 'DD-MON-YY HH24:MI:SS') lud,
       (f_stat.TOTAL_SAMPLES) ts,
       to_char(f_stat.LAST_SAMPLE_DATE, 'DD-MON-YY HH24:MI:SS') lsd
from features f,
     sys.dba_feature_usage_statistics f_stat
where f.name = f_stat.name and
      ( (f_stat.currently_used = 'TRUE' and
         f_stat.detected_usages > 0 and
         (sysdate - f_stat.last_usage_date) < 366 and
         f_stat.total_samples > 0
        )
        or 
        (f_stat.detected_usages > 0 and
        (sysdate - f_stat.last_usage_date) < 366 and 
        f_stat.total_samples > 0)
      ) and
      ( f_stat.name not in('Data Guard', 'Oracle Utility Datapump (Export)', 'Oracle Utility Datapump (Import)')
        or
        (f_stat.name in('Data Guard', 'Oracle Utility Datapump (Export)', 'Oracle Utility Datapump (Import)') and
         f_stat.feature_info is not null and trim(substr(to_char(feature_info), instr(to_char(feature_info), 'compression used: ',1,1) + 18, 2)) != '0')
      )
) t,
v$instance i,
v$database d  
order by t.o,t.n,t.v
/

