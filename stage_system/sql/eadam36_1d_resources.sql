DEF section_name = 'Resources';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF title = 'CPU Demand (MEM)';
DEF main_table = 'GV_ACTIVE_SESSION_HISTORY_S';
DEF abstract = 'Number of Sessions demanding CPU. Includes Peak (max), percentiles and average.'
DEF foot = 'Consider Peak for sizing.'

COL db_name FOR A9;
COL host_name FOR A64;
COL instance_name FOR A16;
COL db_unique_name FOR A30;
COL platform_name FOR A101;
COL version FOR A17;

COL aas_cpu_peak       FOR 999999999999990.0 HEA "CPU Demand Peak";
COL aas_cpu_99_99_perc FOR 999999999999990.0 HEA "CPU Demand 99.99% Percentile";
COL aas_cpu_99_9_perc  FOR 999999999999990.0 HEA "CPU Demand 99.9% Percentile";
COL aas_cpu_99_perc    FOR 999999999999990.0 HEA "CPU Demand 99% Percentile";
COL aas_cpu_95_perc    FOR 999999999999990.0 HEA "CPU Demand 95% Percentile";
COL aas_cpu_90_perc    FOR 999999999999990.0 HEA "CPU Demand 90% Percentile";
COL aas_cpu_75_perc    FOR 999999999999990.0 HEA "CPU Demand 75% Percentile";
COL aas_cpu_50_perc    FOR 999999999999990.0 HEA "CPU Demand 50% Percentile";

BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
, aas_cpu_99_99_perc
, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
FROM cpu_time
WHERE eadam_seq_id = &&eadam_seq_id.
AND cpu_time_type = ''DEM''
AND cpu_time_source = ''MEM''
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF title = 'CPU Demand (AWR)';
DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF abstract = 'Number of Sessions demanding CPU. Includes Peak (max), percentiles and average.'
DEF foot = 'Consider Peak or high Percentile for sizing.'
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
, aas_cpu_99_99_perc
, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
FROM cpu_time
WHERE eadam_seq_id = &&eadam_seq_id.
AND cpu_time_type = ''DEM''
AND cpu_time_source = ''AWR''
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'Sessions "ON CPU" or waiting for "resmgr:cpu quantum"';
DEF tit_01 = 'CPU demand';
DEF tit_02 = 'ON CPU';
DEF tit_03 = 'resmgr:cpu quantum';
DEF tit_04 = '';
DEF tit_05 = '';
DEF tit_06 = '';
DEF tit_07 = '';
DEF tit_08 = '';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       cpu_demand,
       on_cpu,
       waiting_for_cpu,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM cpu_demand_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time,
       end_time
';
END;
/

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'CPU Demand Series (Peak) for Cluster';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&avg_cpu_count.,';

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 1';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 2';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 3';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 4';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 5';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 6';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 7';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 8';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 
DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'Sessions "ON CPU" or waiting for "resmgr:cpu quantum"';
DEF tit_01 = 'Maximum (peak)';
DEF tit_02 = 'Average';
DEF tit_03 = 'Median';
DEF tit_04 = 'Minimum';
DEF tit_05 = '99% Percentile';
DEF tit_06 = '95% Percentile';
DEF tit_07 = '90% Percentile';
DEF tit_08 = '75% Percentile';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       cpu_demand_max,
       cpu_demand_avg,
       cpu_demand_med,
       cpu_demand_min,
       cpu_demand_99p,
       cpu_demand_95p,
       cpu_demand_90p,
       cpu_demand_75p,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM cpu_demand_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time,
       end_time
';
END;
/

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'CPU Demand Series (Percentile) for Cluster';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&avg_cpu_count.,';

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 1';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 2';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 3';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 4';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 5';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 6';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 7';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 8';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 
DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

COL aas_cpu_peak       FOR 999999999999990.0 HEA "AAS CPU Peak";
COL aas_cpu_99_99_perc FOR 999999999999990.0 HEA "AAS CPU 99.99% Percentile";
COL aas_cpu_99_9_perc  FOR 999999999999990.0 HEA "AAS CPU 99.9% Percentile";
COL aas_cpu_99_perc    FOR 999999999999990.0 HEA "AAS CPU 99% Percentile";
COL aas_cpu_95_perc    FOR 999999999999990.0 HEA "AAS CPU 95% Percentile";
COL aas_cpu_90_perc    FOR 999999999999990.0 HEA "AAS CPU 90% Percentile";
COL aas_cpu_75_perc    FOR 999999999999990.0 HEA "AAS CPU 75% Percentile";
COL aas_cpu_50_perc    FOR 999999999999990.0 HEA "AAS CPU 50% Percentile";

DEF title = 'CPU Consumption (AWR)';
DEF main_table = 'DBA_HIST_SYS_TIME_MODEL_S';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes. Consider Peak or high Percentile for sizing.'
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
--, aas_cpu_99_99_perc
--, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
FROM cpu_time
WHERE eadam_seq_id = &&eadam_seq_id.
AND cpu_time_type = ''CON''
AND cpu_time_source = ''AWR''
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_SYS_TIME_MODEL_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'AAS consuming CPU';
DEF tit_01 = 'Consumed CPU (Background + Foreground)';
DEF tit_02 = 'Background CPU';
DEF tit_03 = 'DB CPU (Foreground)';
DEF tit_04 = '';
DEF tit_05 = '';
DEF tit_06 = '';
DEF tit_07 = '';
DEF tit_08 = '';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       consumed_cpu,
       background_cpu,
       db_cpu,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM cpu_consumption_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time
';
END;
/

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'CPU Consumption Series for Cluster';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&avg_cpu_count.,';

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 1';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 2';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 3';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 4';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 5';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 6';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 7';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'CPU Consumption Series for Instance 8';
DEF abstract = 'Average Active Sessions (AAS) consuming CPU.'
DEF foot = 'DB CPU corresponds to Foreground processes'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql


DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 
DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

DEF title = 'Memory Size (MEM)';
DEF main_table = 'GV_SYSTEM_PARAMETER2_S';
DEF abstract = 'Consolidated view of Memory requirements.'
DEF abstract2 = 'It considers AMM if setup, else ASMM if setup, else no memory management settings (individual pools size).'
DEF foot = 'Consider "Giga Bytes (GB)" column for sizing.'
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name               
, instance_number         
, instance_name           
, total_required          
, total_required_gb       
, memory_target           
, memory_target_gb        
, memory_max_target       
, memory_max_target_gb    
, sga_target              
, sga_target_gb           
, sga_max_size            
, sga_max_size_gb         
, max_sga_alloc           
, max_sga_alloc_gb        
, pga_aggregate_target    
, pga_aggregate_target_gb 
, max_pga_alloc           
, max_pga_alloc_gb        
FROM memory_size
WHERE eadam_seq_id = &&eadam_seq_id.
AND memory_source = ''MEM''
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF title = 'Memory Size (AWR)';
DEF main_table = 'DBA_HIST_PARAMETER_S';
DEF abstract = 'Consolidated view of Memory requirements.'
DEF abstract2 = 'It considers AMM if setup, else ASMM if setup, else no memory management settings (individual pools size).'
DEF foot = 'Consider "Giga Bytes (GB)" column for sizing.'
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name               
, instance_number         
, instance_name           
, total_required          
, total_required_gb       
, memory_target           
, memory_target_gb        
, memory_max_target       
, memory_max_target_gb    
, sga_target              
, sga_target_gb           
, sga_max_size            
, sga_max_size_gb         
, max_sga_alloc           
, max_sga_alloc_gb        
, pga_aggregate_target    
, pga_aggregate_target_gb 
, max_pga_alloc           
, max_pga_alloc_gb        
FROM memory_size
WHERE eadam_seq_id = &&eadam_seq_id.
AND memory_source = ''AWR''
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_SGA_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vbaseline = '';
DEF vaxis = 'Memory in Giga Bytes (GB)';
DEF tit_01 = 'Total (SGA + PGA)';
DEF tit_02 = 'SGA';
DEF tit_03 = 'PGA';
DEF tit_04 = '';
DEF tit_05 = '';
DEF tit_06 = '';
DEF tit_07 = '';
DEF tit_08 = '';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       mem_gb,
       sga_gb,
       pga_gb,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM memory_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time
';
END;
/

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'Memory Size Series for Cluster';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

DEF title = 'Database Size on Disk';
DEF main_table = 'DBA_HIST_DATABASE_INSTANC_S';
DEF abstract = 'Displays Space on Disk including datafiles, tempfiles, log and control files.'
DEF foot = 'Consider "Tera Bytes (TB)" column for sizing.'
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, file_type 
, size_bytes
, size_gb   
FROM database_size
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE file_type WHEN ''Total'' THEN 1 ELSE 0 END, size_bytes DESC
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF title = 'IOPS and MBPS';
DEF main_table = 'DBA_HIST_SYSSTAT_S';
DEF abstract = 'I/O Operations per Second (IOPS) and I/O Mega Bytes per Second (MBPS). Includes Peak (max), percentiles and average for read (R), write (W) and read+write (RW) operations.'
DEF foot = 'Consider Peak or high Percentile for sizing.'
COL db_name FOR A9;
COL host_name FOR A64;
COL instance_name FOR A16;
BEGIN
  :sql_text := '
SELECT 
  dbid              
, db_name           
, host_name               
, instance_number         
, instance_name           
, rw_iops_peak      
, r_iops_peak       
, w_iops_peak       
, rw_mbps_peak      
, r_mbps_peak       
, w_mbps_peak       
--, rw_iops_perc_99_99
--, r_iops_perc_99_99 
--, w_iops_perc_99_99 
--, rw_mbps_perc_99_99
--, r_mbps_perc_99_99 
--, w_mbps_perc_99_99 
--, rw_iops_perc_99_9 
--, r_iops_perc_99_9  
--, w_iops_perc_99_9  
--, rw_mbps_perc_99_9 
--, r_mbps_perc_99_9  
--, w_mbps_perc_99_9  
, rw_iops_perc_99   
, r_iops_perc_99    
, w_iops_perc_99    
, rw_mbps_perc_99   
, r_mbps_perc_99    
, w_mbps_perc_99    
, rw_iops_perc_95   
, r_iops_perc_95    
, w_iops_perc_95    
, rw_mbps_perc_95   
, r_mbps_perc_95    
, w_mbps_perc_95    
, rw_iops_perc_90   
, r_iops_perc_90    
, w_iops_perc_90    
, rw_mbps_perc_90   
, r_mbps_perc_90    
, w_mbps_perc_90    
, rw_iops_perc_75   
, r_iops_perc_75    
, w_iops_perc_75    
, rw_mbps_perc_75   
, r_mbps_perc_75    
, w_mbps_perc_75    
, rw_iops_perc_50   
, r_iops_perc_50    
, w_iops_perc_50    
, rw_mbps_perc_50   
, r_mbps_perc_50    
, w_mbps_perc_50    
FROM iops_and_mbps
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE aggregate_level WHEN ''I'' THEN 1 ELSE 2 END, instance_number
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_SYSSTAT_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vbaseline = '';
DEF vaxis = 'IOPS (RW, R and W)';
DEF tit_01 = 'RW IOPS';
DEF tit_02 = 'R IOPS';
DEF tit_03 = 'W IOPS';
DEF tit_04 = '';
DEF tit_05 = '';
DEF tit_06 = '';
DEF tit_07 = '';
DEF tit_08 = '';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       rw_iops,
       r_iops,
       w_iops,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM iops_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time
';
END;
/

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
DEF title = 'IOPS Series for Cluster';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_SYSSTAT_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vbaseline = '';
DEF vaxis = 'MBPS (RW, R and W)';
DEF tit_01 = 'RW MBPS';
DEF tit_02 = 'R MBPS';
DEF tit_03 = 'W MBPS';
DEF tit_04 = '';
DEF tit_05 = '';
DEF tit_06 = '';
DEF tit_07 = '';
DEF tit_08 = '';
DEF tit_09 = '';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';

BEGIN
  :sql_text_backup := '
SELECT begin_time,
       end_time,
       rw_mbps,
       r_mbps,
       w_mbps,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM mbps_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD'') + 1
 ORDER BY
       begin_time
';
END;
/

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
DEF title = 'MBPS Series for Cluster';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '-1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/
