DEF section_name = 'System Global Area (SGA) Statistics History';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'DBA_HIST_SGASTAT_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'SGA Statistics in Bytes';
DEF vbaseline = '';
DEF tit_01 = 'Total SGA allocated';
DEF tit_02 = 'Fixed SGA';
DEF tit_03 = 'Buffer Cache';
DEF tit_04 = 'Log Buffer';
DEF tit_05 = 'Shared IO Pool';
DEF tit_06 = 'Shared Pool';
DEF tit_07 = 'Large Pool';
DEF tit_08 = 'Java Pool';
DEF tit_09 = 'Streams Pool';
DEF tit_10 = '';
DEF tit_11 = '';
DEF tit_12 = '';
DEF tit_13 = '';
DEF tit_14 = '';
DEF tit_15 = '';
BEGIN
  :sql_text_backup := '
WITH 
sgastat_denorm_1 AS (
SELECT /*+ &&sq_fact_hints. */
       snap_id,
       dbid,
       instance_number,
       SUM(bytes) sga_total,
       SUM(CASE WHEN pool IS NULL AND name = ''fixed_sga'' THEN bytes ELSE 0 END) fixed_sga,
       SUM(CASE WHEN pool IS NULL AND name = ''buffer_cache'' THEN bytes ELSE 0 END) buffer_cache,
       SUM(CASE WHEN pool IS NULL AND name = ''log_buffer'' THEN bytes ELSE 0 END) log_buffer,
       SUM(CASE WHEN pool IS NULL AND name = ''shared_io_pool'' THEN bytes ELSE 0 END) shared_io_pool,
       SUM(CASE pool WHEN ''shared pool'' THEN bytes ELSE 0 END) shared_pool,
       SUM(CASE pool WHEN ''large pool'' THEN bytes ELSE 0 END) large_pool,
       SUM(CASE pool WHEN ''java pool'' THEN bytes ELSE 0 END) java_pool,
       SUM(CASE pool WHEN ''streams pool'' THEN bytes ELSE 0 END) streams_pool       
  FROM dba_hist_sgastat_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND instance_number = @instance_number@
 GROUP BY
       snap_id,
       dbid,
       instance_number
),
sgastat_denorm_2 AS (
SELECT /*+ &&sq_fact_hints. */
       h1.snap_id,
       h1.dbid,
       h1.instance_number,
       s1.begin_interval_time,
       s1.end_interval_time,
       ROUND((CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 24 * 60 * 60) interval_secs,
       h1.sga_total,
       h1.fixed_sga,
       h1.buffer_cache,
       h1.log_buffer,
       h1.shared_io_pool,
       h1.shared_pool,
       h1.large_pool,
       h1.java_pool,
       h1.streams_pool
  FROM sgastat_denorm_1 h0,
       sgastat_denorm_1 h1,
       dba_hist_snapshot_s s0,
       dba_hist_snapshot_s s1
 WHERE h1.snap_id = h0.snap_id + 1
   AND h1.dbid = h0.dbid
   AND h1.instance_number = h0.instance_number
   AND s0.eadam_seq_id = &&eadam_seq_id.
   AND s0.dbid = &&eadam_dbid.
   AND s0.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND s0.snap_id = h0.snap_id
   AND s0.dbid = h0.dbid
   AND s0.instance_number = h0.instance_number
   AND s1.eadam_seq_id = &&eadam_seq_id.
   AND s1.dbid = &&eadam_dbid.
   AND s1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND s1.snap_id = h1.snap_id
   AND s1.dbid = h1.dbid
   AND s1.instance_number = h1.instance_number
   AND s1.snap_id = s0.snap_id + 1
   AND s1.startup_time = s0.startup_time
   AND s1.begin_interval_time > (s0.begin_interval_time + (1 / (24 * 60))) /* filter out snaps apart < 1 min */
)
SELECT TO_CHAR(MIN(begin_interval_time), ''YYYY-MM-DD HH24:MI'') begin_time,
       TO_CHAR(MIN(end_interval_time), ''YYYY-MM-DD HH24:MI'') end_time,
       SUM(sga_total) sga_total,
       SUM(fixed_sga) fixed_sga,
       SUM(buffer_cache) buffer_cache,
       SUM(log_buffer) log_buffer,
       SUM(shared_io_pool) shared_io_pool,
       SUM(shared_pool) shared_pool,
       SUM(large_pool) large_pool,
       SUM(java_pool) java_pool,
       SUM(streams_pool) streams_pool,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
  FROM sgastat_denorm_2
 GROUP BY
       snap_id
 ORDER BY
       begin_time
';
END;
/

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'SGA Statistics for Cluster';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', 'instance_number');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'SGA Statistics for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'SGA Statistics for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'SGA Statistics for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'SGA Statistics for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'SGA Statistics for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'SGA Statistics for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'SGA Statistics for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'SGA Statistics for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql
