-- Creates Staging Objects. Use this script when there are new eAdam schema objects
-- parameters: default and temporary tablespaces for eAdam user, the user/pwd for it

SPO eadam_02_cso.txt;
SET ECHO ON FEED ON;

/* ------------------------------------------------------------------------- */

CONN &&eadam_user./&&eadam_pwd.;

/* ------------------------------------------------------------------------- */

CREATE TABLE dba_hist_xtr_control_s (
  eadam_seq_id        NUMBER,
  eadam_seq_id_1      NUMBER,
  eadam_seq_id_2      NUMBER,
  verification_passed VARCHAR2(1), /* Y/N */
  row_num             NUMBER,
  dbid                NUMBER,
  dbname              VARCHAR2(4000),
  db_unique_name      VARCHAR2(4000),
  platform_name       VARCHAR2(4000),
  instance_number     VARCHAR2(4000),
  instance_name       VARCHAR2(4000),
  host_name           VARCHAR2(4000),
  version             VARCHAR2(4000),
  capture_time        VARCHAR2(4000),
  tar_file_name       VARCHAR2(4000),
  directory_path      VARCHAR2(4000)
);

CREATE UNIQUE INDEX dba_hist_xtr_control_s_pk ON dba_hist_xtr_control_s (eadam_seq_id)
/

ALTER TABLE dba_hist_xtr_control_s 
ADD CONSTRAINT dba_hist_xtr_control_s_pk 
PRIMARY KEY (eadam_seq_id); 

GRANT SELECT ON dba_hist_xtr_control_s TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_control FOR dba_hist_xtr_control_s
/

/* ------------------------------------------------------------------------- */

CREATE TABLE dba_tab_columns_s (
  eadam_seq_id     NUMBER,
  eadam_seq_id_src NUMBER,
  row_num        NUMBER,
  table_name     VARCHAR2(4000),
  column_id      NUMBER,
  column_name    VARCHAR2(4000),
  data_type      VARCHAR2(4000),
  data_length    NUMBER,
  data_precision NUMBER,
  data_scale     NUMBER
);

/* ------------------------------------------------------------------------- */

CREATE TABLE sql_log (sql_text CLOB);

CREATE TABLE sql_error (eadam_seq_id NUMBER, error_time DATE, error_text VARCHAR2(4000), sql_text CLOB);

CREATE SEQUENCE eadam_seq NOCACHE;

/* ------------------------------------------------------------------------- */

-- sysman.gc$metric_values_hourly
CREATE TABLE gc_metric_values_hourly_s 
( eadam_seq_id              NUMBER
, eadam_seq_id_src			NUMBER
, row_num					NUMBER
, entity_type               VARCHAR2(64)  
, entity_name               VARCHAR2(256) 
, entity_guid               RAW(16)  
, parent_me_type            VARCHAR2(64)  
, parent_me_name            VARCHAR2(256) 
, parent_me_guid            RAW(16)  
, type_meta_ver             VARCHAR2(8)   
, metric_group_name         VARCHAR2(64)  
, metric_column_name        VARCHAR2(64)  
, column_type               NUMBER(1)     
, column_index              NUMBER(3)     
, data_column_type          NUMBER(2)     
, metric_group_id           NUMBER(38)    
, metric_group_label        VARCHAR2(64)  
, metric_group_label_nlsid  VARCHAR2(64)  
, metric_column_id          NUMBER(38)    
, metric_column_label       VARCHAR2(64)  
, metric_column_label_nlsid VARCHAR2(64)  
, description               VARCHAR2(128) 
, short_name                VARCHAR2(40)  
, unit                      VARCHAR2(32)  
, is_for_summary            NUMBER        
, is_stateful               NUMBER        
, non_thresholded_alerts    NUMBER        
, metric_key_id             NUMBER(38)    
, key_part_1                VARCHAR2(256) 
, key_part_2                VARCHAR2(256) 
, key_part_3                VARCHAR2(256) 
, key_part_4                VARCHAR2(256) 
, key_part_5                VARCHAR2(256) 
, key_part_6                VARCHAR2(256) 
, key_part_7                VARCHAR2(256) 
, collection_time           DATE          
, collection_time_utc       DATE          
, count_of_collections      NUMBER(38)    
, avg_value                 NUMBER        
, min_value                 NUMBER        
, max_value                 NUMBER        
, stddev_value              NUMBER      
);

/* ------------------------------------------------------------------------- */

CREATE TABLE row_counts
( eadam_seq_id              NUMBER
, table_name                VARCHAR2(30)
, external_table_row_count  NUMBER
, staging_table_row_count   NUMBER
, verification_passed       VARCHAR2(1) /* Y/N */
);

/* ------------------------------------------------------------------------- */

DELETE sql_log;
PRO creating staging objects
SET SERVEROUT ON;
DECLARE
  PROCEDURE create_staging_table(p_table_name IN VARCHAR2)
  AS
    l_error VARCHAR2(4000);
    l_cols VARCHAR2(32767);
    l_sql VARCHAR2(32767);
  BEGIN
    l_cols := '( eadam_seq_id     NUMBER'||CHR(10)||
              ', eadam_seq_id_src NUMBER'||CHR(10)||
              ', row_num        NUMBER'||CHR(10);
    FOR j IN (SELECT column_name, data_type, data_length
                FROM dba_tab_columns 
               WHERE owner = 'SYS'
                 AND table_name = p_table_name
               ORDER BY column_id)
    LOOP
      l_cols := l_cols||', '||RPAD(TRIM(j.column_name), 31)||j.data_type;
      IF j.data_type IN ('CHAR', 'RAW') THEN
        l_cols := l_cols||'('||j.data_length||')';
      ELSIF j.data_type = 'VARCHAR2' THEN
        l_cols := l_cols||'(4000)';
      END IF;
      l_cols := l_cols||CHR(10);
    END LOOP;
    l_cols := l_cols||')';
    l_sql := 'CREATE TABLE '||TRIM(LOWER(SUBSTR(REPLACE(p_table_name, '$'), 1, 25)))||'_s'||CHR(10)||l_cols;
    INSERT INTO sql_log VALUES (l_sql);
    BEGIN
      EXECUTE IMMEDIATE l_sql; 
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(l_error||'. Creating Staging Table: '||p_table_name);
        INSERT INTO sql_error VALUES (-1, SYSDATE, l_error, l_sql);
    END;
  END create_staging_table;
BEGIN
  create_staging_table('DBA_HIST_ACTIVE_SESS_HISTORY');
  create_staging_table('DBA_HIST_DATABASE_INSTANCE');
  create_staging_table('DBA_HIST_EVENT_HISTOGRAM');
  create_staging_table('DBA_HIST_OSSTAT');
  create_staging_table('DBA_HIST_PARAMETER');
  create_staging_table('DBA_HIST_PGASTAT');
  create_staging_table('DBA_HIST_SERVICE_STAT');
  create_staging_table('DBA_HIST_SGA');
  create_staging_table('DBA_HIST_SGASTAT');
  create_staging_table('DBA_HIST_SNAPSHOT');
  create_staging_table('DBA_HIST_SQL_PLAN');
  create_staging_table('DBA_HIST_SQLSTAT');
  create_staging_table('DBA_HIST_SQLTEXT');
  create_staging_table('DBA_HIST_SYS_TIME_MODEL');
  create_staging_table('DBA_HIST_SYSSTAT');
  create_staging_table('DBA_HIST_SYSTEM_EVENT');
  create_staging_table('DBA_HIST_TBSPC_SPACE_USAGE');
  create_staging_table('DBA_TABLESPACES');
  create_staging_table('GV_$ACTIVE_SESSION_HISTORY');
  create_staging_table('GV_$LOG');
  create_staging_table('GV_$SQL_MONITOR');
  create_staging_table('GV_$SQL_PLAN_MONITOR');
  create_staging_table('GV_$SQL_PLAN_STATISTICS_ALL');
  create_staging_table('GV_$SQL');
  create_staging_table('GV_$SYSTEM_PARAMETER2');
  create_staging_table('V_$CONTROLFILE');
  create_staging_table('V_$DATAFILE');
  create_staging_table('V_$RMAN_BACKUP_JOB_DETAILS');
  create_staging_table('V_$TABLESPACE');
  create_staging_table('V_$TEMPFILE');
END;
/

/* ------------------------------------------------------------------------- */

CREATE INDEX dba_hist_sql_plan_s_n1 ON dba_hist_sql_plan_s (eadam_seq_id, dbid, sql_id, plan_hash_value, id);
CREATE INDEX gv_sql_plan_statistics_al_s_n1 ON gv_sql_plan_statistics_al_s (eadam_seq_id, inst_id, sql_id, child_number, id);

/* ------------------------------------------------------------------------- */

SELECT table_name staging_table FROM user_tables WHERE table_name LIKE '%_S' ORDER BY 1;

/* ------------------------------------------------------------------------- */

SET ECHO OFF FEED OFF;
SPO OFF;
