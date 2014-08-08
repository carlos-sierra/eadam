-- Creates Views

SPO eadam_05_cvw.txt;
SET ECHO ON FEED ON;

DEF sq_fact_hints = 'MATERIALIZE RESULT_CACHE';

/* ------------------------------------------------------------------------- */

-- stitches other_xml from multi-row into one CLOB
DELETE sql_log;
PRO dba_hist_sql_plan_v1
SET SERVEROUT ON;
DECLARE
  l_cols VARCHAR2(32767);
  l_sql VARCHAR2(32767);
  l_error VARCHAR2(4000);
BEGIN
  FOR i IN (SELECT column_name
              FROM user_tab_columns
             WHERE table_name = 'DBA_HIST_SQL_PLAN_S'
             ORDER BY
                   column_id)
  LOOP
    IF l_cols IS NULL THEN
      l_cols := l_cols||'  ';
    ELSE
      l_cols := l_cols||', ';
    END IF;
    IF i.column_name = 'OTHER_XML' THEN
      l_cols := l_cols||'eadam.get_other_xml_awr(eadam_seq_id, dbid, sql_id, plan_hash_value, id) '||i.column_name||CHR(10);
    ELSE
      l_cols := l_cols||i.column_name||CHR(10);
    END IF;
  END LOOP;
  l_sql := 'CREATE OR REPLACE VIEW dba_hist_sql_plan_v1 AS'||CHR(10)||
           'SELECT'||CHR(10)||
           l_cols||
           '  FROM dba_hist_sql_plan_s'||CHR(10)||
           ' WHERE sql_id IS NOT NULL';
  INSERT INTO sql_log VALUES (l_sql);
  BEGIN
    EXECUTE IMMEDIATE l_sql;
  EXCEPTION
    WHEN OTHERS THEN
      l_error := SQLERRM;
      DBMS_OUTPUT.PUT_LINE(l_error);
      INSERT INTO sql_error VALUES (-1, SYSDATE, l_error, l_sql);
  END;
END;
/

-- stitches other_xml from multi-row into one CLOB
DELETE sql_log;
PRO gv_sql_plan_statistics_all_v1
SET SERVEROUT ON;
DECLARE
  l_cols VARCHAR2(32767);
  l_sql VARCHAR2(32767);
  l_error VARCHAR2(4000);
BEGIN
  FOR i IN (SELECT column_name
              FROM user_tab_columns
             WHERE table_name = 'GV_SQL_PLAN_STATISTICS_AL_S'
             ORDER BY
                   column_id)
  LOOP
    IF l_cols IS NULL THEN
      l_cols := l_cols||'  ';
    ELSE
      l_cols := l_cols||', ';
    END IF;
    IF i.column_name = 'OTHER_XML' THEN
      l_cols := l_cols||'eadam.get_other_xml_mem(eadam_seq_id, inst_id, sql_id, child_number, id) '||i.column_name||CHR(10);
    ELSE
      l_cols := l_cols||i.column_name||CHR(10);
    END IF;
  END LOOP;
  l_sql := 'CREATE OR REPLACE VIEW gv_sql_plan_statistics_all_v1 AS'||CHR(10)||
           'SELECT'||CHR(10)||
           l_cols||
           '  FROM gv_sql_plan_statistics_al_s'||CHR(10)||
           ' WHERE sql_id IS NOT NULL';
  INSERT INTO sql_log VALUES (l_sql);
  BEGIN
    EXECUTE IMMEDIATE l_sql;
  EXCEPTION
    WHEN OTHERS THEN
      l_error := SQLERRM;
      DBMS_OUTPUT.PUT_LINE(l_error);
      INSERT INTO sql_error VALUES (-1, SYSDATE, l_error, l_sql);
  END;
END;
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW databases_v AS
SELECT
  eadam_seq_id       
, dbid               
, db_name            
, db_unique_name     
, platform_name      
, version            
, host_name_src      
-- database size 
, CEIL(db_total_size_gb) database_size_gb       
-- cpu time (DEM)and AWR or MEM: taking max (peak).
, COALESCE(aas_cpu_peak_dem_awr, aas_cpu_peak_dem_mem) aas_cpu_demand    
-- cpu time (CON)sumption AWR: taking max (peak).
, aas_cpu_peak_con_awr aas_cpu_consumed      
-- memory size AWR or MEM
, ROUND(COALESCE(max_sga_alloc_gb_awr, max_sga_alloc_gb_mem, sga_max_size_gb_awr, sga_max_size_gb_mem, sga_target_awr, sga_target_mem), 1)         
+ ROUND(COALESCE(max_pga_alloc_gb_awr, max_pga_alloc_gb_mem, pga_aggregate_target_gb_awr, pga_aggregate_target_gb_mem), 1) mem_size_gb        
, ROUND(COALESCE(max_sga_alloc_gb_awr, max_sga_alloc_gb_mem, sga_max_size_gb_awr, sga_max_size_gb_mem, sga_target_awr, sga_target_mem), 1) sga_size_gb        
, ROUND(COALESCE(max_pga_alloc_gb_awr, max_pga_alloc_gb_mem, pga_aggregate_target_gb_awr, pga_aggregate_target_gb_mem), 1) pga_size_gb        
-- disk throughput
, (r_iops_peak + w_iops_peak) rw_iops 
, r_iops_peak r_iops            
, w_iops_peak w_iops            
, (r_mbps_peak + w_mbps_peak) rw_mbps        
, r_mbps_peak r_mbps            
, w_mbps_peak w_mbps            
FROM databases
/

GRANT SELECT ON databases_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_databases FOR databases_v
/

CREATE OR REPLACE VIEW instances_v AS
SELECT
  eadam_seq_id       
, dbid               
, db_name            
, host_name          
, instance_number    
, instance_name      
-- cpu time (DEM)and AWR or MEM: taking max (peak).
, COALESCE(aas_cpu_peak_dem_awr, aas_cpu_peak_dem_mem) aas_cpu_demand    
-- cpu time (CON)sumption AWR: taking max (peak).
, aas_cpu_peak_con_awr aas_cpu_consumed      
-- memory size AWR or MEM
, ROUND(COALESCE(max_sga_alloc_gb_awr, max_sga_alloc_gb_mem, sga_max_size_gb_awr, sga_max_size_gb_mem, sga_target_awr, sga_target_mem), 1)         
+ ROUND(COALESCE(max_pga_alloc_gb_awr, max_pga_alloc_gb_mem, pga_aggregate_target_gb_awr, pga_aggregate_target_gb_mem), 1) mem_size_gb        
, ROUND(COALESCE(max_sga_alloc_gb_awr, max_sga_alloc_gb_mem, sga_max_size_gb_awr, sga_max_size_gb_mem, sga_target_awr, sga_target_mem), 1) sga_size_gb        
, ROUND(COALESCE(max_pga_alloc_gb_awr, max_pga_alloc_gb_mem, pga_aggregate_target_gb_awr, pga_aggregate_target_gb_mem), 1) pga_size_gb        
-- disk throughput
, (r_iops_peak + w_iops_peak) rw_iops 
, r_iops_peak r_iops            
, w_iops_peak w_iops            
, (r_mbps_peak + w_mbps_peak) rw_mbps        
, r_mbps_peak r_mbps            
, w_mbps_peak w_mbps            
FROM instances
/

GRANT SELECT ON instances_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_instances FOR instances_v
/

/* ------------------------------------------------------------------------- */

SELECT object_name views FROM user_objects WHERE object_type = 'VIEW' ORDER BY 1;

SET ECHO OFF FEED OFF;
SPO OFF;
