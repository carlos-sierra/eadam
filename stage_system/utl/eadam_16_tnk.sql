-- truncates eadam repository

ALTER SESSION FORCE PARALLEL DDL PARALLEL 4;
SET SERVEROUT ON;

BEGIN
  FOR i IN (SELECT table_name
              FROM user_tab_columns
             WHERE table_name NOT LIKE '%!_V' ESCAPE '!'
               AND table_name NOT LIKE '%!_V_' ESCAPE '!'
               AND column_name = 'EADAM_SEQ_ID'
             ORDER BY
                   table_name)
  LOOP
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||i.table_name;
    DBMS_OUTPUT.PUT_LINE(RPAD(i.table_name, 32, '.')||' truncated');
  END LOOP;
END;
/

SET SERVEROUT OFF;
