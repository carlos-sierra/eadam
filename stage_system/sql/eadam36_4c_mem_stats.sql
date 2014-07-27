DEF section_name = 'Memory Statistics History';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'DBA_HIST_OSSTAT_S';
DEF chartype = 'LineChart';
DEF stacked = '';
DEF vaxis = 'Memory Statistics in GB';
DEF vbaseline = '';
DEF tit_01 = 'SGA + PGA';
DEF tit_02 = 'SGA';
DEF tit_03 = 'PGA';
DEF tit_04 = 'VM IN';
DEF tit_05 = 'VM OUT';
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
WITH
vm AS (
SELECT /*+ &&sq_fact_hints. */
       h1.snap_id,
       h1.dbid,
       h1.instance_number,
       SUM(CASE WHEN h1.stat_name = ''VM_IN_BYTES''  AND h1.value > h0.value THEN h1.value - h0.value ELSE 0 END) in_bytes,
       SUM(CASE WHEN h1.stat_name = ''VM_OUT_BYTES'' AND h1.value > h0.value THEN h1.value - h0.value ELSE 0 END) out_bytes
  FROM dba_hist_osstat_s h0,
       dba_hist_osstat_s h1
 WHERE h1.eadam_seq_id = &&eadam_seq_id.
   AND h1.dbid = &&eadam_dbid.
   AND h1.stat_name IN (''VM_IN_BYTES'', ''VM_OUT_BYTES'')
   AND h1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND h1.instance_number = @instance_number@
   AND h0.eadam_seq_id = &&eadam_seq_id.
   AND h0.dbid = &&eadam_dbid.
   AND h0.snap_id = h1.snap_id - 1
   AND h0.dbid = h1.dbid
   AND h0.instance_number = h1.instance_number
   AND h0.stat_name = h1.stat_name
 GROUP BY
       h1.snap_id,
       h1.dbid,
       h1.instance_number
),
sga AS (
SELECT /*+ &&sq_fact_hints. */
       h1.snap_id,
       h1.dbid,
       h1.instance_number,
       SUM(h1.value) bytes
  FROM dba_hist_sga_s h1
 WHERE h1.eadam_seq_id = &&eadam_seq_id.
   AND h1.dbid = &&eadam_dbid.
   AND h1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND h1.instance_number = @instance_number@
 GROUP BY
       h1.snap_id,
       h1.dbid,
       h1.instance_number
),
pga AS (
SELECT /*+ &&sq_fact_hints. */
       h1.snap_id,
       h1.dbid,
       h1.instance_number,
       SUM(h1.value) bytes
  FROM dba_hist_pgastat_s h1
 WHERE h1.eadam_seq_id = &&eadam_seq_id.
   AND h1.dbid = &&eadam_dbid.
   AND h1.name = ''maximum PGA allocated''
   AND h1.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND h1.instance_number = @instance_number@
 GROUP BY
       h1.snap_id,
       h1.dbid,
       h1.instance_number
),
mem AS (
SELECT /*+ &&sq_fact_hints. */
       snp.snap_id,
       snp.dbid,
       snp.instance_number,
       snp.begin_interval_time,
       snp.end_interval_time,
       ROUND((CAST(snp.end_interval_time AS DATE) - CAST(snp.begin_interval_time AS DATE)) * 24 * 60 * 60) interval_secs,
       NVL(vm.in_bytes, 0) vm_in_bytes,
       NVL(vm.out_bytes, 0) vm_out_bytes,
       NVL(sga.bytes, 0) sga_bytes,
       NVL(pga.bytes, 0) pga_bytes,
       NVL(sga.bytes, 0) + NVL(pga.bytes, 0) mem_bytes
  FROM dba_hist_snapshot_s snp,
       vm, sga, pga
 WHERE snp.eadam_seq_id = &&eadam_seq_id.
   AND snp.dbid = &&eadam_dbid.
   AND snp.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND snp.end_interval_time > (snp.begin_interval_time + (1 / (24 * 60))) /* filter out snaps apart < 1 min */
   AND vm.snap_id(+) = snp.snap_id
   AND vm.dbid(+) = snp.dbid
   AND vm.instance_number(+) = snp.instance_number
   AND sga.snap_id(+) = snp.snap_id
   AND sga.dbid(+) = snp.dbid
   AND sga.instance_number(+) = snp.instance_number
   AND pga.snap_id(+) = snp.snap_id
   AND pga.dbid(+) = snp.dbid
   AND pga.instance_number(+) = snp.instance_number
)
SELECT TO_CHAR(MIN(begin_interval_time), ''YYYY-MM-DD HH24:MI'') begin_time,
       TO_CHAR(MIN(end_interval_time), ''YYYY-MM-DD HH24:MI'') end_time,
       ROUND(SUM(mem_bytes)/POWER(2,30),1) mem_gb,
       ROUND(SUM(sga_bytes)/POWER(2,30),1) sga_gb,
       ROUND(SUM(pga_bytes)/POWER(2,30),1) pga_gb,
       ROUND(SUM(vm_in_bytes)/POWER(2,30),1) vm_in_gb,
       ROUND(SUM(vm_out_bytes)/POWER(2,30),1) vm_out_gb,
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
  FROM mem
 WHERE mem_bytes > 0
 GROUP BY
       snap_id
 ORDER BY
       begin_time
';
END;
/

DEF skip_lch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'Memory Statistics for Cluster';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', 'h1.instance_number');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'Memory Statistics for Instance 1';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '1');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'Memory Statistics for Instance 2';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '2');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'Memory Statistics for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '3');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'Memory Statistics for Instance 4';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '4');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'Memory Statistics for Instance 5';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '5');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'Memory Statistics for Instance 6';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '6');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'Memory Statistics for Instance 7';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '7');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF skip_lch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'Memory Statistics for Instance 8';
EXEC :sql_text := REPLACE(:sql_text_backup, '@instance_number@', '8');
@@&&skip_all.&&skip_diagnostics.eadam36_9a_pre_one.sql

