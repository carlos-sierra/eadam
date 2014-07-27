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

DEF section_name = 'Active Session History (ASH) - Top SQL';
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
       NVL(h.sql_id, ''null'') sql_id,
       COUNT(*) samples
  FROM gv_active_session_history_s h
 WHERE ''&&diagnostics_pack.'' = ''Y''
   AND eadam_seq_id = &&eadam_seq_id.
   AND @filter_predicate@
 GROUP BY
       h.sql_id
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.sql_id,
       e.samples,
       ROUND(100 * e.samples / t.samples, 1) percent,
       (SELECT v2.sql_text FROM gv_sql_s v2 WHERE v2.eadam_seq_id = &&eadam_seq_id. AND v2.sql_id = e.sql_id AND ROWNUM = 1) sql_text
  FROM events e,
       total t
 WHERE ROWNUM <= &&slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT ''Others'',
       others samples,
       ROUND(100 * others / samples, 1) percent,
       NULL sql_text
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
';
END;
/

/*****************************************************************************************/

DEF skip_pch = '';
DEF title = 'ASH Top SQL for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 1;
DEF title = 'ASH Top SQL for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 2;
DEF title = 'ASH Top SQL for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 2');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 3;
DEF title = 'ASH Top SQL for Instance 3';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 3');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 4;
DEF title = 'ASH Top SQL for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 4');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 5;
DEF title = 'ASH Top SQL for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 5');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 6;
DEF title = 'ASH Top SQL for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 6');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 7;
DEF title = 'ASH Top SQL for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.inst_id = 7');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND inst_id = 8;
DEF title = 'ASH Top SQL for Instance 8';
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
       NVL(h.sql_id, ''null'') sql_id,
       h.dbid,
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
       h.sql_id,
       h.dbid
 ORDER BY
       3 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.sql_id,
       e.samples,
       ROUND(100 * e.samples / t.samples, 1) percent,
       (SELECT DBMS_LOB.SUBSTR(s.sql_text, 1000, 1) FROM dba_hist_sqltext_s s WHERE s.eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid. AND s.sql_id = e.sql_id AND s.dbid = e.dbid AND ROWNUM = 1) sql_text
  FROM events e,
       total t
 WHERE ROWNUM <= &&slices.
   AND ROUND(100 * e.samples / t.samples, 1) > 0.1
 UNION ALL
SELECT ''Others'',
       others samples,
       ROUND(100 * others / samples, 1) percent,
       NULL sql_text
  FROM total
 WHERE others > 0
   AND ROUND(100 * others / samples, 1) > 0.1
';
END;
/

/*****************************************************************************************/

DEF skip_pch = '';
DEF skip_all = '&&is_single_instance.';
DEF title = 'ASH Top SQL for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'ASH Top SQL for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 1 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'ASH Top SQL for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 2 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'ASH Top SQL for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 3 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'ASH Top SQL for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 4 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'ASH Top SQL for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 5 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'ASH Top SQL for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 6 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'ASH Top SQL for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 7 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'ASH Top SQL for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 8 ');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF section_name = 'Active Session History (ASH) - Top Programs';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF slices = '15';
BEGIN
  :sql_text_backup := '
WITH
events AS (
SELECT /*+ &&sq_fact_hints. */
       NVL(h.program, ''null'') program,
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
       h.program
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.program,
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
DEF title = 'ASH Top Programs for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'ASH Top Programs for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 1 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'ASH Top Programs for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 2 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'ASH Top Programs for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 3 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'ASH Top Programs for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 4 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'ASH Top Programs for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 5 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'ASH Top Programs for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 6 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'ASH Top Programs for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 7 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'ASH Top Programs for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 8 ');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF section_name = 'Active Session History (ASH) - Top Modules and Actions';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF slices = '15';
BEGIN
  :sql_text_backup := '
WITH
events AS (
SELECT /*+ &&sq_fact_hints. */
       NVL(TRIM(h.module||'' ''||h.action), ''null'') module_action,
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
       TRIM(h.module||'' ''||h.action)
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT e.module_action,
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
DEF title = 'ASH Top Modules and Actions for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'ASH Top Modules and Actions for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 1 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'ASH Top Modules and Actions for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 2 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'ASH Top Modules and Actions for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 3 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'ASH Top Modules and Actions for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 4 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'ASH Top Modules and Actions for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 5 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'ASH Top Modules and Actions for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 6 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'ASH Top Modules and Actions for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 7 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'ASH Top Modules and Actions for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 8 ');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF section_name = 'Active Session History (ASH) - Top Users';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF main_table = 'DBA_HIST_ACTIVE_SESS_HIST_S';
DEF slices = '15';
BEGIN
  :sql_text_backup := '
WITH
events AS (
SELECT /*+ &&sq_fact_hints. */
       h.user_id,
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
       h.user_id
 ORDER BY
       2 DESC
),
total AS (
SELECT SUM(samples) samples,
       SUM(CASE WHEN ROWNUM > &&slices. THEN samples ELSE 0 END) others
  FROM events
)
SELECT NVL((SELECT u.username FROM dba_users u WHERE u.user_id = e.user_id AND ROWNUM = 1), ''null'') username,
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
DEF title = 'ASH Top Users for Cluster';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', '1 = 1');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 1;
DEF title = 'ASH Top Users for Instance 1';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 1 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 2;
DEF title = 'ASH Top Users for Instance 2';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 2 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 3;
DEF title = 'ASH Top Users for Instance 3';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 3 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 4;
DEF title = 'ASH Top Users for Instance 4';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 4 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 5;
DEF title = 'ASH Top Users for Instance 5';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 5 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 6;
DEF title = 'ASH Top Users for Instance 6';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 6 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 7;
DEF title = 'ASH Top Users for Instance 7';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 7 ');
@@&&skip_all.eadam36_9a_pre_one.sql

DEF skip_pch = '';
DEF skip_all = 'Y';
SELECT NULL skip_all FROM dba_hist_database_instanc_s WHERE eadam_seq_id = &&eadam_seq_id. AND ROWNUM = 1 AND instance_number = 8;
DEF title = 'ASH Top Users for Instance 8';
DEF title_suffix = '&&between_dates.';
EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'h.instance_number = 8 ');
@@&&skip_all.eadam36_9a_pre_one.sql

/*****************************************************************************************/

DEF skip_lch = 'Y';
DEF skip_pch = 'Y';

/*****************************************************************************************/

