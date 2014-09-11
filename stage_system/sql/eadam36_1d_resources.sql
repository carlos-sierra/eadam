DEF section_name = 'Resources';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

COL eadam_seq_id NOPRI;
COL db_name FOR A9;
COL host_name FOR A64;
COL instance_name FOR A16;
COL db_unique_name FOR A30;
COL platform_name FOR A101;
COL version FOR A17;

/*****************************************************************************************/

DEF title = 'CPU Demand (MEM)';
DEF main_table = 'GV_ACTIVE_SESSION_HISTORY_S';
DEF abstract = 'Number of Sessions demanding CPU. Includes Peak (max), percentiles and average.'
DEF foot = 'Consider Peak for sizing. Instance Number -1 means aggregated values (SUM) while -2 means over all instances (combined).'

COL aas_on_cpu_and_resmgr_peak    FOR 999999999999990.0 HEA "CPU and RESMGR Peak";
COL aas_on_cpu_peak               FOR 999999999999990.0 HEA "CPU Peak";
COL aas_resmgr_cpu_quantum_peak   FOR 999999999999990.0 HEA "RESMGR Peak";
COL aas_on_cpu_and_resmgr_9999    FOR 999999999999990.0 HEA "CPU and RESMGR 99.99%";
COL aas_on_cpu_9999               FOR 999999999999990.0 HEA "CPU 99.99%";
COL aas_resmgr_cpu_quantum_9999   FOR 999999999999990.0 HEA "RESMGR 99.99%";
COL aas_on_cpu_and_resmgr_999     FOR 999999999999990.0 HEA "CPU and RESMGR 99.9%";
COL aas_on_cpu_999                FOR 999999999999990.0 HEA "CPU 99.9%";
COL aas_resmgr_cpu_quantum_999    FOR 999999999999990.0 HEA "RESMGR 99.9%";
COL aas_on_cpu_and_resmgr_99      FOR 999999999999990.0 HEA "CPU and RESMGR 99%";
COL aas_on_cpu_99                 FOR 999999999999990.0 HEA "CPU 99%";
COL aas_resmgr_cpu_quantum_99     FOR 999999999999990.0 HEA "RESMGR 99%";
COL aas_on_cpu_and_resmgr_95      FOR 999999999999990.0 HEA "CPU and RESMGR 95%";
COL aas_on_cpu_95                 FOR 999999999999990.0 HEA "CPU 95%";
COL aas_resmgr_cpu_quantum_95     FOR 999999999999990.0 HEA "RESMGR 95%";
COL aas_on_cpu_and_resmgr_90      FOR 999999999999990.0 HEA "CPU and RESMGR 90%";
COL aas_on_cpu_90                 FOR 999999999999990.0 HEA "CPU 90%";
COL aas_resmgr_cpu_quantum_90     FOR 999999999999990.0 HEA "RESMGR 90%";
COL aas_on_cpu_and_resmgr_75      FOR 999999999999990.0 HEA "CPU and RESMGR 75%";
COL aas_on_cpu_75                 FOR 999999999999990.0 HEA "CPU 75%";
COL aas_resmgr_cpu_quantum_75     FOR 999999999999990.0 HEA "RESMGR 75%";
COL aas_on_cpu_and_resmgr_median  FOR 999999999999990.0 HEA "CPU and RESMGR MEDIAN";
COL aas_on_cpu_median             FOR 999999999999990.0 HEA "CPU MEDIAN";
COL aas_resmgr_cpu_quantum_median FOR 999999999999990.0 HEA "RESMGR MEDIAN";
COL aas_on_cpu_and_resmgr_avg     FOR 999999999999990.0 HEA "CPU and RESMGR AVG";
COL aas_on_cpu_avg                FOR 999999999999990.0 HEA "CPU AVG";
COL aas_resmgr_cpu_quantum_avg    FOR 999999999999990.0 HEA "RESMGR AVG";

BEGIN
  :sql_text := '
SELECT *
FROM cpu_demand_mem_v
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE WHEN instance_number > 0 THEN instance_number ELSE - (instance_number * 999) END
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF title = 'CPU Demand (AWR)';
DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF abstract = 'Number of Sessions demanding CPU. Includes Peak (max), percentiles and average.'
DEF foot = 'Consider Peak or high Percentile for sizing. Instance Number -1 means aggregated values (SUM) while -2 means over all instances (combined).'
BEGIN
  :sql_text := '
SELECT *
FROM cpu_demand_awr_v
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE WHEN instance_number > 0 THEN instance_number ELSE - (instance_number * 999) END
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'Sessions "ON CPU" or "ON CPU" + "resmgr:cpu quantum"';
DEF tit_01 = 'ON CPU + resmgr:cpu quantum';
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
       on_cpu_and_resmgr,
       on_cpu,
       resmgr,
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
  FROM cpu_demand_series_v
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 ORDER BY
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
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 1';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 2';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 3';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 4';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 5';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 6';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 7';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Peak) for Instance 8';
DEF abstract = 'Number of Sessions demanding CPU. Based on peak demand per hour.'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'Sessions "ON CPU"';
DEF tit_01 = 'Maximum (peak)';
DEF tit_02 = '99% Percentile';
DEF tit_03 = '95% Percentile';
DEF tit_04 = '90% Percentile';
DEF tit_05 = '75% Percentile';
DEF tit_06 = 'Median';
DEF tit_07 = 'Average';
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
       on_cpu_max,
       on_cpu_99p,
       on_cpu_95p,
       on_cpu_90p,
       on_cpu_75p,
       on_cpu_med,
       on_cpu_avg,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM cpu_demand_series_v
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 ORDER BY
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
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 1';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 2';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 3';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 4';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 5';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 6';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 7';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'CPU Demand Series (Percentile) for Instance 8';
DEF abstract = 'Number of Sessions demanding CPU. Based on percentiles per hour as per Active Session History (ASH).'
DEF foot = 'Sessions "ON CPU" or waiting on "resmgr:cpu quantum"'
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF vbaseline = 'baseline:&&sum_cpu_count.,'; 

/*****************************************************************************************/

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

DEF title = 'Memory Size (MEM)';
DEF main_table = 'GV_SYSTEM_PARAMETER2_S';
DEF abstract = 'Consolidated view of Memory requirements.'
DEF abstract2 = 'It considers AMM if setup, else ASMM if setup, else no memory management settings (individual pools size).'
DEF foot = 'Consider "Giga Bytes (GB)" column for sizing. Instance Number -1 means aggregated values (SUM) while -2 means over all instances (combined).'
BEGIN
  :sql_text := '
SELECT *
FROM memory_mem_v
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE WHEN instance_number > 0 THEN instance_number ELSE - (instance_number * 999) END
';
END;
/
@@eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF title = 'Memory Size (AWR)';
DEF main_table = 'DBA_HIST_PARAMETER_S';
DEF abstract = 'Consolidated view of Memory requirements.'
DEF abstract2 = 'It considers AMM if setup, else ASMM if setup, else no memory management settings (individual pools size).'
DEF foot = 'Consider "Giga Bytes (GB)" column for sizing. Instance Number -1 means aggregated values (SUM) while -2 means over all instances (combined).'
BEGIN
  :sql_text := '
SELECT *
FROM memory_awr_v
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE WHEN instance_number > 0 THEN instance_number ELSE - (instance_number * 999) END
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
  FROM memory_series_v
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 ORDER BY
       end_time
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
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'Memory Size Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 8 AND ROWNUM = 1;
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
SELECT *
FROM db_size_v
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
DEF foot = 'Consider Peak or high Percentile for sizing. Instance Number -1 means aggregated values (SUM) while -2 means over all instances (combined).'
BEGIN
  :sql_text := '
SELECT *
FROM disk_perf_v
WHERE eadam_seq_id = &&eadam_seq_id.
ORDER BY CASE WHEN instance_number > 0 THEN instance_number ELSE - (instance_number * 999) END
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
  FROM disk_perf_series_v
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 ORDER BY
       end_time
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
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'IOPS Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) I/O Operations per Second (IOPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 8 AND ROWNUM = 1;
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
  FROM disk_perf_series_v
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND instance_number = @instance_number@
   AND begin_time BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 ORDER BY
       end_time
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
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 1 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 2 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 3 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 4 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 5 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 6 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 7 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
DEF abstract = 'Read (R), Write (W) and Read-Write (RW) Mega Bytes per Second (MBPS).'
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.AND instance_number = 8 AND ROWNUM = 1;
DEF title = 'MBPS Series for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/
