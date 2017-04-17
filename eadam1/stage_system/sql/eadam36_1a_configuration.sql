DEF section_name = 'Database Configuration';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF title = 'Identification';
DEF main_table = 'DBA_HIST_XTR_CONTROL_S';
BEGIN
  :sql_text := '
SELECT *
  FROM dba_hist_xtr_control_s
 WHERE eadam_seq_id = &&eadam_seq_id.
';
END;				
/
@@eadam36_9a_pre_one.sql

DEF title = 'Database and Instance History';
DEF main_table = 'DBA_HIST_DATABASE_INSTANC_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM dba_hist_database_instanc_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 ORDER BY
       dbid,
       instance_number,
       startup_time DESC
';
END;				
/
@@&&skip_diagnostics.eadam36_9a_pre_one.sql

DEF title = 'Modified Parameters';
DEF main_table = 'GV_SYSTEM_PARAMETER2_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM gv_system_parameter2_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND ismodified = ''MODIFIED''
 ORDER BY
       name,
       inst_id,
       ordinal
';
END;
/
@@eadam36_9a_pre_one.sql

DEF title = 'Non-default Parameters';
DEF main_table = 'GV_SYSTEM_PARAMETER2_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM gv_system_parameter2_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND isdefault = ''FALSE''
 ORDER BY
       name,
       inst_id,
       ordinal
';
END;
/
@@eadam36_9a_pre_one.sql

DEF title = 'All Parameters';
DEF main_table = 'GV_SYSTEM_PARAMETER2_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM gv_system_parameter2_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 ORDER BY
       name,
       inst_id,
       ordinal
';
END;
/
@@eadam36_9a_pre_one.sql
