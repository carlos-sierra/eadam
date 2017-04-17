DEF section_name = 'Active Session History (ASH) - Top Timed Events';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'GV_ACTIVE_SESSION_HISTORY_S';
DEF slices = '15';
BEGIN
  :sql_text_backup := '
WITH
events AS (
SELECT /*+ &&sq_fact_hints. */
       CASE h.session_state WHEN ''ON CPU'' THEN h.session_state ELSE h.wait_class||'' "''||h.event||''"'' END timed_event,
       COUNT(*) samples
  FROM gv_active_session_history_s h
 WHERE ''&&diagnostics_pack.'' = ''Y''
   AND eadam_seq_id = &&eadam_seq_id.
   AND @filter_predicate@
   AND CAST(h.sample_time AS DATE) BETWEEN TO_DATE(''&&begin_date.'',''YYYY-MM-DD/HH24:MI'') AND TO_DATE(''&&end_date.'',''YYYY-MM-DD/HH24:MI'') + (1/24/60)
 GROUP BY
       CASE h.session_state WHEN ''ON CPU'' THEN h.session_state ELSE h.wait_class||'' "''||h.event||''"'' END
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.timed_event,
       e.samples,
       ROUND(100 * e.samples / t.samples, 1) percent,
       NULL dummy_01
  FROM events e,
       total t
 WHERE ROWNUM <= &&slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT ''Others'',
       others samples,
       ROUND(100 * others / samples, 1) percent,
       NULL dummy_01
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
';
END;
/

/*****************************************************************************************/

DEF skip_pch = '';
DEF title = 'ASH Top Timed Events for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 1;
DEF title = 'ASH Top Timed Events for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 2;
DEF title = 'ASH Top Timed Events for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 3;
DEF title = 'ASH Top Timed Events for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 4;
DEF title = 'ASH Top Timed Events for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 5;
DEF title = 'ASH Top Timed Events for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 6;
DEF title = 'ASH Top Timed Events for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 7;
DEF title = 'ASH Top Timed Events for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 8;
DEF title = 'ASH Top Timed Events for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 8');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF slices = '15';
BEGIN
  :sql_text_backup := '
WITH
events AS (
SELECT /*+ &&sq_fact_hints. */
       CASE h.session_state WHEN ''ON CPU'' THEN h.session_state ELSE h.wait_class||'' "''||h.event||''"'' END timed_event,
       COUNT(*) samples
  FROM dba_hist_active_sess_hist_s h,
       dba_hist_snapshot_s s
 WHERE ''&&diagnostics_pack.'' = ''Y''
   AND h.eadam_seq_id = &&eadam_seq_id.
   AND h.dbid = &&eadam_dbid.
   AND @filter_predicate@
   AND h.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
   AND s.eadam_seq_id = &&eadam_seq_id.
   AND s.dbid = &&eadam_dbid.
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 GROUP BY
       CASE h.session_state WHEN ''ON CPU'' THEN h.session_state ELSE h.wait_class||'' "''||h.event||''"'' END
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.timed_event,
       e.samples,
       ROUND(100 * e.samples / t.samples, 1) percent,
       NULL dummy_01
  FROM events e,
       total t
 WHERE ROWNUM <= &&slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT ''Others'',
       others samples,
       ROUND(100 * others / samples, 1) percent,
       NULL dummy_01
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
';
END;
/

/*****************************************************************************************/

DEF skip_pch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'ASH Top Timed Events for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'ASH Top Timed Events for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 1 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'ASH Top Timed Events for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 2 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'ASH Top Timed Events for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 3 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'ASH Top Timed Events for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 4 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'ASH Top Timed Events for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 5 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'ASH Top Timed Events for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 6 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'ASH Top Timed Events for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 7 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'ASH Top Timed Events for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 8 ');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/


