SPO eadam_07_lso.txt

-- Loads Staging Objects
COL eadam_seq_id NEW_V eadam_seq_id FOR A5;
SELECT TRIM(TO_CHAR(eadam_seq.NEXTVAL)) eadam_seq_id FROM DUAL;
PRO eadam_seq_id: "&&eadam_seq_id."

SPO eadam_07_lso_&&eadam_seq_id..txt;
PRO eadam_seq_id: "&&eadam_seq_id."
DEF new_eadam_seq_id = "&&eadam_seq_id."

SET ECHO ON FEED ON;

DEF date_mask = 'YYYY-MM-DD/HH24:MI:SS';
DEF timestamp_mask = 'YYYY-MM-DD/HH24:MI:SS.FF6';

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_DATE_FORMAT = '&&date_mask.';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = '&&timestamp_mask.';

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
  l_count NUMBER;
  l_total NUMBER;
  l_passed NUMBER;
BEGIN
  FOR i IN (SELECT s.table_name s_table_name, e.table_name e_table_name
              FROM user_tables s,
                   user_tables e
             WHERE s.table_name LIKE '%!_S' ESCAPE '!'
               AND e.table_name LIKE '%!_E' ESCAPE '!'
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
    l_sql := 'INSERT INTO '||LOWER(i.s_table_name)||CHR(10)||l_cols_s||
             'SELECT '||CHR(10)||l_cols_e||'FROM '||LOWER(i.e_table_name);
    INSERT INTO sql_log VALUES (l_sql);
    BEGIN
      EXECUTE IMMEDIATE l_sql USING IN :eadam_seq_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Loading Staging Table: '||i.s_table_name);
        INSERT INTO sql_error VALUES (:eadam_seq_id, SYSDATE, i.s_table_name||': '||l_error, l_sql);
    END;
    -- records row count of external table
    BEGIN
      l_sql := 'SELECT COUNT(*) FROM '||LOWER(i.e_table_name);
      EXECUTE IMMEDIATE l_sql INTO l_count;
      MERGE INTO row_counts r
      USING (SELECT :eadam_seq_id eadam_seq_id, i.s_table_name table_name, l_count external_table_row_count FROM dual) d 
      ON (r.eadam_seq_id = d.eadam_seq_id AND r.table_name = d.table_name)
      WHEN MATCHED THEN UPDATE SET r.external_table_row_count = d.external_table_row_count, r.verification_passed = NULL
      WHEN NOT MATCHED THEN INSERT (eadam_seq_id, table_name, external_table_row_count, verification_passed) 
      VALUES (d.eadam_seq_id, d.table_name, d.external_table_row_count, NULL);
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Counting Rows on External Table: '||i.e_table_name);
        INSERT INTO sql_error VALUES (:eadam_seq_id, SYSDATE, i.e_table_name||': '||l_error, l_sql);
    END;
    -- records row count of staging table
    BEGIN
      l_sql := 'SELECT COUNT(*) FROM '||LOWER(i.s_table_name)||' WHERE eadam_seq_id = :eadam_seq_id';
      EXECUTE IMMEDIATE l_sql INTO l_count USING IN :eadam_seq_id;
      MERGE INTO row_counts r
      USING (SELECT :eadam_seq_id eadam_seq_id, i.s_table_name table_name, l_count staging_table_row_count FROM dual) d 
      ON (r.eadam_seq_id = d.eadam_seq_id AND r.table_name = d.table_name)
      WHEN MATCHED THEN UPDATE SET r.staging_table_row_count = d.staging_table_row_count, r.verification_passed = NULL
      WHEN NOT MATCHED THEN INSERT (eadam_seq_id, table_name, external_table_row_count, staging_table_row_count, verification_passed) 
      VALUES (d.eadam_seq_id, d.table_name, 0, d.staging_table_row_count, NULL);
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Counting Rows on Staging Table: '||i.s_table_name);
        INSERT INTO sql_error VALUES (:eadam_seq_id, SYSDATE, i.s_table_name||': '||l_error, l_sql);
    END;
  END LOOP;
  -- set verification at table level
  UPDATE row_counts SET verification_passed = 'Y' WHERE eadam_seq_id = :eadam_seq_id AND NVL(external_table_row_count, 0) = staging_table_row_count;
  UPDATE row_counts SET verification_passed = 'N' WHERE eadam_seq_id = :eadam_seq_id AND verification_passed IS NULL;
  -- set verification at load level
  SELECT COUNT(*), SUM(CASE verification_passed WHEN 'Y' THEN 1 ELSE 0 END) 
    INTO l_total, l_passed
    FROM row_counts
   WHERE eadam_seq_id = :eadam_seq_id;
  IF l_total = l_passed 
  THEN -- all tables passed validation
    UPDATE dba_hist_xtr_control_s SET verification_passed = 'Y' WHERE eadam_seq_id = :eadam_seq_id;
  ELSE
    UPDATE dba_hist_xtr_control_s SET verification_passed = 'N' WHERE eadam_seq_id = :eadam_seq_id;
  END IF;    
END;
/
WHENEVER SQLERROR CONTINUE;

/* ------------------------------------------------------------------------- */

-- set row count for staging tables
DECLARE
  l_count NUMBER;
BEGIN
  FOR i IN (SELECT table_name
              FROM user_tab_cols
             WHERE table_name LIKE '%/_S' ESCAPE '/'
               AND column_name = 'EADAM_SEQ_ID'
               AND table_name NOT IN ('DBA_HIST_XTR_CONTROL_S') -- exclusion list
             ORDER BY
                   table_name)
  LOOP
    FOR j IN (SELECT eadam_seq_id FROM dba_hist_xtr_control_s WHERE verification_passed IS NULL ORDER BY eadam_seq_id) -- includes this new merged set
    LOOP
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||i.table_name||' WHERE eadam_seq_id = :eadam_seq_id' INTO l_count USING IN j.eadam_seq_id;
      MERGE INTO row_counts r
      USING (SELECT j.eadam_seq_id eadam_seq_id, i.table_name table_name, l_count staging_table_row_count FROM dual) d 
      ON (r.eadam_seq_id = d.eadam_seq_id AND r.table_name = d.table_name)
      WHEN MATCHED THEN UPDATE SET r.staging_table_row_count = d.staging_table_row_count, r.verification_passed = 'Y'
      WHEN NOT MATCHED THEN INSERT (eadam_seq_id, table_name, external_table_row_count, staging_table_row_count, verification_passed) 
      VALUES (d.eadam_seq_id, d.table_name, 0, d.staging_table_row_count, 'Y');
    END LOOP;
  END LOOP;
END;
/

-- tables with failed verification
SELECT table_name, external_table_row_count, staging_table_row_count
  FROM row_counts
 WHERE eadam_seq_id = :eadam_seq_id
   AND NVL(verification_passed, 'N') != 'Y' 
 ORDER BY
       table_name;

/* ------------------------------------------------------------------------- */

UPDATE dba_hist_xtr_control_s SET
  tar_file_name  = TRIM('&&tar_file_name.'),
  directory_path = TRIM('&&directory_path.')
WHERE eadam_seq_id = :eadam_seq_id
/

COMMIT;

/* ------------------------------------------------------------------------- */

-- gets prior set in case this is an automerge
COL old_eadam_seq_id NEW_V old_eadam_seq_id;
SELECT TO_CHAR(NVL(MAX(o.eadam_seq_id), -2)) old_eadam_seq_id -- if -2 then skip merge
  FROM dba_hist_xtr_control_s n,
       dba_hist_xtr_control_s o
 WHERE n.eadam_seq_id = :eadam_seq_id
   AND n.verification_passed = 'Y'
   AND o.dbid = n.dbid
   AND o.dbname = n.dbname
   AND o.db_unique_name = n.db_unique_name
   AND o.platform_name = n.platform_name
   AND o.verification_passed = 'Y'
   AND o.version <= n.version
   AND o.capture_time < n.capture_time
   AND o.eadam_seq_id < n.eadam_seq_id
/
SELECT '-2' old_eadam_seq_id FROM DUAL WHERE '&&old_eadam_seq_id.' IS NULL;

/* ------------------------------------------------------------------------- */

-- list
COL seq FOR 99999;
COL source FOR A13;
COL verification_passed FOR A1;
COL db_name_id FOR A20;
COL version FOR A10;
COL captured FOR A8;
COL host_nm FOR A30 HEA "HOST_NAME";
SELECT eadam_seq_id seq,
       CASE WHEN eadam_seq_id_1 IS NOT NULL THEN eadam_seq_id_1||','||eadam_seq_id_2 END source,
       verification_passed,
       dbname||'('||dbid||')' db_name_id,
       SUBSTR(host_name, 1, 30) host_nm,
       version,
       SUBSTR(capture_time, 1, 8) captured
  FROM dba_hist_xtr_control_s
 ORDER BY 1;

/* ------------------------------------------------------------------------- */

HOS rm -f v_*.log v_*.txt gv_*.log gv_*.txt dba_*.log dba_*.txt gc_*.log gc_*.txt 
SET ECHO OFF FEED OFF;
SPO OFF;
