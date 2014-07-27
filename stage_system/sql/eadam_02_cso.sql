-- Creates Staging Objects
-- parameters: default and temporary tablespaces for eAdam user, the user/pwd for it

SPO eadam_02_cso.txt;
SET ECHO ON FEED ON;

CONN / AS SYSDBA;

SET TERM ON ECHO OFF;

-- displays existing tablespaces
WITH f AS (
        SELECT tablespace_name, NVL(ROUND(SUM(bytes)/1024/1024), 0) free_space_mb
          FROM (SELECT tablespace_name, SUM( bytes ) bytes 
		          FROM sys.dba_free_space 
				 GROUP BY tablespace_name
                UNION ALL
                SELECT tablespace_name, SUM( maxbytes - bytes ) bytes 
				  FROM sys.dba_data_files 
				 WHERE maxbytes - bytes > 0 
 				 GROUP BY tablespace_name )
         GROUP BY tablespace_name)
SELECT t.tablespace_name, f.free_space_mb
  FROM sys.dba_tablespaces t, f
WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name = f.tablespace_name
   AND f.free_space_mb > 50
ORDER BY f.free_space_mb;
PRO
PRO Parameter 1:
PRO DEFAULT_TABLESPACE:
PRO
DEF default_tablespace = '&1';
PRO
SELECT t.tablespace_name
  FROM sys.dba_tablespaces t
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND NOT EXISTS (
SELECT NULL
  FROM sys.dba_tablespace_groups tg
 WHERE t.tablespace_name = tg.tablespace_name )
 UNION
SELECT tg.group_name
  FROM sys.dba_tablespaces t,
       sys.dba_tablespace_groups tg
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND t.tablespace_name = tg.tablespace_name;
PRO
PRO Parameter 2:
PRO TEMPORARY_TABLESPACE:
PRO
DEF temporary_tablespace = '&2';
PRO
PRO Parameter 3:
PRO EADAM_USER:
PRO
DEF eadam_user = '&3';
PRO
PRO Parameter 4:
PRO EADAM_PWD:
PRO
DEF eadam_pwd = '&4';
PRO

SET ECHO ON;
GRANT DBA TO &&eadam_user. IDENTIFIED BY &&eadam_pwd.;
GRANT ANALYZE ANY TO &&eadam_user.;
ALTER USER &&eadam_user. DEFAULT TABLESPACE &&default_tablespace.;
ALTER USER &&eadam_user. QUOTA UNLIMITED ON &&default_tablespace.;
ALTER USER &&eadam_user. TEMPORARY TABLESPACE &&temporary_tablespace.;

/* ------------------------------------------------------------------------- */

CONN &&eadam_user./&&eadam_pwd.;

/* ------------------------------------------------------------------------- */

CREATE TABLE dba_hist_xtr_control_s (
  eadam_seq_id      NUMBER,
  eadam_seq_id_1    NUMBER,
  eadam_seq_id_2    NUMBER,
  row_num         NUMBER,
  dbid            NUMBER,
  dbname          VARCHAR2(4000),
  db_unique_name  VARCHAR2(4000),
  platform_name   VARCHAR2(4000),
  instance_number VARCHAR2(4000),
  instance_name   VARCHAR2(4000),
  host_name       VARCHAR2(4000),
  version         VARCHAR2(4000),
  capture_time    VARCHAR2(4000),
  tar_file_name   VARCHAR2(4000),
  directory_path  VARCHAR2(4000)
);

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
    l_sql := 'CREATE TABLE '||TRIM(LOWER(SUBSTR(REPLACE(p_table_name, '$'), 1, 25)))||'_s'||CHR(10)||l_cols||' PARALLEL 4';
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
  create_staging_table('DBA_HIST_SGA');
  create_staging_table('DBA_HIST_SGASTAT');
  create_staging_table('DBA_HIST_SNAPSHOT');
  create_staging_table('DBA_HIST_SQL_PLAN');
  create_staging_table('DBA_HIST_SQLSTAT');
  create_staging_table('DBA_HIST_SQLTEXT');
  create_staging_table('DBA_HIST_SYS_TIME_MODEL');
  create_staging_table('DBA_HIST_SYSSTAT');
  create_staging_table('GV_$ACTIVE_SESSION_HISTORY');
  create_staging_table('GV_$LOG');
  create_staging_table('GV_$SQL_MONITOR');
  create_staging_table('GV_$SQL_PLAN_MONITOR');
  create_staging_table('GV_$SQL_PLAN_STATISTICS_ALL');
  create_staging_table('GV_$SQL');
  create_staging_table('GV_$SYSTEM_PARAMETER2');
  create_staging_table('V_$CONTROLFILE');
  create_staging_table('V_$DATAFILE');
  create_staging_table('V_$TEMPFILE');
END;
/

/* ------------------------------------------------------------------------- */

CREATE INDEX dba_hist_sql_plan_s_n1 ON dba_hist_sql_plan_s (eadam_seq_id, dbid, sql_id, plan_hash_value, id);
CREATE INDEX gv_sql_plan_statistics_al_s_n1 ON gv_sql_plan_statistics_al_s (eadam_seq_id, inst_id, sql_id, child_number, id);

/* ------------------------------------------------------------------------- */

SELECT table_name staging_table FROM user_tables WHERE table_name LIKE '%_S' ORDER BY 1;

/* ------------------------------------------------------------------------- */

/*
DROP TABLE instances;
DROP TABLE databases;
DROP TABLE cpu_time;
DROP TABLE cpu_demand_series;
DROP TABLE cpu_consumption_series;
DROP TABLE memory_size;
DROP TABLE memory_series;
DROP TABLE database_size;
DROP TABLE iops_and_mbps;
DROP TABLE iops_series;
DROP TABLE mbps_series;
DROP TABLE time_series;
*/

CREATE TABLE instances
( eadam_seq_id       NUMBER
, dbid               NUMBER
, db_name            VARCHAR2(9)
, host_name          VARCHAR2(64)
, instance_number    NUMBER
, instance_name      VARCHAR2(16)
, inst_id            NUMBER
-- cpu time (DEM)and MEM
, aas_cpu_peak_dem_mem       NUMBER
, aas_cpu_99_99_perc_dem_mem NUMBER
, aas_cpu_99_9_perc_dem_mem  NUMBER
, aas_cpu_99_perc_dem_mem    NUMBER
, aas_cpu_95_perc_dem_mem    NUMBER
, aas_cpu_90_perc_dem_mem    NUMBER
, aas_cpu_75_perc_dem_mem    NUMBER
, aas_cpu_50_perc_dem_mem    NUMBER
-- cpu time (DEM)and AWR
, aas_cpu_peak_dem_awr       NUMBER
, aas_cpu_99_99_perc_dem_awr NUMBER
, aas_cpu_99_9_perc_dem_awr  NUMBER
, aas_cpu_99_perc_dem_awr    NUMBER
, aas_cpu_95_perc_dem_awr    NUMBER
, aas_cpu_90_perc_dem_awr    NUMBER
, aas_cpu_75_perc_dem_awr    NUMBER
, aas_cpu_50_perc_dem_awr    NUMBER
-- cpu time (CON)sumption AWR
, aas_cpu_peak_con_awr       NUMBER
, aas_cpu_99_99_perc_con_awr NUMBER
, aas_cpu_99_9_perc_con_awr  NUMBER
, aas_cpu_99_perc_con_awr    NUMBER
, aas_cpu_95_perc_con_awr    NUMBER
, aas_cpu_90_perc_con_awr    NUMBER
, aas_cpu_75_perc_con_awr    NUMBER
, aas_cpu_50_perc_con_awr    NUMBER
-- memory size MEM
, mem_total_required_mem      NUMBER
, mem_total_required_gb_mem   NUMBER
, memory_target_mem           NUMBER
, memory_target_gb_mem        NUMBER
, memory_max_target_mem       NUMBER
, memory_max_target_gb_mem    NUMBER    
, sga_target_mem              NUMBER
, sga_target_gb_mem           NUMBER
, sga_max_size_mem            NUMBER
, sga_max_size_gb_mem         NUMBER
, max_sga_alloc_mem           NUMBER
, max_sga_alloc_gb_mem        NUMBER
, pga_aggregate_target_mem    NUMBER
, pga_aggregate_target_gb_mem NUMBER
, max_pga_alloc_mem           NUMBER
, max_pga_alloc_gb_mem        NUMBER
-- memory size AWR
, mem_total_required_awr      NUMBER
, mem_total_required_gb_awr   NUMBER
, memory_target_awr           NUMBER
, memory_target_gb_awr        NUMBER
, memory_max_target_awr       NUMBER
, memory_max_target_gb_awr    NUMBER    
, sga_target_awr              NUMBER
, sga_target_gb_awr           NUMBER
, sga_max_size_awr            NUMBER
, sga_max_size_gb_awr         NUMBER
, max_sga_alloc_awr           NUMBER
, max_sga_alloc_gb_awr        NUMBER
, pga_aggregate_target_awr    NUMBER
, pga_aggregate_target_gb_awr NUMBER
, max_pga_alloc_awr           NUMBER
, max_pga_alloc_gb_awr        NUMBER
-- disk throughput
, rw_iops_peak            NUMBER
, r_iops_peak             NUMBER
, w_iops_peak             NUMBER
, rw_mbps_peak            NUMBER
, r_mbps_peak             NUMBER
, w_mbps_peak             NUMBER
, rw_iops_perc_99_99      NUMBER
, r_iops_perc_99_99       NUMBER
, w_iops_perc_99_99       NUMBER
, rw_mbps_perc_99_99      NUMBER
, r_mbps_perc_99_99       NUMBER
, w_mbps_perc_99_99       NUMBER
, rw_iops_perc_99_9       NUMBER
, r_iops_perc_99_9        NUMBER
, w_iops_perc_99_9        NUMBER
, rw_mbps_perc_99_9       NUMBER
, r_mbps_perc_99_9        NUMBER
, w_mbps_perc_99_9        NUMBER
, rw_iops_perc_99         NUMBER
, r_iops_perc_99          NUMBER
, w_iops_perc_99          NUMBER
, rw_mbps_perc_99         NUMBER
, r_mbps_perc_99          NUMBER
, w_mbps_perc_99          NUMBER
, rw_iops_perc_95         NUMBER
, r_iops_perc_95          NUMBER
, w_iops_perc_95          NUMBER
, rw_mbps_perc_95         NUMBER
, r_mbps_perc_95          NUMBER
, w_mbps_perc_95          NUMBER
, rw_iops_perc_90         NUMBER
, r_iops_perc_90          NUMBER
, w_iops_perc_90          NUMBER
, rw_mbps_perc_90         NUMBER
, r_mbps_perc_90          NUMBER
, w_mbps_perc_90          NUMBER
, rw_iops_perc_75         NUMBER
, r_iops_perc_75          NUMBER
, w_iops_perc_75          NUMBER
, rw_mbps_perc_75         NUMBER
, r_mbps_perc_75          NUMBER
, w_mbps_perc_75          NUMBER
, rw_iops_perc_50         NUMBER
, r_iops_perc_50          NUMBER
, w_iops_perc_50          NUMBER
, rw_mbps_perc_50         NUMBER
, r_mbps_perc_50          NUMBER
, w_mbps_perc_50          NUMBER
)
/

CREATE TABLE databases
( eadam_seq_id       NUMBER
, dbid               NUMBER
, db_name            VARCHAR2(9)
, host_name_src      VARCHAR2(64)
, db_unique_name     VARCHAR2(30)
, platform_name      VARCHAR2(101)
, version            VARCHAR2(17)
-- cpu time (DEM)and MEM
, aas_cpu_peak_dem_mem       NUMBER
, aas_cpu_99_99_perc_dem_mem NUMBER
, aas_cpu_99_9_perc_dem_mem  NUMBER
, aas_cpu_99_perc_dem_mem    NUMBER
, aas_cpu_95_perc_dem_mem    NUMBER
, aas_cpu_90_perc_dem_mem    NUMBER
, aas_cpu_75_perc_dem_mem    NUMBER
, aas_cpu_50_perc_dem_mem    NUMBER
-- cpu time (DEM)and AWR
, aas_cpu_peak_dem_awr       NUMBER
, aas_cpu_99_99_perc_dem_awr NUMBER
, aas_cpu_99_9_perc_dem_awr  NUMBER
, aas_cpu_99_perc_dem_awr    NUMBER
, aas_cpu_95_perc_dem_awr    NUMBER
, aas_cpu_90_perc_dem_awr    NUMBER
, aas_cpu_75_perc_dem_awr    NUMBER
, aas_cpu_50_perc_dem_awr    NUMBER
-- cpu time (CON)sumption AWR
, aas_cpu_peak_con_awr       NUMBER
, aas_cpu_99_99_perc_con_awr NUMBER
, aas_cpu_99_9_perc_con_awr  NUMBER
, aas_cpu_99_perc_con_awr    NUMBER
, aas_cpu_95_perc_con_awr    NUMBER
, aas_cpu_90_perc_con_awr    NUMBER
, aas_cpu_75_perc_con_awr    NUMBER
, aas_cpu_50_perc_con_awr    NUMBER
-- memory size MEM
, mem_total_required_mem      NUMBER
, mem_total_required_gb_mem   NUMBER
, memory_target_mem           NUMBER
, memory_target_gb_mem        NUMBER
, memory_max_target_mem       NUMBER
, memory_max_target_gb_mem    NUMBER    
, sga_target_mem              NUMBER
, sga_target_gb_mem           NUMBER
, sga_max_size_mem            NUMBER
, sga_max_size_gb_mem         NUMBER
, max_sga_alloc_mem           NUMBER
, max_sga_alloc_gb_mem        NUMBER
, pga_aggregate_target_mem    NUMBER
, pga_aggregate_target_gb_mem NUMBER
, max_pga_alloc_mem           NUMBER
, max_pga_alloc_gb_mem        NUMBER
-- memory size AWR
, mem_total_required_awr      NUMBER
, mem_total_required_gb_awr   NUMBER
, memory_target_awr           NUMBER
, memory_target_gb_awr        NUMBER
, memory_max_target_awr       NUMBER
, memory_max_target_gb_awr    NUMBER    
, sga_target_awr              NUMBER
, sga_target_gb_awr           NUMBER
, sga_max_size_awr            NUMBER
, sga_max_size_gb_awr         NUMBER
, max_sga_alloc_awr           NUMBER
, max_sga_alloc_gb_awr        NUMBER
, pga_aggregate_target_awr    NUMBER
, pga_aggregate_target_gb_awr NUMBER
, max_pga_alloc_awr           NUMBER
, max_pga_alloc_gb_awr        NUMBER
-- database size 
, db_total_size_bytes     NUMBER
, db_total_size_gb        NUMBER
, db_data_size_bytes      NUMBER
, db_data_size_gb         NUMBER
, db_temp_size_bytes      NUMBER
, db_temp_size_gb         NUMBER
, db_log_size_bytes       NUMBER
, db_log_size_gb          NUMBER
, db_control_size_bytes   NUMBER
, db_control_size_gb      NUMBER
-- disk throughput
, rw_iops_peak            NUMBER
, r_iops_peak             NUMBER
, w_iops_peak             NUMBER
, rw_mbps_peak            NUMBER
, r_mbps_peak             NUMBER
, w_mbps_peak             NUMBER
, rw_iops_perc_99_99      NUMBER
, r_iops_perc_99_99       NUMBER
, w_iops_perc_99_99       NUMBER
, rw_mbps_perc_99_99      NUMBER
, r_mbps_perc_99_99       NUMBER
, w_mbps_perc_99_99       NUMBER
, rw_iops_perc_99_9       NUMBER
, r_iops_perc_99_9        NUMBER
, w_iops_perc_99_9        NUMBER
, rw_mbps_perc_99_9       NUMBER
, r_mbps_perc_99_9        NUMBER
, w_mbps_perc_99_9        NUMBER
, rw_iops_perc_99         NUMBER
, r_iops_perc_99          NUMBER
, w_iops_perc_99          NUMBER
, rw_mbps_perc_99         NUMBER
, r_mbps_perc_99          NUMBER
, w_mbps_perc_99          NUMBER
, rw_iops_perc_95         NUMBER
, r_iops_perc_95          NUMBER
, w_iops_perc_95          NUMBER
, rw_mbps_perc_95         NUMBER
, r_mbps_perc_95          NUMBER
, w_mbps_perc_95          NUMBER
, rw_iops_perc_90         NUMBER
, r_iops_perc_90          NUMBER
, w_iops_perc_90          NUMBER
, rw_mbps_perc_90         NUMBER
, r_mbps_perc_90          NUMBER
, w_mbps_perc_90          NUMBER
, rw_iops_perc_75         NUMBER
, r_iops_perc_75          NUMBER
, w_iops_perc_75          NUMBER
, rw_mbps_perc_75         NUMBER
, r_mbps_perc_75          NUMBER
, w_mbps_perc_75          NUMBER
, rw_iops_perc_50         NUMBER
, r_iops_perc_50          NUMBER
, w_iops_perc_50          NUMBER
, rw_mbps_perc_50         NUMBER
, r_mbps_perc_50          NUMBER
, w_mbps_perc_50          NUMBER
)
/

CREATE TABLE cpu_time
( eadam_seq_id       NUMBER
, cpu_time_type      VARCHAR2(3) -- (DEM)and or (CON)sumption
, cpu_time_source    VARCHAR2(3) -- AWR or MEM
, aggregate_level    VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid               NUMBER
, db_name            VARCHAR2(9)
, host_name          VARCHAR2(64)
, instance_number    NUMBER
, instance_name      VARCHAR2(16)
, aas_cpu_peak       NUMBER
, aas_cpu_99_99_perc NUMBER
, aas_cpu_99_9_perc  NUMBER
, aas_cpu_99_perc    NUMBER
, aas_cpu_95_perc    NUMBER
, aas_cpu_90_perc    NUMBER
, aas_cpu_75_perc    NUMBER
, aas_cpu_50_perc    NUMBER
)
/

CREATE TABLE cpu_demand_series
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, sample_time         TIMESTAMP(3)
, snap_id             NUMBER
, begin_interval_time TIMESTAMP(3)
, end_interval_time   TIMESTAMP(3)
, begin_time          DATE
, end_time            DATE
, cpu_demand          NUMBER
, on_cpu              NUMBER
, waiting_for_cpu     NUMBER 
, cpu_demand_max      NUMBER
, cpu_demand_avg      NUMBER
, cpu_demand_med      NUMBER
, cpu_demand_min      NUMBER
, cpu_demand_99p      NUMBER
, cpu_demand_95p      NUMBER
, cpu_demand_90p      NUMBER
, cpu_demand_75p      NUMBER
)
/

CREATE TABLE cpu_consumption_series
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, snap_id             NUMBER
, begin_interval_time TIMESTAMP(3)
, end_interval_time   TIMESTAMP(3)
, begin_time          DATE
, end_time            DATE
, consumed_cpu        NUMBER
, background_cpu      NUMBER
, db_cpu              NUMBER 
)
/

CREATE TABLE memory_size
( eadam_seq_id            NUMBER
, memory_source           VARCHAR2(3) -- AWR or MEM
, aggregate_level         VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                    NUMBER
, db_name                 VARCHAR2(9)
, host_name               VARCHAR2(64)
, instance_number         NUMBER
, instance_name           VARCHAR2(16)
, total_required          NUMBER
, total_required_gb       NUMBER
, memory_target           NUMBER
, memory_target_gb        NUMBER
, memory_max_target       NUMBER
, memory_max_target_gb    NUMBER    
, sga_target              NUMBER
, sga_target_gb           NUMBER
, sga_max_size            NUMBER
, sga_max_size_gb         NUMBER
, max_sga_alloc           NUMBER
, max_sga_alloc_gb        NUMBER
, pga_aggregate_target    NUMBER
, pga_aggregate_target_gb NUMBER
, max_pga_alloc           NUMBER
, max_pga_alloc_gb        NUMBER
)
/

CREATE TABLE memory_series
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, snap_id             NUMBER
, begin_interval_time TIMESTAMP(3)
, end_interval_time   TIMESTAMP(3)
, begin_time          DATE
, end_time            DATE
, mem_gb              NUMBER
, sga_gb              NUMBER
, pga_gb              NUMBER 
)
/

CREATE TABLE database_size
( eadam_seq_id       NUMBER
, dbid               NUMBER
, db_name            VARCHAR2(9)
, file_type          VARCHAR2(7)
, size_bytes         NUMBER
, size_gb            NUMBER
)
/

CREATE TABLE iops_and_mbps
( eadam_seq_id            NUMBER
, aggregate_level         VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                    NUMBER
, db_name                 VARCHAR2(9)
, host_name               VARCHAR2(64)
, instance_number         NUMBER
, instance_name           VARCHAR2(16)
, rw_iops_peak            NUMBER
, r_iops_peak             NUMBER
, w_iops_peak             NUMBER
, rw_mbps_peak            NUMBER
, r_mbps_peak             NUMBER
, w_mbps_peak             NUMBER
, rw_iops_perc_99_99      NUMBER
, r_iops_perc_99_99       NUMBER
, w_iops_perc_99_99       NUMBER
, rw_mbps_perc_99_99      NUMBER
, r_mbps_perc_99_99       NUMBER
, w_mbps_perc_99_99       NUMBER
, rw_iops_perc_99_9       NUMBER
, r_iops_perc_99_9        NUMBER
, w_iops_perc_99_9        NUMBER
, rw_mbps_perc_99_9       NUMBER
, r_mbps_perc_99_9        NUMBER
, w_mbps_perc_99_9        NUMBER
, rw_iops_perc_99         NUMBER
, r_iops_perc_99          NUMBER
, w_iops_perc_99          NUMBER
, rw_mbps_perc_99         NUMBER
, r_mbps_perc_99          NUMBER
, w_mbps_perc_99          NUMBER
, rw_iops_perc_95         NUMBER
, r_iops_perc_95          NUMBER
, w_iops_perc_95          NUMBER
, rw_mbps_perc_95         NUMBER
, r_mbps_perc_95          NUMBER
, w_mbps_perc_95          NUMBER
, rw_iops_perc_90         NUMBER
, r_iops_perc_90          NUMBER
, w_iops_perc_90          NUMBER
, rw_mbps_perc_90         NUMBER
, r_mbps_perc_90          NUMBER
, w_mbps_perc_90          NUMBER
, rw_iops_perc_75         NUMBER
, r_iops_perc_75          NUMBER
, w_iops_perc_75          NUMBER
, rw_mbps_perc_75         NUMBER
, r_mbps_perc_75          NUMBER
, w_mbps_perc_75          NUMBER
, rw_iops_perc_50         NUMBER
, r_iops_perc_50          NUMBER
, w_iops_perc_50          NUMBER
, rw_mbps_perc_50         NUMBER
, r_mbps_perc_50          NUMBER
, w_mbps_perc_50          NUMBER
)
/

CREATE TABLE iops_series 
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, snap_id             NUMBER
, begin_interval_time TIMESTAMP(3)
, end_interval_time   TIMESTAMP(3)
, begin_time          DATE
, end_time            DATE
, rw_iops             NUMBER
, r_iops              NUMBER
, w_iops              NUMBER
)
/

CREATE TABLE mbps_series 
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, snap_id             NUMBER
, begin_interval_time TIMESTAMP(3)
, end_interval_time   TIMESTAMP(3)
, begin_time          DATE
, end_time            DATE
, rw_mbps             NUMBER
, r_mbps              NUMBER
, w_mbps              NUMBER
)
/

CREATE TABLE time_series 
( eadam_seq_id        NUMBER
, aggregate_level     VARCHAR2(1) -- (I)nstance or (D)atabase 
, dbid                NUMBER
, db_name             VARCHAR2(9)
, host_name           VARCHAR2(64)
, instance_number     NUMBER
, instance_name       VARCHAR2(16)
, begin_time          DATE
, end_time            DATE
-- cpu demand
, cpu_demand          NUMBER
, on_cpu              NUMBER
, waiting_for_cpu     NUMBER 
, cpu_demand_max      NUMBER
, cpu_demand_avg      NUMBER
, cpu_demand_med      NUMBER
, cpu_demand_min      NUMBER
, cpu_demand_99p      NUMBER
, cpu_demand_95p      NUMBER
, cpu_demand_90p      NUMBER
, cpu_demand_75p      NUMBER
-- cpu consumption
, consumed_cpu        NUMBER
, background_cpu      NUMBER
, db_cpu              NUMBER 
-- memory
, mem_gb              NUMBER
, sga_gb              NUMBER
, pga_gb              NUMBER 
-- disk throughput
, rw_iops             NUMBER
, r_iops              NUMBER
, w_iops              NUMBER
, rw_mbps             NUMBER
, r_mbps              NUMBER
, w_mbps              NUMBER
)
/

GRANT SELECT ON time_series TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM eadam_time_series FOR time_series
/

/* ------------------------------------------------------------------------- */

UNDEF 1 2 3 4
SET ECHO OFF FEED OFF;
SPO OFF;
