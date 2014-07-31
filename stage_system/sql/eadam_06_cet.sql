SPO eadam_06_cet.txt;

PRO This script loads awr data from source into staging system
PRO 1) place tar into eadam/stage_system directory (the one that contains the readme.txt)
PRO 2) navigate to eadam/stage_system directory, which contains now tar file(s)
PRO 3) as SYS, run @eadam_load.sql to create external tables, load staging tables and produce output
PRO

CONN / AS SYSDBA;

SET TERM ON ECHO OFF;

PRO
PRO Current Directory path:
HOS pwd
PRO Parameter 1: 
PRO Enter directory path where your TAR file should reside (eadam/stage_system directory)
PRO Note: You may want to cut and paste "current directory path" displayed above
PRO 
PRO DIRECTORY_PATH:
DEF directory_path = '&1';
PRO
PRO Parameter 2:
PRO EADAM_USER:
PRO
DEF eadam_user = '&2';
PRO
PRO Parameter 3:
PRO EADAM_PWD:
PRO
DEF eadam_pwd = '&3';
PRO

SET ECHO ON FEED ON;

CREATE OR REPLACE DIRECTORY EADAM AS '&&directory_path.';
GRANT READ,WRITE ON DIRECTORY EADAM TO &&eadam_user.;
HOS chmod 777 &&directory_path.

/* ------------------------------------------------------------------------- */

SET ECHO OFF;
PRO
PRO TAR files in Current Directory:
HOS ls -lt eadam*.tar
PRO Parameter 4:
PRO TAR_FILE_NAME:
DEF tar_file_name = '&4';
SPO OFF;
SPO eadam_06_cet_&&tar_file_name..txt;
DEF
PRO
SET ECHO ON FEED ON;

/* ------------------------------------------------------------------------- */

PRO tar extract 

HOS tar -xvf &&tar_file_name. 
HOS tar -tvf &&tar_file_name.
HOS ls -lt *.txt.gz

/* ------------------------------------------------------------------------- */

PRO gunzing files

HOS gunzip -v dba_hist_xtr_control.txt.gz
HOS gunzip -v dba_tab_columns.txt.gz

HOS gunzip -v dba_hist_active_sess_history.txt.gz
HOS gunzip -v dba_hist_database_instance.txt.gz
HOS gunzip -v dba_hist_event_histogram.txt.gz
HOS gunzip -v dba_hist_osstat.txt.gz
HOS gunzip -v dba_hist_parameter.txt.gz
HOS gunzip -v dba_hist_pgastat.txt.gz
HOS gunzip -v dba_hist_sga.txt.gz
HOS gunzip -v dba_hist_sgastat.txt.gz
HOS gunzip -v dba_hist_snapshot.txt.gz
HOS gunzip -v dba_hist_sql_plan.txt.gz
HOS gunzip -v dba_hist_sqlstat.txt.gz
HOS gunzip -v dba_hist_sqltext.txt.gz
HOS gunzip -v dba_hist_sys_time_model.txt.gz
HOS gunzip -v dba_hist_sysstat.txt.gz
HOS gunzip -v gv_active_session_history.txt.gz
HOS gunzip -v gv_log.txt.gz
HOS gunzip -v gv_sql_monitor.txt.gz
HOS gunzip -v gv_sql_plan_monitor.txt.gz
HOS gunzip -v gv_sql_plan_statistics_all.txt.gz
HOS gunzip -v gv_sql.txt.gz
HOS gunzip -v gv_system_parameter2.txt.gz
HOS gunzip -v v_controlfile.txt.gz
HOS gunzip -v v_datafile.txt.gz
HOS gunzip -v v_tempfile.txt.gz

/* ------------------------------------------------------------------------- */

DEF fields_delimiter = '<,>';

PRO Connecting as &&eadam_user.
CONN &&eadam_user./&&eadam_pwd.;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

/* ------------------------------------------------------------------------- */

DROP TABLE dba_hist_xtr_control_e;
CREATE TABLE dba_hist_xtr_control_e (
  dbid            VARCHAR2(4000),
  dbname          VARCHAR2(4000),
  db_unique_name  VARCHAR2(4000),
  platform_name   VARCHAR2(4000),
  instance_number VARCHAR2(4000),
  instance_name   VARCHAR2(4000),
  host_name       VARCHAR2(4000),
  version         VARCHAR2(4000),
  capture_time    VARCHAR2(4000)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY EADAM
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'dba_hist_xtr_control.bad'
  LOGFILE 'dba_hist_xtr_control.log'
  FIELDS TERMINATED BY '&&fields_delimiter.'
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('dba_hist_xtr_control.txt')
)
/

EXEC DBMS_STATS.LOCK_TABLE_STATS(USER, 'dba_hist_xtr_control_e');

SELECT * FROM dba_hist_xtr_control_e
/

/* ------------------------------------------------------------------------- */

DROP TABLE dba_tab_columns_e;
CREATE TABLE dba_tab_columns_e (
  table_name     VARCHAR2(4000),
  column_id      VARCHAR2(4000),
  column_name    VARCHAR2(4000),
  data_type      VARCHAR2(4000),
  data_length    VARCHAR2(4000),
  data_precision VARCHAR2(4000),
  data_scale     VARCHAR2(4000)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY EADAM
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'dba_tab_columns.bad'
  LOGFILE 'dba_tab_columns.log'
  FIELDS TERMINATED BY '&&fields_delimiter.'
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('dba_tab_columns.txt')
)
/

EXEC DBMS_STATS.LOCK_TABLE_STATS(USER, 'dba_tab_columns_e');

SELECT COUNT(*) FROM dba_tab_columns_e
/

/* ------------------------------------------------------------------------- */

ALTER SESSION ENABLE PARALLEL QUERY;
DELETE sql_log;
PRO creating external tables
SET SERVEROUT ON;
DECLARE
  l_cols VARCHAR2(32767);
  l_sql VARCHAR2(32767);
  l_error VARCHAR2(4000);
  l_table_name VARCHAR2(30);
  l_count NUMBER;
BEGIN
  FOR i IN (SELECT DISTINCT table_name FROM dba_tab_columns_e ORDER BY table_name)
  LOOP
    l_table_name := REPLACE(i.table_name, '$');
    l_cols := NULL;
    FOR j IN (SELECT column_name FROM dba_tab_columns_e WHERE table_name = i.table_name ORDER BY column_id)
    LOOP
      l_cols := l_cols||', '||RPAD(TRIM(j.column_name), 31)||'VARCHAR2(4000)'||CHR(10);
    END LOOP;
    l_cols := '('||CHR(10)||' '||SUBSTR(l_cols, 2)||')';
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE '||TRIM(LOWER(SUBSTR(l_table_name, 1, 25)))||'_e';
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Trying to drop External Table: '||TRIM(LOWER(l_table_name))); -- expected to error first time
        INSERT INTO sql_error VALUES (-1, SYSDATE, TRIM(LOWER(l_table_name))||': '||l_error, l_sql);
        COMMIT;
    END;
    l_sql := 'CREATE TABLE '||TRIM(LOWER(SUBSTR(l_table_name, 1, 25)))||'_e'||l_cols||'
  ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY EADAM
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x''0A''
  BADFILE '''||TRIM(LOWER(l_table_name))||'.bad''
  LOGFILE '''||TRIM(LOWER(l_table_name))||'.log''
  FIELDS TERMINATED BY ''&&fields_delimiter.''
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('''||TRIM(LOWER(l_table_name))||'.txt'')
)
  PARALLEL 4
  REJECT LIMIT UNLIMITED';   
    INSERT INTO sql_log VALUES (l_sql);
    BEGIN
      EXECUTE IMMEDIATE l_sql;
      EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL(4) */ COUNT(*) FROM '||TRIM(LOWER(SUBSTR(l_table_name, 1, 25)))||'_e' INTO l_count;
      DBMS_OUTPUT.PUT_LINE(TO_CHAR(l_count, '999,999,999,990')||' '||TRIM(LOWER(SUBSTR(l_table_name, 1, 25)))||'_e');
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Trying to create External Table: '||TRIM(LOWER(l_table_name))); -- expecting some errors
        INSERT INTO sql_error VALUES (-1, SYSDATE, TRIM(LOWER(l_table_name))||': '||l_error, l_sql);
        COMMIT;
    END;
    DBMS_STATS.LOCK_TABLE_STATS(USER, TRIM(LOWER(SUBSTR(l_table_name, 1, 25)))||'_e');
  END LOOP;
END;
/
WHENEVER SQLERROR CONTINUE;

/* ------------------------------------------------------------------------- */

SELECT table_name external_table FROM user_tables WHERE table_name LIKE '%_E' ORDER BY 1;

UNDEF 1 2 3
SET ECHO OFF FEED OFF;
SPO OFF;

