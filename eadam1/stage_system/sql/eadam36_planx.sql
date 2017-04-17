SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 50 TIMI OFF LONG 40000 LONGC 200 TRIMS ON AUTOT OFF;
CL COL;

-- list
COL seq FOR 999;
COL dbname_instance_host FOR A50;
COL version FOR A10;
COL captured FOR A8;
SELECT eadam_seq_id seq,
       SUBSTR(dbname||':'||db_unique_name||':'||instance_name||':'||host_name, 1, 50) dbname_instance_host,
       version,
       SUBSTR(capture_time, 1, 8) captured
  FROM dba_hist_xtr_control_s
 ORDER BY 1;

-- parameters
PRO
PRO Parameter 1: eAdam seq_id (required)
UNDEF x_eadam_seq_id;
COL x_eadam_seq_id NEW_V x_eadam_seq_id NOPRI;
COL x_min_date NEW_V x_min_date FOR A16 HEA "MIN_DATE";
COL x_max_date NEW_V x_max_date FOR A16 HEA "MAX_DATE";
DEF x_eadam_seq_id = '&1.';

SELECT NVL(TO_CHAR(MIN(eadam_seq_id)), '&&x_eadam_seq_id.') x_eadam_seq_id,
       NVL(TO_CHAR(MIN(begin_interval_time), 'YYYY-MM-DD/HH24:MI'), TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI')) x_min_date,
       NVL(TO_CHAR(MAX(end_interval_time), 'YYYY-MM-DD/HH24:MI'), TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI')) x_max_date
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = TO_NUMBER(TRIM('&&x_eadam_seq_id.'));

SELECT NVL(MAX(TO_CHAR(CAST(sample_time AS DATE), 'YYYY-MM-DD/HH24:MI')), '&&x_max_date.') x_max_date
  FROM gv_active_session_history_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(CAST(sample_time AS DATE), 'YYYY-MM-DD/HH24:MI') > '&&x_max_date.';

SELECT NVL(MIN(TO_CHAR(CAST(sample_time AS DATE), 'YYYY-MM-DD/HH24:MI')), '&&min_date.') x_min_date
  FROM gv_active_session_history_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(CAST(sample_time AS DATE), 'YYYY-MM-DD/HH24:MI') < '&&x_min_date.';

SELECT '&&x_min_date.' begin_date_default, '&&x_max_date.' end_date_default FROM DUAL;

PRO
PRO Parameter 2: Begin date "YYYY-MM-DD/HH24:MI": (opt)
COL x_minimum_snap_id NEW_V x_minimum_snap_id NOPRI;
COL x_begin_date NEW_V x_begin_date FOR A16 NOPRI;

SELECT NVL(MAX(TO_CHAR(begin_interval_time, 'YYYY-MM-DD/HH24:MI')), '&&x_min_date.') x_begin_date
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(begin_interval_time, 'YYYY-MM-DD/HH24:MI') <= NVL(TRIM('&2.'), '&&x_min_date.');

SELECT NVL(MIN(snap_id), -1) x_minimum_snap_id
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(begin_interval_time, 'YYYY-MM-DD/HH24:MI') >= NVL('&&x_begin_date.', '&&x_min_date.');

PRO Parameter 3: End date "YYYY-MM-DD/HH24:MI": (opt)
COL x_maximum_snap_id NEW_V x_maximum_snap_id NOPRI;
COL x_end_date NEW_V x_end_date FOR A16 NOPRI;

SELECT NVL(MIN(TO_CHAR(end_interval_time, 'YYYY-MM-DD/HH24:MI')), '&&x_max_date.') x_end_date
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(end_interval_time, 'YYYY-MM-DD/HH24:MI') >= NVL(TRIM('&3.'), '&&x_max_date.');

SELECT NVL(MAX(snap_id), -1) x_maximum_snap_id
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND TO_CHAR(end_interval_time, 'YYYY-MM-DD/HH24:MI') <= NVL('&&x_end_date.', '&&x_max_date.');

PRO Parameter 4: Enter SQL_ID (required)
COL sql_id NEW_V sql_id FOR A13 NOPRI;
SELECT TRIM('&4') sql_id FROM DUAL;

-- get dbid
VAR dbid NUMBER;
BEGIN
  SELECT dbid INTO :dbid FROM dba_hist_xtr_control_s WHERE eadam_seq_id = &&x_eadam_seq_id.;
END;
/
-- is_10g
DEF is_10g = '';
COL is_10g NEW_V is_10g NOPRI;
SELECT '--' is_10g FROM dba_hist_xtr_control_s WHERE eadam_seq_id = &&x_eadam_seq_id. AND version LIKE '10%';
-- get current time
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
-- spool and sql_text
SPO planx_&&sql_id._&&current_time..txt;
PRO EADAM : &&x_eadam_seq_id. between &&x_min_date. and &&x_max_date.
PRO SQL_ID: &&sql_id. between &&x_begin_date. and &&x_end_date.
PRO
SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 0 TIMI OFF LONG 40000 LONGC 200 TRIMS ON AUTOT OFF;
SELECT sql_fulltext FROM gv_sql_s WHERE eadam_seq_id = &&x_eadam_seq_id. AND sql_id = '&&sql_id.' AND ROWNUM = 1;
SELECT sql_text FROM dba_hist_sqltext_s WHERE eadam_seq_id = &&x_eadam_seq_id. AND sql_id = '&&sql_id.' AND ROWNUM = 1 AND NOT EXISTS
(SELECT sql_fulltext FROM gv_sql_s WHERE eadam_seq_id = &&x_eadam_seq_id. AND sql_id = '&&sql_id.' AND ROWNUM = 1);

SET PAGES 50000;
COL is_shareable FOR A12;
COL loaded FOR A6;
COL executions FOR A20;
COL rows_processed FOR A20;
COL buffer_gets FOR A20;
COL disk_reads FOR A20;
COL direct_writes FOR A20;
COL elsapsed_secs FOR A18;
COL cpu_secs FOR A18;
COL user_io_wait_secs FOR A18;
COL cluster_wait_secs FOR A18;
COL appl_wait_secs FOR A18;
COL conc_wait_secs FOR A18;
COL plsql_exec_secs FOR A18;
COL java_exec_secs FOR A18;
COL io_cell_offload_eligible_bytes FOR A30;
COL io_interconnect_bytes FOR A30;
COL io_saved FOR A8;

PRO
PRO GV_SQL_S (ordered by inst_id and child_number) after &&x_begin_date.
PRO ~~~~~~~~

SELECT inst_id, child_number, plan_hash_value, &&is_10g.is_shareable, 
       DECODE(loaded_versions, 1, 'Y', 'N') loaded, 
       LPAD(TO_CHAR(executions, '999,999,999,999,990'), 20) executions, 
       LPAD(TO_CHAR(rows_processed, '999,999,999,999,990'), 20) rows_processed, 
       LPAD(TO_CHAR(buffer_gets, '999,999,999,999,990'), 20) buffer_gets,
       LPAD(TO_CHAR(disk_reads, '999,999,999,999,990'), 20) disk_reads, 
       LPAD(TO_CHAR(direct_writes, '999,999,999,999,990'), 20) direct_writes,
       LPAD(TO_CHAR(ROUND(elapsed_time/1e6, 3), '999,999,990.000'), 18) elsapsed_secs,
       LPAD(TO_CHAR(ROUND(cpu_time/1e6, 3), '999,999,990.000'), 18) cpu_secs,
       LPAD(TO_CHAR(ROUND(user_io_wait_time/1e6, 3), '999,999,990.000'), 18) user_io_wait_secs,
       LPAD(TO_CHAR(ROUND(cluster_wait_time/1e6, 3), '999,999,990.000'), 18) cluster_wait_secs,
       LPAD(TO_CHAR(ROUND(application_wait_time/1e6, 3), '999,999,990.000'), 18) appl_wait_secs,
       LPAD(TO_CHAR(ROUND(concurrency_wait_time/1e6, 3), '999,999,990.000'), 18) conc_wait_secs,
       LPAD(TO_CHAR(ROUND(plsql_exec_time/1e6, 3), '999,999,990.000'), 18) plsql_exec_secs,
       LPAD(TO_CHAR(ROUND(java_exec_time/1e6, 3), '999,999,990.000'), 18) java_exec_secs&&is_10g.,
       &&is_10g.LPAD(TO_CHAR(io_cell_offload_eligible_bytes, '999,999,999,999,999,999,990'), 30) io_cell_offload_eligible_bytes,
       &&is_10g.LPAD(TO_CHAR(io_interconnect_bytes, '999,999,999,999,999,999,990'), 30) io_interconnect_bytes,
       &&is_10g.CASE 
         &&is_10g.WHEN io_cell_offload_eligible_bytes > io_interconnect_bytes THEN
           &&is_10g.LPAD(TO_CHAR(ROUND(
           &&is_10g.(io_cell_offload_eligible_bytes - io_interconnect_bytes) * 100 / io_cell_offload_eligible_bytes
           &&is_10g., 2), '990.00')||' %', 8) END io_saved
  FROM gv_sql_s
 WHERE eadam_seq_id = &&x_eadam_seq_id. 
   AND sql_id = '&&sql_id.'
   AND last_active_time >= TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI')
 ORDER BY 1, 2
/

SET PAGES 0;
COL inst_child FOR A21;
BREAK ON inst_child SKIP 2;

PRO       
PRO GV_SQL_PLAN_STATISTICS_AL_S LAST (ordered by inst_id and child_number) after &&x_begin_date. 
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH v AS (
SELECT /*+ MATERIALIZE */
       DISTINCT eadam_seq_id, sql_id, inst_id, child_number
  FROM gv_sql_s
 WHERE eadam_seq_id = &&x_eadam_seq_id. 
   AND sql_id = '&&sql_id.'
   AND loaded_versions > 0
   AND (inst_id, child_number) IN (
SELECT inst_id, child_number
  FROM gv_sql_s
 WHERE eadam_seq_id = &&x_eadam_seq_id. 
   AND sql_id = '&&sql_id.'
   AND last_active_time >= TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI'))
 ORDER BY 1, 2, 3 )
SELECT /*+ ORDERED USE_NL(t) */
       RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child, 
       t.plan_table_output
  FROM v, TABLE(DBMS_XPLAN.DISPLAY('gv_sql_plan_statistics_al_s', NULL, 'ADVANCED ALLSTATS LAST', 
       'eadam_seq_id = '||v.eadam_seq_id||' AND inst_id = '||v.inst_id||' AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number)) t
/

SET PAGES 50000;

PRO
PRO DBA_HIST_SQLSTAT_S DELTA (ordered by snap_id DESC, instance_number and plan_hash_value) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~

SELECT s.snap_id, 
       TO_CHAR(s.begin_interval_time, 'YYYY-MM-DD HH24:MI:SS') begin_interval_time,
       TO_CHAR(s.end_interval_time, 'YYYY-MM-DD HH24:MI:SS') end_interval_time,
       s.instance_number, h.plan_hash_value,
       DECODE(h.loaded_versions, 1, 'Y', 'N') loaded, 
       LPAD(TO_CHAR(h.executions_delta, '999,999,999,999,990'), 20) executions, 
       LPAD(TO_CHAR(h.rows_processed_delta, '999,999,999,999,990'), 20) rows_processed, 
       LPAD(TO_CHAR(h.buffer_gets_delta, '999,999,999,999,990'), 20) buffer_gets, 
       LPAD(TO_CHAR(h.disk_reads_delta, '999,999,999,999,990'), 20) disk_reads, 
       LPAD(TO_CHAR(h.direct_writes_delta, '999,999,999,999,990'), 20) direct_writes,
       LPAD(TO_CHAR(ROUND(h.elapsed_time_delta/1e6, 3), '999,999,990.000'), 18) elsapsed_secs,
       LPAD(TO_CHAR(ROUND(h.cpu_time_delta/1e6, 3), '999,999,990.000'), 18) cpu_secs,
       LPAD(TO_CHAR(ROUND(h.iowait_delta/1e6, 3), '999,999,990.000'), 18) user_io_wait_secs,
       LPAD(TO_CHAR(ROUND(h.clwait_delta/1e6, 3), '999,999,990.000'), 18) cluster_wait_secs,
       LPAD(TO_CHAR(ROUND(h.apwait_delta/1e6, 3), '999,999,990.000'), 18) appl_wait_secs,
       LPAD(TO_CHAR(ROUND(h.ccwait_delta/1e6, 3), '999,999,990.000'), 18) conc_wait_secs,
       LPAD(TO_CHAR(ROUND(h.plsexec_time_delta/1e6, 3), '999,999,990.000'), 18) plsql_exec_secs,
       LPAD(TO_CHAR(ROUND(h.javexec_time_delta/1e6, 3), '999,999,990.000'), 18) java_exec_secs&&is_10g.,
       &&is_10g.LPAD(TO_CHAR(h.io_offload_elig_bytes_delta, '999,999,999,999,999,999,990'), 30) io_cell_offload_eligible_bytes,
       &&is_10g.LPAD(TO_CHAR(h.io_interconnect_bytes_delta, '999,999,999,999,999,999,990'), 30) io_interconnect_bytes,
       &&is_10g.CASE 
         &&is_10g.WHEN h.io_offload_elig_bytes_delta > h.io_interconnect_bytes_delta THEN
           &&is_10g.LPAD(TO_CHAR(ROUND(
           &&is_10g.(h.io_offload_elig_bytes_delta - h.io_interconnect_bytes_delta) * 100 / h.io_offload_elig_bytes_delta
           &&is_10g., 2), '990.00')||' %', 8) END io_saved
  FROM dba_hist_sqlstat_s h,
       dba_hist_snapshot_s s
 WHERE h.eadam_seq_id = &&x_eadam_seq_id.
   AND h.dbid = :dbid
   AND h.snap_id BETWEEN &&x_minimum_snap_id. AND &&x_maximum_snap_id.
   AND h.sql_id = '&&sql_id.'
   AND s.eadam_seq_id = &&x_eadam_seq_id.
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 ORDER BY 1 DESC, 4, 5
/

PRO
PRO DBA_HIST_SQLSTAT_S TOTAL (ordered by snap_id DESC, instance_number and plan_hash_value) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~

SELECT s.snap_id, 
       TO_CHAR(s.begin_interval_time, 'YYYY-MM-DD HH24:MI:SS') begin_interval_time,
       TO_CHAR(s.end_interval_time, 'YYYY-MM-DD HH24:MI:SS') end_interval_time,
       s.instance_number, h.plan_hash_value,
       DECODE(h.loaded_versions, 1, 'Y', 'N') loaded, 
       LPAD(TO_CHAR(h.executions_total, '999,999,999,999,990'), 20) executions, 
       LPAD(TO_CHAR(h.rows_processed_total, '999,999,999,999,990'), 20) rows_processed, 
       LPAD(TO_CHAR(h.buffer_gets_total, '999,999,999,999,990'), 20) buffer_gets, 
       LPAD(TO_CHAR(h.disk_reads_total, '999,999,999,999,990'), 20) disk_reads, 
       LPAD(TO_CHAR(h.direct_writes_total, '999,999,999,999,990'), 20) direct_writes,
       LPAD(TO_CHAR(ROUND(h.elapsed_time_total/1e6, 3), '999,999,990.000'), 18) elsapsed_secs,
       LPAD(TO_CHAR(ROUND(h.cpu_time_total/1e6, 3), '999,999,990.000'), 18) cpu_secs,
       LPAD(TO_CHAR(ROUND(h.iowait_total/1e6, 3), '999,999,990.000'), 18) user_io_wait_secs,
       LPAD(TO_CHAR(ROUND(h.clwait_total/1e6, 3), '999,999,990.000'), 18) cluster_wait_secs,
       LPAD(TO_CHAR(ROUND(h.apwait_total/1e6, 3), '999,999,990.000'), 18) appl_wait_secs,
       LPAD(TO_CHAR(ROUND(h.ccwait_total/1e6, 3), '999,999,990.000'), 18) conc_wait_secs,
       LPAD(TO_CHAR(ROUND(h.plsexec_time_total/1e6, 3), '999,999,990.000'), 18) plsql_exec_secs,
       LPAD(TO_CHAR(ROUND(h.javexec_time_total/1e6, 3), '999,999,990.000'), 18) java_exec_secs &&is_10g.,
       &&is_10g.LPAD(TO_CHAR(h.io_offload_elig_bytes_total, '999,999,999,999,999,999,990'), 30) io_cell_offload_eligible_bytes,
       &&is_10g.LPAD(TO_CHAR(h.io_interconnect_bytes_total, '999,999,999,999,999,999,990'), 30) io_interconnect_bytes,
       &&is_10g.CASE 
         &&is_10g.WHEN h.io_offload_elig_bytes_total > h.io_interconnect_bytes_total THEN
           &&is_10g.LPAD(TO_CHAR(ROUND(
           &&is_10g.(h.io_offload_elig_bytes_total - h.io_interconnect_bytes_total) * 100 / h.io_offload_elig_bytes_total
           &&is_10g., 2), '990.00')||' %', 8) END io_saved
  FROM dba_hist_sqlstat_s h,
       dba_hist_snapshot_s s
 WHERE h.eadam_seq_id = &&x_eadam_seq_id.
   AND h.dbid = :dbid
   AND h.snap_id BETWEEN &&x_minimum_snap_id. AND &&x_maximum_snap_id.
   AND h.sql_id = '&&sql_id.'
   AND s.eadam_seq_id = &&x_eadam_seq_id.
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 ORDER BY 1 DESC, 4, 5
/

SET PAGES 0;

PRO
PRO DBA_HIST_SQL_PLAN_S (ordered by plan_hash_value) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~
WITH v AS (
SELECT /*+ MATERIALIZE */ DISTINCT 
       eadam_seq_id, sql_id, plan_hash_value, dbid
  FROM dba_hist_sql_plan_s
 WHERE eadam_seq_id = &&x_eadam_seq_id. 
   AND sql_id = '&&sql_id.'
   AND plan_hash_value IN (
SELECT h.plan_hash_value
  FROM dba_hist_sqlstat_s h
 WHERE h.eadam_seq_id = &&x_eadam_seq_id.
   AND h.dbid = :dbid
   AND h.snap_id BETWEEN &&x_minimum_snap_id. AND &&x_maximum_snap_id.
   AND h.sql_id = '&&sql_id.')
 ORDER BY 1, 2, 3 )
SELECT /*+ ORDERED USE_NL(t) */ t.plan_table_output
  FROM v, TABLE(DBMS_XPLAN.DISPLAY('DBA_HIST_SQL_PLAN_V1', NULL, 'ADVANCED', 'eadam_seq_id = '||v.eadam_seq_id||' AND dbid = '||v.dbid||' AND sql_id = '''||v.sql_id||''' AND plan_hash_value = '||v.plan_hash_value)) t
/

DEF x_slices = '10';
SET PAGES 50000;
COL samples FOR 999,999,999,999
COL seconds FOR 999,999,999,999
COL percent FOR 9,990.0;
COL timed_event FOR A70;

PRO
PRO GV_ACTIVE_SESSION_HISTORY_S (by timed event) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH
events AS (
SELECT /*+ MATERIALIZE */
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END timed_event,
       COUNT(*) samples
  FROM gv_active_session_history_s h
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND sql_id = '&&sql_id.'
   AND CAST(sample_time AS DATE) BETWEEN TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&x_end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60) 
 GROUP BY
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&x_slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.samples,
       e.samples seconds,
       ROUND(100 * e.samples / t.samples, 1) percent,
       e.timed_event
  FROM events e,
       total t
 WHERE ROWNUM <= &&x_slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT others samples,
       others seconds,
       ROUND(100 * others / samples, 1) percent,
       'Others' timed_event
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
/

PRO
PRO DBA_HIST_ACTIVE_SESS_HIST_S (by timed event) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH
events AS (
SELECT /*+ MATERIALIZE */
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END timed_event,
       COUNT(*) samples
  FROM dba_hist_active_sess_hist_s h,
       dba_hist_snapshot_s s
 WHERE h.eadam_seq_id = &&x_eadam_seq_id.
   AND h.dbid = :dbid 
   AND h.sql_id = '&&sql_id.'
   AND h.snap_id BETWEEN &&x_minimum_snap_id. AND &&x_maximum_snap_id.
   AND s.eadam_seq_id = &&x_eadam_seq_id.
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND CAST(s.end_interval_time AS DATE) BETWEEN TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&x_end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60) 
 GROUP BY
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&x_slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.samples,
       10 * e.samples seconds,
       ROUND(100 * e.samples / t.samples, 1) percent,
       e.timed_event
  FROM events e,
       total t
 WHERE ROWNUM <= &&x_slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT others samples,
       10 * others seconds,
       ROUND(100 * others / samples, 1) percent,
       'Others' timed_event
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
/

DEF x_slices = '15';
COL operation FOR A50;
COL line_id FOR 9999999;

PRO
PRO GV_ACTIVE_SESSION_HISTORY_S (by plan line and timed event) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH
events AS (
SELECT /*+ MATERIALIZE */
       h.sql_plan_hash_value plan_hash_value,
       NVL(h.sql_plan_line_id, 0) line_id,
       SUBSTR(h.sql_plan_operation||' '||h.sql_plan_options, 1, 50) operation,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END timed_event,
       COUNT(*) samples
  FROM gv_active_session_history_s h
 WHERE eadam_seq_id = &&x_eadam_seq_id.
   AND sql_id = '&&sql_id.'
   AND CAST(sample_time AS DATE) BETWEEN TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&x_end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60) 
 GROUP BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.sql_plan_operation,
       h.sql_plan_options,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END
 ORDER BY
       5 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&x_slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.samples,
       e.samples seconds,
       ROUND(100 * e.samples / t.samples, 1) percent,
       e.plan_hash_value,
       e.line_id,
       e.operation,
       e.timed_event
  FROM events e,
       total t
 WHERE ROWNUM <= &&x_slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT others samples,
       others seconds,
       ROUND(100 * others / samples, 1) percent,
       TO_NUMBER(NULL) plan_hash_value, 
       TO_NUMBER(NULL) id, 
       NULL operation, 
       'Others' timed_event
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
/

PRO
PRO DBA_HIST_ACTIVE_SESS_HIST_S (by plan line and timed event) between &&x_begin_date. and &&x_end_date.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH
events AS (
SELECT /*+ MATERIALIZE */
       h.sql_plan_hash_value plan_hash_value,
       NVL(h.sql_plan_line_id, 0) line_id,
       SUBSTR(h.sql_plan_operation||' '||h.sql_plan_options, 1, 50) operation,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END timed_event,
       COUNT(*) samples
  FROM dba_hist_active_sess_hist_s h,
       dba_hist_snapshot_s s
 WHERE h.eadam_seq_id = &&x_eadam_seq_id.
   AND h.dbid = :dbid 
   AND h.sql_id = '&&sql_id.'
   AND h.snap_id BETWEEN &&x_minimum_snap_id. AND &&x_maximum_snap_id.
   AND s.eadam_seq_id = &&x_eadam_seq_id.
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND CAST(s.end_interval_time AS DATE) BETWEEN TO_DATE('&&x_begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&x_end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60) 
 GROUP BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.sql_plan_operation,
       h.sql_plan_options,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' "'||h.event||'"' END
 ORDER BY
       5 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&x_slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.samples,
       10 * e.samples seconds,
       ROUND(100 * e.samples / t.samples, 1) percent,
       e.plan_hash_value,
       e.line_id,
       e.operation,
       e.timed_event
  FROM events e,
       total t
 WHERE ROWNUM <= &&x_slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT others samples,
       10 * others seconds,
       ROUND(100 * others / samples, 1) percent,
       TO_NUMBER(NULL) plan_hash_value, 
       TO_NUMBER(NULL) id, 
       NULL operation, 
       'Others' timed_event
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
/

-- spool off and cleanup
PRO
PRO planx_&&sql_id._&&current_time..txt has been generated
SET FEED ON VER ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF;
SPO OFF;
UNDEF 1 2 3 4
-- end

