SPO eadam_13_prg.txt;

-- purges sources of verified merged sets when their merged set is older than retention days
-- purges sets with failed verification if older than retention

SET TERM ON ECHO OFF;

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

PRO
PRO Parameter 1:
PRO RETENTION_DAYS
PRO
COL retention_days NEW_V retention_days;
SELECT NVL(TRIM('&1.'), '31') retention_days FROM DUAL;

PRO
PRO purge list
SELECT eadam_seq_id seq,
       CASE WHEN eadam_seq_id_1 IS NOT NULL THEN eadam_seq_id_1||','||eadam_seq_id_2 END source,
       verification_passed,
       dbname||'('||dbid||')' db_name_id,
       SUBSTR(host_name, 1, 30) host_nm,
       version,
       SUBSTR(capture_time, 1, 8) captured
  FROM dba_hist_xtr_control_s
 WHERE eadam_seq_id IN (
SELECT eadam_seq_id
  FROM dba_hist_xtr_control_s
 WHERE NVL(verification_passed, 'N') != 'Y'
   AND TRUNC(TO_DATE(capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.
 UNION
SELECT p.eadam_seq_id
  FROM dba_hist_xtr_control_s p
 WHERE p.verification_passed = 'Y'
   AND TRUNC(TO_DATE(p.capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.
   AND EXISTS (
SELECT NULL
  FROM dba_hist_xtr_control_s c
 WHERE p.eadam_seq_id IN (c.eadam_seq_id_1, c.eadam_seq_id_2)
   AND c.verification_passed = 'Y'
   AND TRUNC(TO_DATE(c.capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.)
   AND NOT EXISTS (
SELECT NULL
  FROM dba_hist_xtr_control_s c
 WHERE p.eadam_seq_id IN (c.eadam_seq_id_1, c.eadam_seq_id_2)
   AND c.verification_passed = 'Y'
   AND TRUNC(TO_DATE(c.capture_time, 'YYYYMMDDHH24MISS')) >= TRUNC(SYSDATE) - &&retention_days.)
)
 ORDER BY
       eadam_seq_id;

SET SERVEROUT ON;

DECLARE
  l_count NUMBER;
BEGIN
  FOR i IN (SELECT eadam_seq_id,
                   CASE WHEN eadam_seq_id_1 IS NOT NULL THEN eadam_seq_id_1||','||eadam_seq_id_2 END source,
                   verification_passed,
                   dbname||'('||dbid||')' db_name_id,
                   SUBSTR(host_name, 1, 30) host_nm,
                   version,
                   SUBSTR(capture_time, 1, 8) captured
              FROM dba_hist_xtr_control_s
             WHERE eadam_seq_id IN (
            SELECT eadam_seq_id
              FROM dba_hist_xtr_control_s
             WHERE NVL(verification_passed, 'N') != 'Y'
               AND TRUNC(TO_DATE(capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.
             UNION
            SELECT p.eadam_seq_id
              FROM dba_hist_xtr_control_s p
             WHERE p.verification_passed = 'Y'
               AND TRUNC(TO_DATE(p.capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.
               AND EXISTS (
            SELECT NULL
              FROM dba_hist_xtr_control_s c
             WHERE p.eadam_seq_id IN (c.eadam_seq_id_1, c.eadam_seq_id_2)
               AND c.verification_passed = 'Y'
               AND TRUNC(TO_DATE(c.capture_time, 'YYYYMMDDHH24MISS')) < TRUNC(SYSDATE) - &&retention_days.)
               AND NOT EXISTS (
            SELECT NULL
              FROM dba_hist_xtr_control_s c
             WHERE p.eadam_seq_id IN (c.eadam_seq_id_1, c.eadam_seq_id_2)
               AND c.verification_passed = 'Y'
               AND TRUNC(TO_DATE(c.capture_time, 'YYYYMMDDHH24MISS')) >= TRUNC(SYSDATE) - &&retention_days.)
            )
             ORDER BY
                   eadam_seq_id)
  LOOP
    FOR j IN (SELECT table_name
                FROM user_tab_columns
               WHERE table_name NOT LIKE '%!_V' ESCAPE '!'
                 AND table_name NOT LIKE '%!_V_' ESCAPE '!'
                 AND column_name = 'EADAM_SEQ_ID'
               ORDER BY
                     CASE table_name WHEN 'DBA_HIST_XTR_CONTROL_S' THEN 2 ELSE 1 END,
                     table_name)
    LOOP
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||j.table_name||' WHERE eadam_seq_id = '||i.eadam_seq_id INTO l_count;
      EXECUTE IMMEDIATE 'DELETE '||j.table_name||' WHERE eadam_seq_id = '||i.eadam_seq_id;
      DBMS_OUTPUT.PUT_LINE(RPAD(i.eadam_seq_id, 5)||' '||RPAD(j.table_name, 32, '.')||LPAD(l_count, 12)||' rows');
    END LOOP;
    COMMIT;
  END LOOP;
END;
/

UNDEF 1;
SET SERVEROUT OFF;

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

SPO OFF;

