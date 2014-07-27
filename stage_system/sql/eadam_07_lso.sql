SPO eadam_07_lso.txt

-- Loads Staging Objects
COL eadam_seq_id NEW_V eadam_seq_id FOR A5;
SELECT TRIM(TO_CHAR(eadam_seq.NEXTVAL)) eadam_seq_id FROM DUAL;
PRO eadam_seq_id: "&&eadam_seq_id."

SPO eadam_07_lso_&&eadam_seq_id..txt;
PRO eadam_seq_id: "&&eadam_seq_id."

SET ECHO ON FEED ON;

DEF date_mask = 'YYYY-MM-DD/HH24:MI:SS';
DEF timestamp_mask = 'YYYY-MM-DD/HH24:MI:SS.FF6';

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_DATE_FORMAT = '&&date_mask.';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = '&&timestamp_mask.';

ALTER SESSION FORCE PARALLEL QUERY PARALLEL 4;
ALTER SESSION FORCE PARALLEL DML PARALLEL 4;

VAR eadam_seq_id NUMBER;
EXEC :eadam_seq_id := TO_NUMBER('&&eadam_seq_id.');

DELETE sql_log;
PRO loading staging objects
SET SERVEROUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
DECLARE
  l_cols_s VARCHAR2(32767);
  l_cols_e VARCHAR2(32767);
  l_sql VARCHAR2(32767);
  l_error VARCHAR2(4000);
BEGIN
  FOR i IN (SELECT s.table_name s_table_name, e.table_name e_table_name
              FROM user_tables s,
                   user_tables e
             WHERE s.table_name LIKE '%!_S' ESCAPE '!'
               AND e.table_name LIKE '%!_E' ESCAPE '!'
               AND s.table_name NOT IN ('SPECINT_RATE2006_S') -- exceptions
               AND SUBSTR(s.table_name, 1, LENGTH(s.table_name) - 1) =
                   SUBSTR(e.table_name, 1, LENGTH(e.table_name) - 1))
  LOOP
    l_cols_s := '( eadam_seq_id'||CHR(10)||', row_num'||CHR(10);
    l_cols_e := '  :eadam_seq_id'||CHR(10)||', ROWNUM'||CHR(10);
    FOR j IN (SELECT s.column_name
                FROM user_tab_columns s,
                     user_tab_columns e
               WHERE s.table_name = i.s_table_name
                 AND e.table_name = i.e_table_name
                 AND e.column_name = s.column_name
               ORDER BY
                     s.column_id)
    LOOP
      l_cols_s := l_cols_s||', '||TRIM(j.column_name)||CHR(10);
      l_cols_e := l_cols_e||', TRIM('||TRIM(j.column_name)||')'||CHR(10);
    END LOOP;
    l_cols_s := l_cols_s||')'||CHR(10);
    l_sql := 'INSERT /*+ APPEND PARALLEL(4) */ INTO '||LOWER(i.s_table_name)||CHR(10)||l_cols_s||
             'SELECT /*+ PARALLEL(4) */ '||CHR(10)||l_cols_e||'FROM '||LOWER(i.e_table_name);
    INSERT INTO sql_log VALUES (l_sql);
    BEGIN
      EXECUTE IMMEDIATE l_sql USING IN :eadam_seq_id;
      EXECUTE IMMEDIATE 'COMMIT';
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Loading Staging Table: '||i.s_table_name);
        INSERT INTO sql_error VALUES (:eadam_seq_id, SYSDATE, i.s_table_name||': '||l_error, l_sql);
    END;
    DBMS_STATS.GATHER_TABLE_STATS(USER, LOWER(i.s_table_name));
  END LOOP;
END;
/
WHENEVER SQLERROR CONTINUE;

UPDATE dba_hist_xtr_control_s SET
  tar_file_name  = TRIM('&&tar_file_name.'),
  directory_path = TRIM('&&directory_path.')
WHERE eadam_seq_id = :eadam_seq_id
/

COMMIT;

/* ------------------------------------------------------------------------- */

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

/* ------------------------------------------------------------------------- */

HOS rm -f v_*.log v_*.txt gv_*.log gv_*.txt dba_hist_*.log dba_hist_*.txt dba_tab_columns.log dba_tab_columns.txt
SET ECHO OFF FEED OFF;
SPO OFF;
