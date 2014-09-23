-- Merges Two Sequences

SET TERM ON ECHO OFF;
-- list
COL seq FOR 999;
COL source FOR A9;
COL db_name_id FOR A20;
COL version FOR A10;
COL captured FOR A8;
COL host_nm FOR A30 HEA "HOST_NAME";
SELECT eadam_seq_id seq,
       CASE WHEN eadam_seq_id_1 IS NOT NULL THEN eadam_seq_id_1||','||eadam_seq_id_2 END source,
       dbname||'('||dbid||')' db_name_id,
       SUBSTR(host_name, 1, 30) host_nm,
       version,
       SUBSTR(capture_time, 1, 8) captured
  FROM dba_hist_xtr_control_s
 ORDER BY 1;
PRO
PRO Parameter 1:
PRO EADAM_SEQ_ID_1:
PRO
DEF eadam_seq_id_1 = '&1';
PRO
PRO Parameter 2:
PRO EADAM_SEQ_ID_2:
PRO
DEF eadam_seq_id_2 = '&2';
PRO
SET TERM OFF;

-- 1st when null then merge is actually a simple copy, if -2 then skip merge
VAR eadam_seq_id_1 NUMBER;
EXEC :eadam_seq_id_1 := TO_NUMBER(NVL('&&eadam_seq_id_1.', '-1'));

-- 2nd has to be higher number than 1st
VAR eadam_seq_id_2 NUMBER;
EXEC :eadam_seq_id_2 := TO_NUMBER(NVL('&&eadam_seq_id_2.', '-1'));

COL eadam_seq_id_3 NEW_V eadam_seq_id_3;
SELECT eadam_seq.NEXTVAL eadam_seq_id_3 FROM DUAL WHERE :eadam_seq_id_2 > :eadam_seq_id_1 AND :eadam_seq_id_1 > -2;
VAR eadam_seq_id_3 NUMBER;
EXEC :eadam_seq_id_3 := TO_NUMBER(NVL('&&eadam_seq_id_3.', '-3'));

COL current_time NEW_V current_time;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') current_time FROM DUAL;

SET TERM ON;

/* ------------------------------------------------------------------------- */

DELETE sql_log;
PRO merging two sequences
SET SERVEROUT ON;
DECLARE
  l_cols VARCHAR2(32767);
  l_sql VARCHAR2(32767);
  l_error VARCHAR2(4000);
  l_count INTEGER;
BEGIN
  IF :eadam_seq_id_2 > :eadam_seq_id_1 AND :eadam_seq_id_1 > -2 THEN
    FOR i IN (SELECT table_name,
                     CASE SUM(CASE column_name WHEN 'SNAP_ID' THEN 1 ELSE 0 END) WHEN 1 THEN 'Y' ELSE 'N' END contains_snap_id,
                     CASE SUM(CASE column_name WHEN 'INSTANCE_NUMBER' THEN 1 ELSE 0 END) WHEN 1 THEN 'Y' ELSE 'N' END contains_instance_number
                FROM user_tab_columns
               WHERE (table_name LIKE 'DBA!_%!_S' ESCAPE '!' OR table_name LIKE 'GV!_%!_S' ESCAPE '!' OR table_name LIKE 'V!_%!_S' ESCAPE '!')
                 AND table_name NOT IN ('DBA_HIST_XTR_CONTROL_S')
               GROUP BY
                     table_name
               ORDER BY
                     table_name)
    LOOP
      -- prepares column list
      l_cols := '  :eadam_seq_id_3'||CHR(10)||
                ', :eadam_seq_id_x'||CHR(10);
      FOR j IN (SELECT column_name
                  FROM user_tab_columns 
                 WHERE table_name = i.table_name
                   AND column_name NOT IN ('EADAM_SEQ_ID', 'EADAM_SEQ_ID_SRC')
                 ORDER BY
                       column_id)
      LOOP
        l_cols := l_cols||', '||j.column_name||CHR(10);
      END LOOP;
      
      -- copies first the newest set
      l_sql := 'INSERT INTO '||LOWER(i.table_name)||CHR(10)||
      'SELECT '||CHR(10)||l_cols||
      'FROM '||LOWER(i.table_name)||CHR(10)||
      'WHERE eadam_seq_id = :eadam_seq_id_x';
      INSERT INTO sql_log VALUES (l_sql);
      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN :eadam_seq_id_3, :eadam_seq_id_2, :eadam_seq_id_2;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM;
          DBMS_OUTPUT.PUT_LINE(i.table_name||': '||l_error);
          INSERT INTO sql_error VALUES (:eadam_seq_id_3, SYSDATE, i.table_name||': '||l_error, l_sql);
      END;
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||LOWER(i.table_name)||' WHERE eadam_seq_id = :eadam_seq_id' INTO l_count USING IN :eadam_seq_id_3;
      DBMS_OUTPUT.PUT_LINE(RPAD(i.table_name, 30)||': '||l_count);
      
      -- merges then the oldest set
      IF i.contains_snap_id = 'Y' AND i.contains_instance_number = 'Y' THEN
        l_sql := l_sql||' AND (snap_id, dbid, instance_number) NOT IN (SELECT snap_id, dbid, instance_number FROM dba_hist_snapshot_s WHERE eadam_seq_id = :eadam_seq_id_2 AND snap_id IS NOT NULL AND dbid IS NOT NULL AND instance_number IS NOT NULL)';
      ELSIF i.table_name = 'DBA_HIST_DATABASE_INSTANC_S' THEN
        l_sql := l_sql||' AND (dbid, instance_number, startup_time) NOT IN (SELECT dbid, instance_number, startup_time FROM dba_hist_database_instanc_s WHERE eadam_seq_id = :eadam_seq_id_2 AND dbid IS NOT NULL AND instance_number IS NOT NULL AND startup_time IS NOT NULL)';
      ELSIF i.table_name = 'DBA_HIST_SQLTEXT_S' THEN
        l_sql := l_sql||' AND (dbid, sql_id) NOT IN (SELECT dbid, sql_id FROM dba_hist_sqltext_s WHERE eadam_seq_id = :eadam_seq_id_2 AND dbid IS NOT NULL AND sql_id IS NOT NULL)';
      ELSIF i.table_name = 'DBA_HIST_SQL_PLAN_S' THEN
        l_sql := l_sql||' AND (dbid, sql_id, plan_hash_value, id) NOT IN (SELECT dbid, sql_id, plan_hash_value, id FROM dba_hist_sql_plan_s WHERE eadam_seq_id = :eadam_seq_id_2 AND dbid IS NOT NULL AND sql_id IS NOT NULL AND plan_hash_value IS NOT NULL AND id IS NOT NULL)';
      ELSIF i.table_name = 'DBA_HIST_TBSPC_SPACE_USAG_S' THEN
        l_sql := l_sql||' AND (snap_id, dbid, tablespace_id) NOT IN (SELECT snap_id, dbid, tablespace_id FROM dba_hist_tbspc_space_usag_s WHERE eadam_seq_id = :eadam_seq_id_2 AND snap_id IS NOT NULL AND dbid IS NOT NULL AND tablespace_id IS NOT NULL)';
      ELSIF i.table_name = 'DBA_TABLESPACES_S' THEN
        l_sql := l_sql||' AND tablespace_name NOT IN (SELECT tablespace_name FROM dba_tablespaces_s WHERE eadam_seq_id = :eadam_seq_id_2 AND tablespace_name IS NOT NULL)';
      ELSIF i.table_name = 'DBA_TAB_COLUMNS_S' THEN
        l_sql := l_sql||' AND (table_name, column_id) NOT IN (SELECT table_name, column_id FROM dba_tab_columns_s WHERE eadam_seq_id = :eadam_seq_id_2 AND table_name IS NOT NULL AND column_id IS NOT NULL)';
      ELSIF i.table_name = 'GV_ACTIVE_SESSION_HISTORY_S' THEN
        l_sql := l_sql||' AND (inst_id, sample_id, session_id, sql_id) NOT IN (SELECT inst_id, sample_id, session_id, sql_id FROM gv_active_session_history_s WHERE eadam_seq_id = :eadam_seq_id_2 AND inst_id IS NOT NULL AND sample_id IS NOT NULL AND session_id IS NOT NULL AND sql_id IS NOT NULL)';
      ELSIF i.table_name = 'GV_LOG_S' THEN
        l_sql := l_sql||' AND (inst_id, group#, thread#, sequence#) NOT IN (SELECT inst_id, group#, thread#, sequence# FROM gv_log_s WHERE eadam_seq_id = :eadam_seq_id_2 AND inst_id IS NOT NULL AND group# IS NOT NULL AND thread# IS NOT NULL AND sequence# IS NOT NULL)';
      ELSIF i.table_name = 'GV_SQL_MONITOR_S' THEN
        l_sql := l_sql||' AND key NOT IN (SELECT key FROM gv_sql_monitor_s WHERE eadam_seq_id = :eadam_seq_id_2 AND key IS NOT NULL)';
      ELSIF i.table_name = 'GV_SQL_PLAN_MONITOR_S' THEN
        l_sql := l_sql||' AND (key, sql_child_address, plan_line_id) NOT IN (SELECT key, sql_child_address, plan_line_id FROM gv_sql_plan_monitor_s WHERE eadam_seq_id = :eadam_seq_id_2 AND key IS NOT NULL AND sql_child_address IS NOT NULL AND plan_line_id IS NOT NULL)';
      ELSIF i.table_name = 'GV_SQL_PLAN_STATISTICS_AL_S' THEN
        l_sql := l_sql||' AND (inst_id, sql_id, child_number, id, elapsed_time) NOT IN (SELECT inst_id, sql_id, child_number, id, elapsed_time FROM gv_sql_plan_statistics_al_s WHERE eadam_seq_id = :eadam_seq_id_2 AND inst_id IS NOT NULL AND sql_id IS NOT NULL AND child_number IS NOT NULL AND id IS NOT NULL AND elapsed_time IS NOT NULL)';
      ELSIF i.table_name = 'GV_SQL_S' THEN
        l_sql := l_sql||' AND (inst_id, sql_id, child_number, elapsed_time) NOT IN (SELECT inst_id, sql_id, child_number, elapsed_time FROM gv_sql_s WHERE eadam_seq_id = :eadam_seq_id_2 AND inst_id IS NOT NULL AND sql_id IS NOT NULL AND child_number IS NOT NULL AND elapsed_time IS NOT NULL)';
      ELSIF i.table_name = 'GV_SYSTEM_PARAMETER2_S' THEN
        l_sql := l_sql||' AND (inst_id, name, ordinal, value) NOT IN (SELECT inst_id, name, ordinal, value FROM gv_system_parameter2_s WHERE eadam_seq_id = :eadam_seq_id_2 AND inst_id IS NOT NULL AND name IS NOT NULL AND ordinal IS NOT NULL AND value IS NOT NULL)';
      ELSIF i.table_name = 'V_CONTROLFILE_S' THEN
        l_sql := l_sql||' AND name NOT IN (SELECT name FROM v_controlfile_s WHERE eadam_seq_id = :eadam_seq_id_2 AND name IS NOT NULL)';
      ELSIF i.table_name = 'V_DATAFILE_S' THEN
        l_sql := l_sql||' AND file# NOT IN (SELECT file# FROM v_datafile_s WHERE eadam_seq_id = :eadam_seq_id_2 AND file# IS NOT NULL)';
      ELSIF i.table_name = 'V_RMAN_BACKUP_JOB_DETAILS_S' THEN
        l_sql := l_sql||' AND (session_key, session_recid, session_stamp) NOT IN (SELECT session_key, session_recid, session_stamp FROM v_rman_backup_job_details_s WHERE eadam_seq_id = :eadam_seq_id_2 AND session_key IS NOT NULL AND session_recid IS NOT NULL AND session_stamp IS NOT NULL)';
      ELSIF i.table_name = 'V_TABLESPACE_S' THEN
        l_sql := l_sql||' AND name NOT IN (SELECT name FROM v_tablespace_s WHERE eadam_seq_id = :eadam_seq_id_2 AND name IS NOT NULL)';
      ELSIF i.table_name = 'V_TEMPFILE_S' THEN
        l_sql := l_sql||' AND file# NOT IN (SELECT file# FROM v_tempfile_s WHERE eadam_seq_id = :eadam_seq_id_2 AND file# IS NOT NULL)';
      END IF;
      INSERT INTO sql_log VALUES (l_sql);
      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN :eadam_seq_id_3, :eadam_seq_id_1, :eadam_seq_id_1, :eadam_seq_id_2;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM;
          DBMS_OUTPUT.PUT_LINE(i.table_name||': '||l_error);
          INSERT INTO sql_error VALUES (:eadam_seq_id_3, SYSDATE, i.table_name||': '||l_error, l_sql);
      END;
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||LOWER(i.table_name)||' WHERE eadam_seq_id = :eadam_seq_id' INTO l_count USING IN :eadam_seq_id_3;
      DBMS_OUTPUT.PUT_LINE(RPAD(i.table_name, 30)||': '||l_count);
    END LOOP;
  END IF;
END;
/

/* ------------------------------------------------------------------------- */

INSERT INTO dba_hist_xtr_control_s
( eadam_seq_id
, eadam_seq_id_1
, eadam_seq_id_2
, row_num       
, dbid          
, dbname        
, db_unique_name
, platform_name 
, instance_number
, instance_name  
, host_name      
, version        
, capture_time   
, tar_file_name  
, directory_path 
)
SELECT
  :eadam_seq_id_3
, :eadam_seq_id_1
, :eadam_seq_id_2
, row_num       
, dbid          
, dbname        
, db_unique_name
, platform_name 
, instance_number
, instance_name  
, host_name      
, version        
, '&&current_time.'   
, tar_file_name  
, directory_path 
FROM dba_hist_xtr_control_s
WHERE eadam_seq_id = :eadam_seq_id_2
  AND :eadam_seq_id_2 > :eadam_seq_id_1 
  AND :eadam_seq_id_1 > -2;

/* ------------------------------------------------------------------------- */

COMMIT;

/* ------------------------------------------------------------------------- */

PRINT eadam_seq_id_1;
PRINT eadam_seq_id_2;
PRINT eadam_seq_id_3;

SELECT eadam_seq_id seq,
       CASE WHEN eadam_seq_id_1 IS NOT NULL THEN eadam_seq_id_1||','||eadam_seq_id_2 END source,
       dbname||'('||dbid||')' db_name_id,
       SUBSTR(host_name, 1, 30) host_nm,
       version,
       SUBSTR(capture_time, 1, 8) captured
  FROM dba_hist_xtr_control_s
 ORDER BY 1;

UNDEF 1 2
SET ECHO OFF;



