-- Extracts DBA_HIST and GV$ metadata into flat files
-- Please execute connected as SYS
-- local directory must have enough space (proportional to SYSAUX size)
-- extraction types: C is a subset of S. S is a subset of A.  C < S < A

SET TERM ON ECHO OFF;
CL COL;
PRO
PRO Parameter 1:
PRO Days to extract (default 100):
PRO
DEF days = '&1';
PRO
PRO
PRO Parameter 2:
PRO Extraction Type [ (A)ll | (S)ql | (C)apacity ] (default S):
PRO
DEF extraction_type = '&2';
PRO
SET TERM OFF;

VAR days NUMBER;
EXEC :days := TO_NUMBER(NVL(TRIM('&&days.'), '100'));

VAR extraction_type VARCHAR2(1);
BEGIN
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&extraction_type.'), 1, 1)) IN ('A', 'S', 'C') THEN UPPER(SUBSTR(TRIM('&&extraction_type.'), 1, 1)) ELSE 'S' END 
INTO :extraction_type FROM DUAL;
END;
/

DEF date_mask = 'YYYY-MM-DD/HH24:MI:SS';
DEF timestamp_mask = 'YYYY-MM-DD/HH24:MI:SS.FF6';
DEF fields_delimiter = '<,>';

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_DATE_FORMAT = '&&date_mask.';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = '&&timestamp_mask.';

/* ------------------------------------------------------------------------- */

-- timestamp for record keeping control
COL current_time NEW_V current_time;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') current_time FROM DUAL;

-- timestamp for file naming
COL file_creation_time NEW_V file_creation_time NOPRI FOR A20;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MI') file_creation_time FROM DUAL;

-- get database name (up to 10, stop before first '.', no special characters)
COL database_name_short NEW_V database_name_short FOR A10 NOPRI;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'DB_NAME'), 1, 10)) database_name_short FROM DUAL;
SELECT SUBSTR('&&&&database_name_short.', 1, INSTR('&&&&database_name_short..', '.') - 1) database_name_short FROM DUAL;
SELECT TRANSLATE('&&&&database_name_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') database_name_short FROM DUAL;

-- get host name (up to 30, stop before first '.', no special characters)
COL host_name_short NEW_V host_name_short FOR A30 NOPRI;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, 30)) host_name_short FROM DUAL;
SELECT SUBSTR('&&&&host_name_short.', 1, INSTR('&&&&host_name_short..', '.') - 1) host_name_short FROM DUAL;
SELECT TRANSLATE('&&&&host_name_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') host_name_short FROM DUAL;

-- compressed file name
DEF tar_filename = 'eadam_&&database_name_short._&&host_name_short._&&file_creation_time.';

-- lower limit for snap_id to collect
COL min_snap_id NEW_V min_snap_id NOPRI;
SELECT NVL(MAX(snap_id), 0) min_snap_id
  FROM dba_hist_snapshot 
 WHERE begin_interval_time < TRUNC(SYSDATE) - :days;

/* ------------------------------------------------------------------------- */

SET TERM OFF ECHO OFF DEF ON FEED OFF FLU OFF HEA OFF NUM 30 LIN 32767 LONG 4000000 LONGC 4000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TIM OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF COLSEP '&&fields_delimiter.';

SET TERM ON;
PRO dba_hist_xtr_control
SET TERM OFF;
SPO dba_hist_xtr_control.txt;
SELECT d.dbid, d.name dbname, d.db_unique_name, d.platform_name,
       i.instance_number, i.instance_name, i.host_name, i.version,
       '&&current_time.' current_sysdate
  FROM v$database d,
       v$instance i;
SPO OFF;
HOS gzip -v dba_hist_xtr_control.txt
HOS tar -cvf &&tar_filename..tar dba_hist_xtr_control.txt.gz
HOS rm dba_hist_xtr_control.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_tab_columns
SET TERM OFF;
SPO dba_tab_columns.txt;
SELECT table_name,
       column_id,
       column_name,
       data_type,
       data_length,
       data_precision,
       data_scale
  FROM dba_tab_columns
 WHERE owner = 'SYS'
   AND table_name IN 
('V_$DATAFILE'
,'V_$TEMPFILE'
,'V_$CONTROLFILE'
,'GV_$LOG'
,'GV_$ACTIVE_SESSION_HISTORY'
,'GV_$SYSTEM_PARAMETER2'
,'GV_$SQL'
,'GV_$SQL_MONITOR'
,'GV_$SQL_PLAN_MONITOR'
,'GV_$SQL_PLAN_STATISTICS_ALL'
,'DBA_HIST_SNAPSHOT'
,'DBA_HIST_OSSTAT'
,'DBA_HIST_SYS_TIME_MODEL'
,'DBA_HIST_PGASTAT'
,'DBA_HIST_SYSSTAT'
,'DBA_HIST_SYSTEM_EVENT'
,'DBA_HIST_SQLSTAT'
,'DBA_HIST_SERVICE_STAT'
,'DBA_HIST_SGA'
,'AUDIT_ACTIONS'
,'DBA_HIST_EVENT_HISTOGRAM'
,'DBA_HIST_DATABASE_INSTANCE'
,'DBA_HIST_IOSTAT_DETAIL'
,'DBA_HIST_IOSTAT_FILETYPE'
,'DBA_HIST_IOSTAT_FUNCTION'
,'DBA_HIST_SGASTAT'
,'DBA_HIST_ACTIVE_SESS_HISTORY'
,'DBA_HIST_SQLTEXT'
,'DBA_HIST_SQL_PLAN'
,'DBA_HIST_PARAMETER'
);
SPO OFF;
HOS gzip -v dba_tab_columns.txt
HOS tar -rvf &&tar_filename..tar dba_tab_columns.txt.gz
HOS rm dba_tab_columns.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO v$datafile
SET TERM OFF;
SPO v_datafile.txt;
SELECT * FROM v$datafile;
SPO OFF;
HOS gzip -v v_datafile.txt
HOS tar -rvf &&tar_filename..tar v_datafile.txt.gz
HOS rm v_datafile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO v$tempfile
SET TERM OFF;
SPO v_tempfile.txt;
SELECT * FROM v$tempfile;
SPO OFF;
HOS gzip -v v_tempfile.txt
HOS tar -rvf &&tar_filename..tar v_tempfile.txt.gz
HOS rm v_tempfile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO v$controlfile
SET TERM OFF;
SPO v_controlfile.txt;
SELECT * FROM v$controlfile;
SPO OFF;
HOS gzip -v v_controlfile.txt
HOS tar -rvf &&tar_filename..tar v_controlfile.txt.gz
HOS rm v_controlfile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$log
SET TERM OFF;
SPO gv_log.txt;
SELECT * FROM gv$log;
SPO OFF;
HOS gzip -v gv_log.txt
HOS tar -rvf &&tar_filename..tar gv_log.txt.gz
HOS rm gv_log.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_snapshot
SET TERM OFF;
SPO dba_hist_snapshot.txt;
SELECT * FROM dba_hist_snapshot WHERE snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_snapshot.txt
HOS tar -rvf &&tar_filename..tar dba_hist_snapshot.txt.gz
HOS rm dba_hist_snapshot.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_pgastat
SET TERM OFF;
SPO dba_hist_pgastat.txt;
SELECT * FROM dba_hist_pgastat WHERE snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_pgastat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_pgastat.txt.gz
HOS rm dba_hist_pgastat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sysstat
SET TERM OFF;
SPO dba_hist_sysstat.txt;
SELECT * FROM dba_hist_sysstat WHERE snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sysstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sysstat.txt.gz
HOS rm dba_hist_sysstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sga
SET TERM OFF;
SPO dba_hist_sga.txt;
SELECT * FROM dba_hist_sga WHERE snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sga.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sga.txt.gz
HOS rm dba_hist_sga.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_database_instance
SET TERM OFF;
SPO dba_hist_database_instance.txt;
SELECT * FROM dba_hist_database_instance;
SPO OFF;
HOS gzip -v dba_hist_database_instance.txt
HOS tar -rvf &&tar_filename..tar dba_hist_database_instance.txt.gz
HOS rm dba_hist_database_instance.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$active_session_history
SET TERM OFF;
SPO gv_active_session_history.txt;
SELECT * FROM gv$active_session_history
WHERE (CASE 
WHEN :extraction_type = 'C' 
AND (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum') THEN 'Y'
WHEN :extraction_type = 'C' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v gv_active_session_history.txt
HOS tar -rvf &&tar_filename..tar gv_active_session_history.txt.gz
HOS rm gv_active_session_history.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$system_parameter2
SET TERM OFF;
SPO gv_system_parameter2.txt;
SELECT * FROM gv$system_parameter2
WHERE (CASE 
WHEN :extraction_type = 'C' AND name in ('instance_number', 'instance_name', 
'memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 
'pga_aggregate_target') THEN 'Y'
WHEN :extraction_type = 'C' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v gv_system_parameter2.txt
HOS tar -rvf &&tar_filename..tar gv_system_parameter2.txt.gz
HOS rm gv_system_parameter2.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_active_sess_history
SET TERM OFF;
SPO dba_hist_active_sess_history.txt;
SELECT * FROM dba_hist_active_sess_history 
WHERE snap_id > &&min_snap_id.
AND (CASE 
WHEN :extraction_type = 'C' 
AND (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum') THEN 'Y'
WHEN :extraction_type = 'C' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_active_sess_history.txt
HOS tar -rvf &&tar_filename..tar dba_hist_active_sess_history.txt.gz
HOS rm dba_hist_active_sess_history.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_parameter
SET TERM OFF;
SPO dba_hist_parameter.txt;
SELECT * FROM dba_hist_parameter 
WHERE snap_id > &&min_snap_id.
AND (CASE 
WHEN :extraction_type = 'C' 
AND parameter_name IN ('memory_target', 'memory_max_target', 'sga_target', 
'sga_max_size', 'pga_aggregate_target') THEN 'Y'
WHEN :extraction_type = 'C' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_parameter.txt
HOS tar -rvf &&tar_filename..tar dba_hist_parameter.txt.gz
HOS rm dba_hist_parameter.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sys_time_model
SET TERM OFF;
SPO dba_hist_sys_time_model.txt;
SELECT * FROM dba_hist_sys_time_model 
WHERE snap_id > &&min_snap_id. 
AND (CASE 
WHEN :extraction_type = 'C' 
AND stat_name IN ('background cpu time', 'DB CPU') THEN 'Y'
WHEN :extraction_type = 'C' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_sys_time_model.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sys_time_model.txt.gz
HOS rm dba_hist_sys_time_model.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_osstat
SET TERM OFF;
SPO dba_hist_osstat.txt;
SELECT * FROM dba_hist_osstat 
WHERE snap_id > &&min_snap_id. 
AND :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v dba_hist_osstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_osstat.txt.gz
HOS rm dba_hist_osstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_system_event
SET TERM OFF;
SPO dba_hist_system_event.txt;
SELECT * FROM dba_hist_system_event 
WHERE snap_id > &&min_snap_id. 
AND :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v dba_hist_system_event.txt
HOS tar -rvf &&tar_filename..tar dba_hist_system_event.txt.gz
HOS rm dba_hist_system_event.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sqlstat
SET TERM OFF;
SPO dba_hist_sqlstat.txt;
SELECT * FROM dba_hist_sqlstat 
WHERE snap_id > &&min_snap_id. 
AND :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v dba_hist_sqlstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sqlstat.txt.gz
HOS rm dba_hist_sqlstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_service_stat
SET TERM OFF;
SPO dba_hist_service_stat.txt;
SELECT * FROM dba_hist_service_stat 
WHERE snap_id > &&min_snap_id. 
AND :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v dba_hist_service_stat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_service_stat.txt.gz
HOS rm dba_hist_service_stat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO audit_actions
SET TERM OFF;
SPO audit_actions.txt;
SELECT * FROM audit_actions WHERE :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip audit_actions.txt
HOS tar -rvf &&tar_filename..tar audit_actions.txt.gz
HOS rm audit_actions.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sqltext
SET TERM OFF;
SPO dba_hist_sqltext.txt;
WITH extracted_sql_id AS (
SELECT /*+ materialize result_cache */
       DISTINCT dbid, sql_id 
  FROM dba_hist_sqlstat
 WHERE snap_id > &&min_snap_id. 
   AND :extraction_type IN ('S', 'A'))
SELECT h.* 
  FROM dba_hist_sqltext h,
       extracted_sql_id s
 WHERE NVL(DBMS_LOB.instr(h.sql_text, '&&fields_delimiter.'), 0) = 0
   AND :extraction_type IN ('S', 'A')
   AND s.dbid = h.dbid
   AND s.sql_id = h.sql_id;
SPO OFF;
HOS gzip -v dba_hist_sqltext.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sqltext.txt.gz
HOS rm dba_hist_sqltext.txt.gz
   
/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$sql_monitor
SET TERM OFF;
SPO gv_sql_monitor.txt;
SELECT * FROM gv$sql_monitor WHERE :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v gv_sql_monitor.txt
HOS tar -rvf &&tar_filename..tar gv_sql_monitor.txt.gz
HOS rm gv_sql_monitor.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$sql_plan_monitor
SET TERM OFF;
SPO gv_sql_plan_monitor.txt;
SELECT * FROM gv$sql_plan_monitor WHERE :extraction_type IN ('S', 'A');
SPO OFF;
HOS gzip -v gv_sql_plan_monitor.txt
HOS tar -rvf &&tar_filename..tar gv_sql_plan_monitor.txt.gz
HOS rm gv_sql_plan_monitor.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$sql
SET TERM OFF;
SPO gv_sql.txt;
SELECT * FROM gv$sql s WHERE :extraction_type IN ('S', 'A')
   AND NVL(INSTR(s.sql_text, '&&fields_delimiter.'), 0) = 0
   AND NVL(DBMS_LOB.instr(s.sql_fulltext, '&&fields_delimiter.'), 0) = 0;
SPO OFF;
HOS gzip -v gv_sql.txt
HOS tar -rvf &&tar_filename..tar gv_sql.txt.gz
HOS rm gv_sql.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO gv$sql_plan_statistics_all
SET TERM OFF;
SPO gv_sql_plan_statistics_all.txt;
WITH extracted_sql_id AS (
SELECT /*+ materialize result_cache */
       DISTINCT inst_id, sql_id 
  FROM gv$sql_monitor
 WHERE :extraction_type IN ('S', 'A'))
SELECT * 
  FROM gv$sql_plan_statistics_all s,
       extracted_sql_id m
 WHERE :extraction_type IN ('S', 'A')
   AND s.inst_id = m.inst_id
   AND s.sql_id = m.sql_id
   AND NVL(INSTR(s.filter_predicates, '&&fields_delimiter.'), 0) = 0;
SPO OFF;
HOS gzip -v gv_sql_plan_statistics_all.txt
HOS tar -rvf &&tar_filename..tar gv_sql_plan_statistics_all.txt.gz
HOS rm gv_sql_plan_statistics_all.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sql_plan
SET TERM OFF;
SPO dba_hist_sql_plan.txt;
WITH extracted_sql_id AS (
SELECT /*+ materialize result_cache */
       DISTINCT dbid, sql_id 
  FROM dba_hist_sqlstat
 WHERE :extraction_type IN ('S', 'A')
   AND snap_id > &&min_snap_id. )
SELECT h.* 
  FROM dba_hist_sql_plan h,
       extracted_sql_id s
 WHERE :extraction_type IN ('S', 'A')
   AND s.dbid = h.dbid
   AND s.sql_id = h.sql_id;
SPO OFF;
HOS gzip -v dba_hist_sql_plan.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sql_plan.txt.gz
HOS rm dba_hist_sql_plan.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_event_histogram
SET TERM OFF;
SPO dba_hist_event_histogram.txt;
SELECT * 
  FROM dba_hist_event_histogram 
 WHERE :extraction_type IN ('A') 
   AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_event_histogram.txt
HOS tar -rvf &&tar_filename..tar dba_hist_event_histogram.txt.gz
HOS rm dba_hist_event_histogram.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_iostat_detail
SET TERM OFF;
SPO dba_hist_iostat_detail.txt;
SELECT * 
  FROM dba_hist_iostat_detail
 WHERE :extraction_type IN ('A')
   AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_iostat_detail.txt
HOS tar -rvf &&tar_filename..tar dba_hist_iostat_detail.txt.gz
HOS rm dba_hist_iostat_detail.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_iostat_filetype
SET TERM OFF;
SPO dba_hist_iostat_filetype.txt;
SELECT * 
  FROM dba_hist_iostat_filetype
 WHERE :extraction_type IN ('A')
   AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_iostat_filetype.txt
HOS tar -rvf &&tar_filename..tar dba_hist_iostat_filetype.txt.gz
HOS rm dba_hist_iostat_filetype.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_iostat_function
SET TERM OFF;
SPO dba_hist_iostat_function.txt;
SELECT * 
  FROM dba_hist_iostat_function
 WHERE :extraction_type IN ('A')
   AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_iostat_function.txt
HOS tar -rvf &&tar_filename..tar dba_hist_iostat_function.txt.gz
HOS rm dba_hist_iostat_function.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO dba_hist_sgastat
SET TERM OFF;
SPO dba_hist_sgastat.txt;
SELECT * 
  FROM dba_hist_sgastat
 WHERE :extraction_type IN ('A')
   AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sgastat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sgastat.txt.gz
HOS rm dba_hist_sgastat.txt.gz

/* ------------------------------------------------------------------------- */

UNDEF 1 2
HOS tar -tvf &&tar_filename..tar
HOS ls -lt &&tar_filename..tar
SET TERM ON ECHO OFF DEF ON FEED ON FLU ON HEA ON NUM 10 LIN 80 LONG 80 LONGC 80 NEWP 1 PAGES 14 SHOW OFF SQLC MIX TAB OFF TRIMS OFF VER ON TIM OFF TIMI OFF ARRAY 15 SQLP SQL> BLO . RECSEP WR COLSEP '';
PRO send &&tar_filename..tar to requestor
