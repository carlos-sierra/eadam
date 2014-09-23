-- deletes an eadam_seq_id

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
PRO EADAM_SEQ_ID:
PRO
DEF eadam_seq_id = '&1';
PRO

SET SERVEROUT ON;

DECLARE
  l_count NUMBER;
BEGIN
  FOR i IN (SELECT table_name
              FROM user_tab_columns
             WHERE table_name NOT LIKE '%!_V' ESCAPE '!'
               AND table_name NOT LIKE '%!_V_' ESCAPE '!'
               AND column_name = 'EADAM_SEQ_ID'
             ORDER BY
                   table_name)
  LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||i.table_name||' WHERE eadam_seq_id = &&eadam_seq_id.' INTO l_count;
    EXECUTE IMMEDIATE 'DELETE '||i.table_name||' WHERE eadam_seq_id = &&eadam_seq_id.';
    DBMS_OUTPUT.PUT_LINE(RPAD(i.table_name, 32, '.')||LPAD(l_count, 12)||' rows');
  END LOOP;
END;
/

COMMIT;

UNDEF 1;
SET SERVEROUT OFF;

