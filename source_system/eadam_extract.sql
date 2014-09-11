-- Extracts DBA_HIST and GV$ metadata into flat files
-- Please execute connected as SYS
-- local directory must have at least 10G of free space
-- extraction types: PT (Performance Evaluation) or SP (Sizing and Provisioning)
-- Sizing and Provisioning (SP) is a subset of Performance Evaluation (PE)
-- Default parameter values are 100 days of history, and PE for extraction type
-- This scripts extracts data from DBA_HIST views, which are part of the
-- Oracle Diagnostics Pack. Same about ASH views.

SET TERM ON ECHO OFF;
CL COL;
PRO
PRO Parameter 1: (default 100) recommended: 100
PRO Days to extract 
PRO
DEF days = '&1';
PRO
PRO
PRO Parameter 2: (default PE) recommended: PE
PRO Extraction Type [ Performance Evaluation (PE) | Sizing and Provisioning (SP) ] 
PRO
DEF extraction_type = '&2';
PRO
SET TERM OFF;

VAR days NUMBER;
EXEC :days := GREATEST(TO_NUMBER(NVL(TRIM('&&days.'), '100')), 8);

VAR extraction_type VARCHAR2(2);
BEGIN
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&extraction_type.'), 1, 2)) IN ('PE', 'SP') THEN UPPER(SUBSTR(TRIM('&&extraction_type.'), 1, 2)) ELSE 'PE' END 
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
COL min_snap_id NEW_V min_snap_id;
SELECT NVL(MAX(snap_id), 0) min_snap_id
  FROM dba_hist_snapshot 
 WHERE begin_interval_time < TRUNC(SYSDATE) - :days;

-- dbid to collect
COL edb360_dbid NEW_V edb360_dbid;
SELECT dbid edb360_dbid FROM v$database;

/* ------------------------------------------------------------------------- */

SET TERM OFF ECHO OFF DEF ON FEED OFF FLU OFF HEA OFF NUM 30 LIN 32767 LONG 4000000 LONGC 4000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TIM OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF COLSEP '&&fields_delimiter.';

SET TERM ON;
PRO -> 1/26 dba_hist_xtr_control
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
PRO -> 2/26 dba_tab_columns
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
('DBA_HIST_ACTIVE_SESS_HISTORY'
,'DBA_HIST_DATABASE_INSTANCE'
,'DBA_HIST_EVENT_HISTOGRAM'     /* PE */
,'DBA_HIST_OSSTAT'              /* PE */
,'DBA_HIST_PARAMETER'
,'DBA_HIST_PGASTAT'
,'DBA_HIST_SGA'
,'DBA_HIST_SGASTAT'
,'DBA_HIST_SNAPSHOT'
,'DBA_HIST_SQL_PLAN'            /* PE */
,'DBA_HIST_SQLSTAT'             /* PE */
,'DBA_HIST_SQLTEXT'             /* PE */ 
,'DBA_HIST_SYS_TIME_MODEL'
,'DBA_HIST_SYSSTAT'
,'GV_$ACTIVE_SESSION_HISTORY'
,'GV_$LOG'
,'GV_$SQL_MONITOR'              /* PE */
,'GV_$SQL_PLAN_MONITOR'         /* PE */
,'GV_$SQL_PLAN_STATISTICS_ALL'  /* PE */
,'GV_$SQL'                      /* PE */
,'GV_$SYSTEM_PARAMETER2'
,'V_$CONTROLFILE'
,'V_$DATAFILE'                  
,'V_$TEMPFILE'
);
SPO OFF;
HOS gzip -v dba_tab_columns.txt
HOS tar -rvf &&tar_filename..tar dba_tab_columns.txt.gz
HOS rm dba_tab_columns.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 3/26 v$datafile
SET TERM OFF;
SPO v_datafile.txt;
SELECT * FROM v$datafile;
SPO OFF;
HOS gzip -v v_datafile.txt
HOS tar -rvf &&tar_filename..tar v_datafile.txt.gz
HOS rm v_datafile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 4/26 v$tempfile
SET TERM OFF;
SPO v_tempfile.txt;
SELECT * FROM v$tempfile;
SPO OFF;
HOS gzip -v v_tempfile.txt
HOS tar -rvf &&tar_filename..tar v_tempfile.txt.gz
HOS rm v_tempfile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 5/26 v$controlfile
SET TERM OFF;
SPO v_controlfile.txt;
SELECT * FROM v$controlfile;
SPO OFF;
HOS gzip -v v_controlfile.txt
HOS tar -rvf &&tar_filename..tar v_controlfile.txt.gz
HOS rm v_controlfile.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 6/26 gv$log
SET TERM OFF;
SPO gv_log.txt;
SELECT * FROM gv$log;
SPO OFF;
HOS gzip -v gv_log.txt
HOS tar -rvf &&tar_filename..tar gv_log.txt.gz
HOS rm gv_log.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 7/26 dba_hist_snapshot
SET TERM OFF;
SPO dba_hist_snapshot.txt;
SELECT * FROM dba_hist_snapshot 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_snapshot.txt
HOS tar -rvf &&tar_filename..tar dba_hist_snapshot.txt.gz
HOS rm dba_hist_snapshot.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 8/26 dba_hist_pgastat
SET TERM OFF;
SPO dba_hist_pgastat.txt;
SELECT * FROM dba_hist_pgastat 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_pgastat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_pgastat.txt.gz
HOS rm dba_hist_pgastat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 9/26 dba_hist_sgastat
SET TERM OFF;
SPO dba_hist_sgastat.txt;
SELECT * FROM dba_hist_sgastat 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sgastat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sgastat.txt.gz
HOS rm dba_hist_sgastat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 10/26 dba_hist_sysstat
SET TERM OFF;
SPO dba_hist_sysstat.txt;
SELECT * FROM dba_hist_sysstat 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sysstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sysstat.txt.gz
HOS rm dba_hist_sysstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 11/26 dba_hist_sga
SET TERM OFF;
SPO dba_hist_sga.txt;
SELECT * FROM dba_hist_sga 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_sga.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sga.txt.gz
HOS rm dba_hist_sga.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 12/26 dba_hist_database_instance
SET TERM OFF;
SPO dba_hist_database_instance.txt;
SELECT * FROM dba_hist_database_instance
WHERE dbid = &&edb360_dbid.;
SPO OFF;
HOS gzip -v dba_hist_database_instance.txt
HOS tar -rvf &&tar_filename..tar dba_hist_database_instance.txt.gz
HOS rm dba_hist_database_instance.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 13/26 gv$active_session_history
SET TERM OFF;
SPO gv_active_session_history.txt;
SELECT * FROM gv$active_session_history
WHERE sample_time > TRUNC(SYSDATE) - :days
AND (CASE 
WHEN :extraction_type = 'SP' 
AND (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum') THEN 'Y'
WHEN :extraction_type = 'SP' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v gv_active_session_history.txt
HOS tar -rvf &&tar_filename..tar gv_active_session_history.txt.gz
HOS rm gv_active_session_history.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 14/26 gv$system_parameter2
SET TERM OFF;
SPO gv_system_parameter2.txt;
SELECT * FROM gv$system_parameter2
WHERE (CASE 
WHEN :extraction_type = 'SP' AND name in ('instance_number', 'instance_name', 
'memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 
'pga_aggregate_target', 'cpu_count') THEN 'Y'
WHEN :extraction_type = 'SP' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v gv_system_parameter2.txt
HOS tar -rvf &&tar_filename..tar gv_system_parameter2.txt.gz
HOS rm gv_system_parameter2.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 15/26 dba_hist_active_sess_history
SET TERM OFF;
SPO dba_hist_active_sess_history.txt;
SELECT * FROM dba_hist_active_sess_history 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.
AND (CASE 
WHEN :extraction_type = 'SP' 
AND (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum') THEN 'Y'
WHEN :extraction_type = 'SP' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_active_sess_history.txt
HOS tar -rvf &&tar_filename..tar dba_hist_active_sess_history.txt.gz
HOS rm dba_hist_active_sess_history.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 16/26 dba_hist_parameter
SET TERM OFF;
SPO dba_hist_parameter.txt;
SELECT * FROM dba_hist_parameter 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.
AND (CASE 
WHEN :extraction_type = 'SP' 
AND parameter_name IN ('instance_number', 'instance_name', 
'memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 
'pga_aggregate_target', 'cpu_count') THEN 'Y'
WHEN :extraction_type = 'SP' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_parameter.txt
HOS tar -rvf &&tar_filename..tar dba_hist_parameter.txt.gz
HOS rm dba_hist_parameter.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 17/26 dba_hist_sys_time_model
SET TERM OFF;
SPO dba_hist_sys_time_model.txt;
SELECT * FROM dba_hist_sys_time_model 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id. 
AND (CASE 
WHEN :extraction_type = 'SP' 
AND stat_name IN ('background cpu time', 'DB CPU') THEN 'Y'
WHEN :extraction_type = 'SP' THEN 'N'
ELSE 'Y' END) = 'Y';
SPO OFF;
HOS gzip -v dba_hist_sys_time_model.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sys_time_model.txt.gz
HOS rm dba_hist_sys_time_model.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 18/26 dba_hist_osstat
SET TERM OFF;
SPO dba_hist_osstat.txt;
SELECT * FROM dba_hist_osstat 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id. 
AND :extraction_type = ('PE');
SPO OFF;
HOS gzip -v dba_hist_osstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_osstat.txt.gz
HOS rm dba_hist_osstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 19/26 dba_hist_sqlstat
SET TERM OFF;
SPO dba_hist_sqlstat.txt;
SELECT * FROM dba_hist_sqlstat 
WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id. 
AND :extraction_type = ('PE');
SPO OFF;
HOS gzip -v dba_hist_sqlstat.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sqlstat.txt.gz
HOS rm dba_hist_sqlstat.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 20/26 dba_hist_sqltext
SET TERM OFF;
SPO dba_hist_sqltext.txt;
WITH extracted_sql_id AS (
SELECT /*+ materialize no_merge */
       DISTINCT sql_id 
  FROM dba_hist_sqlstat
 WHERE dbid = &&edb360_dbid. AND snap_id > &&min_snap_id. 
   AND :extraction_type = ('PE'))
SELECT h.* 
  FROM dba_hist_sqltext h,
       extracted_sql_id s
 WHERE NVL(DBMS_LOB.instr(h.sql_text, '&&fields_delimiter.'), 0) = 0
   AND :extraction_type = ('PE')
   AND h.dbid = &&edb360_dbid. 
   AND s.sql_id = h.sql_id;
SPO OFF;
HOS gzip -v dba_hist_sqltext.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sqltext.txt.gz
HOS rm dba_hist_sqltext.txt.gz
   
/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 21/26 gv$sql_monitor
SET TERM OFF;
SPO gv_sql_monitor.txt;
SELECT * FROM gv$sql_monitor WHERE :extraction_type = ('PE')
AND sql_exec_start > TRUNC(SYSDATE) - :days;
SPO OFF;
HOS gzip -v gv_sql_monitor.txt
HOS tar -rvf &&tar_filename..tar gv_sql_monitor.txt.gz
HOS rm gv_sql_monitor.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 22/26 gv$sql_plan_monitor
SET TERM OFF;
SPO gv_sql_plan_monitor.txt;
SELECT * FROM gv$sql_plan_monitor WHERE :extraction_type = ('PE')
AND sql_exec_start > TRUNC(SYSDATE) - :days;
SPO OFF;
HOS gzip -v gv_sql_plan_monitor.txt
HOS tar -rvf &&tar_filename..tar gv_sql_plan_monitor.txt.gz
HOS rm gv_sql_plan_monitor.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 23/26 gv$sql
SET TERM OFF;
SPO gv_sql.txt;
SELECT * FROM gv$sql WHERE :extraction_type = ('PE')
   AND last_active_time > TRUNC(SYSDATE) - :days
   AND (sql_fulltext IS NULL OR DBMS_LOB.instr(sql_fulltext, '&&fields_delimiter.') = 0);
SPO OFF;
HOS gzip -v gv_sql.txt
HOS tar -rvf &&tar_filename..tar gv_sql.txt.gz
HOS rm gv_sql.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 24/26 gv$sql_plan_statistics_all
SET TERM OFF;
SPO gv_sql_plan_statistics_all.txt;
SELECT * FROM gv$sql_plan_statistics_all WHERE :extraction_type = ('PE')
   AND timestamp > TRUNC(SYSDATE) - :days;
   AND (filter_predicates IS NULL OR INSTR(filter_predicates, '&&fields_delimiter.') = 0);
SPO OFF;
HOS gzip -v gv_sql_plan_statistics_all.txt
HOS tar -rvf &&tar_filename..tar gv_sql_plan_statistics_all.txt.gz
HOS rm gv_sql_plan_statistics_all.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 25/26 dba_hist_sql_plan
SET TERM OFF;
SPO dba_hist_sql_plan.txt;
WITH extracted_sql_id AS (
SELECT /*+ materialize no_merge */
       DISTINCT sql_id 
  FROM dba_hist_sqlstat
 WHERE :extraction_type = ('PE')
   AND dbid = &&edb360_dbid. AND snap_id > &&min_snap_id. )
SELECT h.* 
  FROM dba_hist_sql_plan h,
       extracted_sql_id s
 WHERE :extraction_type = ('PE')
   AND h.dbid = &&edb360_dbid.
   AND s.sql_id = h.sql_id;
SPO OFF;
HOS gzip -v dba_hist_sql_plan.txt
HOS tar -rvf &&tar_filename..tar dba_hist_sql_plan.txt.gz
HOS rm dba_hist_sql_plan.txt.gz

/* ------------------------------------------------------------------------- */

SET TERM ON;
PRO -> 26/26 dba_hist_event_histogram
SET TERM OFF;
SPO dba_hist_event_histogram.txt;
SELECT * 
  FROM dba_hist_event_histogram 
 WHERE :extraction_type = ('PE') 
   AND dbid = &&edb360_dbid. AND snap_id > &&min_snap_id.;
SPO OFF;
HOS gzip -v dba_hist_event_histogram.txt
HOS tar -rvf &&tar_filename..tar dba_hist_event_histogram.txt.gz
HOS rm dba_hist_event_histogram.txt.gz

/* ------------------------------------------------------------------------- */

UNDEF 1 2
HOS tar -tvf &&tar_filename..tar
HOS ls -lt &&tar_filename..tar
SET TERM ON ECHO OFF DEF ON FEED ON FLU ON HEA ON NUM 10 LIN 80 LONG 80 LONGC 80 NEWP 1 PAGES 14 SHOW OFF SQLC MIX TAB OFF TRIMS OFF VER ON TIM OFF TIMI OFF ARRAY 15 SQLP SQL> BLO . RECSEP WR COLSEP '';
PRO send &&tar_filename..tar to requestor
