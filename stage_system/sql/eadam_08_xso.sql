SPO eadam_08_xso.txt
CL COL
SET LIN 2000 TRIMS ON TIM ON TIMI ON ECHO ON VER ON FEED ON;

-- Transforms Staginging Objects
PRO eadam_seq_id: "&&eadam_seq_id."

SPO eadam_08_xso_&&eadam_seq_id..txt;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

ALTER SESSION ENABLE PARALLEL QUERY;
ALTER SESSION ENABLE PARALLEL DML;

COL eadam_dbid NEW_V eadam_dbid;
SELECT dbid eadam_dbid FROM dba_hist_xtr_control_s WHERE eadam_seq_id = &&eadam_seq_id.
/

/* ------------------------------------------------------------------------- */

DEF sq_fact_hints = 'MATERIALIZE NO_MERGE';
DEF percentile = '1';

DELETE instances WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO instances
( eadam_seq_id   
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, inst_id
)
WITH 
i1 AS (
SELECT DISTINCT
  i.eadam_seq_id   
, i.dbid           
, i.db_name        
, i.host_name      
, i.instance_number
, i.instance_name  
  FROM dba_hist_database_instanc_s i,
       dba_hist_xtr_control_s c
 WHERE i.eadam_seq_id = &&eadam_seq_id.
   AND c.eadam_seq_id = i.eadam_seq_id
   AND c.dbid = i.dbid
),
i2 AS (
SELECT /*+ PARALLEL(4) */ DISTINCT
       TO_NUMBER(value) instance_number,
       inst_id
  FROM gv_system_parameter2_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND name = 'instance_number'
)
SELECT
  i1.eadam_seq_id   
, i1.dbid           
, i1.db_name        
, i1.host_name      
, i1.instance_number
, i1.instance_name  
, NVL(i2.inst_id, i1.instance_number) inst_id
  FROM i1, i2
 WHERE i2.instance_number(+) = i1.instance_number 
/

COMMIT;

SELECT * FROM instances WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE databases WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO databases
( eadam_seq_id       
, dbid               
, db_name            
, host_name_src      
, db_unique_name     
, platform_name      
, version            
)
WITH
ctrl AS (
SELECT
  eadam_seq_id  
, dbid          
, SUBSTR(dbname, 1, 9)          db_name       
, SUBSTR(host_name, 1, 64)      host_name_src
, SUBSTR(db_unique_name, 1, 30) db_unique_name
, SUBSTR(platform_name, 1, 101) platform_name
, SUBSTR(version, 1, 17)        version     
  FROM dba_hist_xtr_control_s
 WHERE eadam_seq_id = &&eadam_seq_id.
)
SELECT
  c.eadam_seq_id       
, c.dbid               
, c.db_name            
, c.host_name_src      
, c.db_unique_name     
, c.platform_name      
, c.version            
  FROM ctrl c
/

COMMIT;

SELECT * FROM databases WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'DEM' AND cpu_time_source = 'MEM'
/

COMMIT;

INSERT INTO cpu_time
( eadam_seq_id      
, cpu_time_type     
, cpu_time_source   
, aggregate_level
, dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
, aas_cpu_99_99_perc
, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT /*+ ORDERED */
       i.eadam_seq_id,
       'DEM' cpu_time_type,
       'MEM' cpu_time_source,
       'I' aggregate_level,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       peak.cpu_demand        peak_on_cpu,
       perc_99_99.cpu_demand  perc_99_99_on_cpu,
       perc_99_9.cpu_demand   perc_99_9_on_cpu,
       perc_99.cpu_demand     perc_99_on_cpu,
       perc_95.cpu_demand     perc_95_on_cpu,
       perc_90.cpu_demand     perc_90_on_cpu,
       perc_75.cpu_demand     perc_75_on_cpu,
       perc_50.cpu_demand     perc_50_on_cpu
  FROM my_instances i,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 1     )) peak,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.99  )) perc_99,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.95  )) perc_95,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.9   )) perc_90,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.75  )) perc_75,
       TABLE(eadam.cpu_demand_peak_mem(i.eadam_seq_id, i.inst_id, 0.50  )) perc_50
 WHERE perc_99_99.cpu_demand > 0
 UNION ALL
SELECT /*+ ORDERED */
       d.eadam_seq_id,
       'DEM' cpu_time_type,
       'MEM' cpu_time_source,
       'D' aggregate_level,
       d.dbid,
       d.db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       peak.cpu_demand        peak_on_cpu,
       perc_99_99.cpu_demand  perc_99_99_on_cpu,
       perc_99_9.cpu_demand   perc_99_9_on_cpu,
       perc_99.cpu_demand     perc_99_on_cpu,
       perc_95.cpu_demand     perc_95_on_cpu,
       perc_90.cpu_demand     perc_90_on_cpu,
       perc_75.cpu_demand     perc_75_on_cpu,
       perc_50.cpu_demand     perc_50_on_cpu
  FROM my_databases d,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 1     )) peak,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.99  )) perc_99,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.95  )) perc_95,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.9   )) perc_90,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.75  )) perc_75,
       TABLE(eadam.cpu_demand_peak_mem(d.eadam_seq_id, NULL, 0.50  )) perc_50
 WHERE perc_99_99.cpu_demand > 0
/

COMMIT;

SELECT * FROM cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'DEM' AND cpu_time_source = 'MEM'
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'DEM' AND cpu_time_source = 'AWR'
/

COMMIT;

INSERT INTO cpu_time
( eadam_seq_id      
, cpu_time_type     
, cpu_time_source   
, aggregate_level
, dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
, aas_cpu_99_99_perc
, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT /*+ ORDERED */
       i.eadam_seq_id,
       'DEM' cpu_time_type,
       'AWR' cpu_time_source,
       'I' aggregate_level,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       peak.cpu_demand        peak_on_cpu,
       perc_99_99.cpu_demand  perc_99_99_on_cpu,
       perc_99_9.cpu_demand   perc_99_9_on_cpu,
       perc_99.cpu_demand     perc_99_on_cpu,
       perc_95.cpu_demand     perc_95_on_cpu,
       perc_90.cpu_demand     perc_90_on_cpu,
       perc_75.cpu_demand     perc_75_on_cpu,
       perc_50.cpu_demand     perc_50_on_cpu
  FROM my_instances i,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 1     )) peak,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.99  )) perc_99,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.95  )) perc_95,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.9   )) perc_90,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.75  )) perc_75,
       TABLE(eadam.cpu_demand_peak_awr(i.eadam_seq_id, i.inst_id, 0.50  )) perc_50
 WHERE perc_99_99.cpu_demand > 0
 UNION ALL
SELECT /*+ ORDERED */
       d.eadam_seq_id,
       'DEM' cpu_time_type,
       'AWR' cpu_time_source,
       'D' aggregate_level,
       d.dbid,
       d.db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       peak.cpu_demand        peak_on_cpu,
       perc_99_99.cpu_demand  perc_99_99_on_cpu,
       perc_99_9.cpu_demand   perc_99_9_on_cpu,
       perc_99.cpu_demand     perc_99_on_cpu,
       perc_95.cpu_demand     perc_95_on_cpu,
       perc_90.cpu_demand     perc_90_on_cpu,
       perc_75.cpu_demand     perc_75_on_cpu,
       perc_50.cpu_demand     perc_50_on_cpu
  FROM my_databases d,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 1     )) peak,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.99  )) perc_99,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.95  )) perc_95,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.9   )) perc_90,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.75  )) perc_75,
       TABLE(eadam.cpu_demand_peak_awr(d.eadam_seq_id, NULL, 0.50  )) perc_50
 WHERE perc_99_99.cpu_demand > 0
/

COMMIT;

SELECT * FROM cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'DEM' AND cpu_time_source = 'AWR'
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ cpu_demand_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO cpu_demand_series 
( eadam_seq_id        
, aggregate_level
, dbid                
, db_name             
, host_name           
, instance_number     
, instance_name       
, sample_time         
, snap_id             
, begin_interval_time 
, end_interval_time   
, begin_time          
, end_time            
, cpu_demand          
, on_cpu              
, waiting_for_cpu     
, cpu_demand_max
, cpu_demand_avg
, cpu_demand_med
, cpu_demand_min
, cpu_demand_99p
, cpu_demand_95p
, cpu_demand_90p
, cpu_demand_75p
)
SELECT
  &&eadam_seq_id. eadam_seq_id
, 'I' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.sample_time         
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.cpu_demand          
, s.on_cpu              
, s.waiting_for_cpu     
, x.cpu_demand_max
, x.cpu_demand_avg
, x.cpu_demand_med
, x.cpu_demand_min
, x.cpu_demand_99p
, x.cpu_demand_95p
, x.cpu_demand_90p
, x.cpu_demand_75p
FROM
(
SELECT
  s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.sample_time         
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.cpu_demand          
, s.on_cpu              
, s.waiting_for_cpu     
  FROM instances i, 
       TABLE(eadam.cpu_demand_awr(&&eadam_seq_id., i.instance_number, &&percentile.)) s
 WHERE i.eadam_seq_id = &&eadam_seq_id.
   AND s.dbid = &&eadam_dbid.
) s,
(
SELECT /*+ &&sq_fact_hints. */
  x.dbid                
, x.db_name             
, x.host_name           
, x.instance_number     
, x.instance_name       
, x.sample_time         
, x.snap_id             
, x.begin_interval_time 
, x.end_interval_time   
, x.begin_time          
, x.end_time            
, x.cpu_demand_max
, x.cpu_demand_avg
, x.cpu_demand_med
, x.cpu_demand_min
, x.cpu_demand_99p
, x.cpu_demand_95p
, x.cpu_demand_90p
, x.cpu_demand_75p
  FROM instances i, 
       TABLE(eadam.cpu_demand_mm_awr(&&eadam_seq_id., i.instance_number)) x
 WHERE i.eadam_seq_id = &&eadam_seq_id.
) x
 WHERE x.instance_number = s.instance_number 
   AND x.begin_time = s.begin_time
UNION ALL
SELECT
  &&eadam_seq_id. eadam_seq_id
, 'D' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.sample_time         
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.cpu_demand          
, s.on_cpu              
, s.waiting_for_cpu     
, x.cpu_demand_max
, x.cpu_demand_avg
, x.cpu_demand_med
, x.cpu_demand_min
, x.cpu_demand_99p
, x.cpu_demand_95p
, x.cpu_demand_90p
, x.cpu_demand_75p
FROM
(
SELECT
  s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.sample_time         
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.cpu_demand          
, s.on_cpu              
, s.waiting_for_cpu     
  FROM TABLE(eadam.cpu_demand_awr(&&eadam_seq_id., NULL, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
) s,
(
SELECT /*+ &&sq_fact_hints. */
  x.dbid                
, x.db_name             
, x.host_name           
, x.instance_number     
, x.instance_name       
, x.sample_time         
, x.snap_id             
, x.begin_interval_time 
, x.end_interval_time   
, x.begin_time          
, x.end_time            
, x.cpu_demand_max
, x.cpu_demand_avg
, x.cpu_demand_med
, x.cpu_demand_min
, x.cpu_demand_99p
, x.cpu_demand_95p
, x.cpu_demand_90p
, x.cpu_demand_75p
  FROM TABLE(eadam.cpu_demand_mm_awr(&&eadam_seq_id.)) x
) x
 WHERE x.begin_time = s.begin_time
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM cpu_demand_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'CON' AND cpu_time_source = 'AWR'
/

COMMIT;

INSERT INTO cpu_time
( eadam_seq_id      
, cpu_time_type     
, cpu_time_source   
, aggregate_level
, dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, aas_cpu_peak      
, aas_cpu_99_99_perc
, aas_cpu_99_9_perc 
, aas_cpu_99_perc   
, aas_cpu_95_perc   
, aas_cpu_90_perc   
, aas_cpu_75_perc   
, aas_cpu_50_perc   
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT /*+ ORDERED */
       i.eadam_seq_id,
       'CON' cpu_time_type,
       'AWR' cpu_time_source,
       'I' aggregate_level,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       peak.consumed_cpu        peak_on_cpu,
       perc_99_99.consumed_cpu  perc_99_99_on_cpu,
       perc_99_9.consumed_cpu   perc_99_9_on_cpu,
       perc_99.consumed_cpu     perc_99_on_cpu,
       perc_95.consumed_cpu     perc_95_on_cpu,
       perc_90.consumed_cpu     perc_90_on_cpu,
       perc_75.consumed_cpu     perc_75_on_cpu,
       perc_50.consumed_cpu     perc_50_on_cpu
  FROM my_instances i,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 1     )) peak,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.99  )) perc_99,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.95  )) perc_95,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.9   )) perc_90,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.75  )) perc_75,
       TABLE(eadam.cpu_consumption_peak_awr(i.eadam_seq_id, i.inst_id, 0.50  )) perc_50
 WHERE perc_99_99.consumed_cpu > 0
 UNION ALL
SELECT /*+ ORDERED */
       d.eadam_seq_id,
       'CON' cpu_time_type,
       'AWR' cpu_time_source,
       'D' aggregate_level,
       d.dbid,
       d.db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       peak.consumed_cpu        peak_on_cpu,
       perc_99_99.consumed_cpu  perc_99_99_on_cpu,
       perc_99_9.consumed_cpu   perc_99_9_on_cpu,
       perc_99.consumed_cpu     perc_99_on_cpu,
       perc_95.consumed_cpu     perc_95_on_cpu,
       perc_90.consumed_cpu     perc_90_on_cpu,
       perc_75.consumed_cpu     perc_75_on_cpu,
       perc_50.consumed_cpu     perc_50_on_cpu
  FROM my_databases d,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 1     )) peak,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.9999)) perc_99_99,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.999 )) perc_99_9,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.99  )) perc_99,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.95  )) perc_95,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.9   )) perc_90,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.75  )) perc_75,
       TABLE(eadam.cpu_consumption_peak_awr(d.eadam_seq_id, NULL, 0.50  )) perc_50
 WHERE perc_99_99.consumed_cpu > 0
/

COMMIT;

SELECT * FROM cpu_time WHERE eadam_seq_id = &&eadam_seq_id. AND cpu_time_type = 'CON' AND cpu_time_source = 'AWR'
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ cpu_consumption_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO cpu_consumption_series 
( eadam_seq_id        
, aggregate_level
, dbid                
, db_name             
, host_name           
, instance_number     
, instance_name       
, snap_id             
, begin_interval_time 
, end_interval_time   
, begin_time          
, end_time            
, consumed_cpu    
, background_cpu  
, db_cpu           
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT
  i.eadam_seq_id
, 'I' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.consumed_cpu    
, s.background_cpu  
, s.db_cpu           
  FROM my_instances i, TABLE(eadam.cpu_consumption_awr(&&eadam_seq_id., i.instance_number, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
 UNION ALL
SELECT 
  d.eadam_seq_id
, 'D' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.consumed_cpu    
, s.background_cpu  
, s.db_cpu           
  FROM my_databases d, TABLE(eadam.cpu_consumption_awr(&&eadam_seq_id., NULL, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM cpu_consumption_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE memory_size WHERE eadam_seq_id = &&eadam_seq_id. AND memory_source = 'MEM'
/

COMMIT;

INSERT INTO memory_size
( eadam_seq_id            
, memory_source           
, aggregate_level
, dbid                    
, db_name                 
, host_name               
, instance_number         
, instance_name           
, total_required          
, total_required_gb       
, memory_target           
, memory_target_gb        
, memory_max_target       
, memory_max_target_gb    
, sga_target              
, sga_target_gb           
, sga_max_size            
, sga_max_size_gb         
, max_sga_alloc           
, max_sga_alloc_gb        
, pga_aggregate_target    
, pga_aggregate_target_gb 
, max_pga_alloc           
, max_pga_alloc_gb        
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
),
par AS (
SELECT /*+ &&sq_fact_hints. */
       i.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       p.inst_id,
       SUM(CASE p.name WHEN 'memory_target' THEN TO_NUMBER(value) END) memory_target,
       SUM(CASE p.name WHEN 'memory_max_target' THEN TO_NUMBER(value) END) memory_max_target,
       SUM(CASE p.name WHEN 'sga_target' THEN TO_NUMBER(value) END) sga_target,
       SUM(CASE p.name WHEN 'sga_max_size' THEN TO_NUMBER(value) END) sga_max_size,
       SUM(CASE p.name WHEN 'pga_aggregate_target' THEN TO_NUMBER(value) END) pga_aggregate_target
  FROM my_instances i,
       gv_system_parameter2_s p
 WHERE p.eadam_seq_id = i.eadam_seq_id
   AND p.inst_id = i.inst_id 
   AND p.name IN ('memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 'pga_aggregate_target')
 GROUP BY
       i.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       p.inst_id
),
start_up AS (
SELECT /*+ &&sq_fact_hints. */
       dbid,
       instance_number,
       MAX(startup_time) max_startup_time
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 GROUP BY
       dbid,
       instance_number
),
snap_id_from AS (
SELECT /*+ &&sq_fact_hints. */
       s.dbid,
       s.instance_number,
       MIN(s.snap_id) min_snap_id
  FROM dba_hist_snapshot_s s,
       start_up u
 WHERE s.eadam_seq_id = &&eadam_seq_id.
   AND s.dbid = &&eadam_dbid.
   AND s.dbid = u.dbid
   AND s.instance_number = u.instance_number
   AND s.startup_time = u.max_startup_time
 GROUP BY
       s.dbid,
       s.instance_number
),
sga_per_snap AS (
SELECT /*+ &&sq_fact_hints. */
       h.dbid,
       h.instance_number,
       h.snap_id,
       SUM(h.value) sga
  FROM dba_hist_sga_s h,
       snap_id_from s
 WHERE h.eadam_seq_id = &&eadam_seq_id.
   AND h.dbid = &&eadam_dbid.
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
   AND h.snap_id >= s.min_snap_id
 GROUP BY
       h.dbid,
       h.instance_number,
       h.snap_id
),
sga_max AS (
SELECT /*+ &&sq_fact_hints. */
       dbid,
       instance_number,
       MAX(sga) bytes
  FROM sga_per_snap
 GROUP BY
       dbid,
       instance_number
),
pga_max AS (
SELECT /*+ &&sq_fact_hints. */
       h.dbid,
       h.instance_number,
       MAX(h.value) bytes
  FROM dba_hist_pgastat_s h,
       snap_id_from s
 WHERE h.eadam_seq_id = &&eadam_seq_id.
   AND h.dbid = &&eadam_dbid.
   AND h.name = 'maximum PGA allocated'
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
   AND h.snap_id >= s.min_snap_id
 GROUP BY
       h.dbid,
       h.instance_number
),
pga AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.inst_id,
       par.pga_aggregate_target,
       pga_max.bytes max_bytes,
       GREATEST(NVL(par.pga_aggregate_target, 0), NVL(pga_max.bytes, 0)) bytes
  FROM par,
       pga_max
 WHERE par.instance_number = pga_max.instance_number(+)
),
amm AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.inst_id,
       par.memory_target,
       par.memory_max_target,
       GREATEST(NVL(par.memory_target, 0), NVL(par.memory_max_target, 0)) + (6 * 1024 * 1024) bytes
  FROM par
),
asmm AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.inst_id,
       par.sga_target,
       par.sga_max_size,
       pga.bytes pga_bytes,
       GREATEST(NVL(par.sga_target, 0), NVL(par.sga_max_size, 0)) + NVL(pga.bytes, 0) + (6 * 1024 * 1024) bytes
  FROM par,
       pga
 WHERE par.instance_number = pga.instance_number
),
no_mm AS (
SELECT /*+ &&sq_fact_hints. */
       pga.eadam_seq_id,
       pga.dbid,
       pga.db_name,
       pga.host_name,
       pga.instance_number,
       pga.instance_name,
       pga.inst_id,
       sga_max.bytes max_sga,
       pga.bytes max_pga,
       pga.pga_aggregate_target,
       sga_max.bytes + NVL(pga.bytes, 0) + (5 * 1024 * 1024) bytes
  FROM sga_max,
       pga
 WHERE sga_max.instance_number(+) = pga.instance_number
),
them_all AS (
SELECT /*+ &&sq_fact_hints. */
       amm.eadam_seq_id,
       amm.dbid,
       amm.db_name,
       amm.host_name,
       amm.instance_number,
       amm.instance_name,
       amm.inst_id,
       GREATEST(NVL(amm.bytes, 0), NVL(asmm.bytes, 0), NVL(no_mm.bytes, 0)) bytes,
       amm.memory_target,
       amm.memory_max_target,
       asmm.sga_target,
       asmm.sga_max_size,
       no_mm.max_sga,
       no_mm.pga_aggregate_target,
       no_mm.max_pga
  FROM amm,
       asmm,
       no_mm
 WHERE asmm.instance_number = amm.instance_number
   AND no_mm.instance_number = amm.instance_number
)
SELECT eadam_seq_id,
       'MEM' memory_source,
       'I' aggregate_level,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name,
       bytes total_required,
       ROUND(bytes/POWER(2,30),3) total_required_gb,
       memory_target,
       ROUND(memory_target/POWER(2,30),3) memory_target_gb,
       memory_max_target,
       ROUND(memory_max_target/POWER(2,30),3) memory_max_target_gb,
       sga_target,
       ROUND(sga_target/POWER(2,30),3) sga_target_gb,
       sga_max_size,
       ROUND(sga_max_size/POWER(2,30),3) sga_max_size_gb,
       max_sga max_sga_alloc,
       ROUND(max_sga/POWER(2,30),3) max_sga_alloc_gb,
       pga_aggregate_target,
       ROUND(pga_aggregate_target/POWER(2,30),3) pga_aggregate_target_gb,
       max_pga max_pga_alloc,
       ROUND(max_pga/POWER(2,30),3) max_pga_alloc_gb
  FROM them_all
 UNION ALL
SELECT MIN(eadam_seq_id) eadam_seq_id,
       'MEM' memory_source,
       'D' aggregate_level,
       MIN(dbid) dbid,
       MIN(db_name) db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       SUM(bytes) total_required,
       ROUND(SUM(bytes)/POWER(2,30),3) total_required_gb,
       SUM(memory_target) memory_target,
       ROUND(SUM(memory_target)/POWER(2,30),3) memory_target_gb,
       SUM(memory_max_target) memory_max_target,
       ROUND(SUM(memory_max_target)/POWER(2,30),3) memory_max_target_gb,
       SUM(sga_target) sga_target,
       ROUND(SUM(sga_target)/POWER(2,30),3) sga_target_gb,
       SUM(sga_max_size) sga_max_size,
       ROUND(SUM(sga_max_size)/POWER(2,30),3) sga_max_size_gb,
       SUM(max_sga) max_sga_alloc,
       ROUND(SUM(max_sga)/POWER(2,30),3) max_sga_alloc_gb,
       SUM(pga_aggregate_target) pga_aggregate_target,
       ROUND(SUM(pga_aggregate_target)/POWER(2,30),3) pga_aggregate_target_gb,
       SUM(max_pga) max_pga_alloc,
       ROUND(SUM(max_pga)/POWER(2,30),3) max_pga_alloc_gb
  FROM them_all
/

COMMIT;

SELECT * FROM memory_size WHERE eadam_seq_id = &&eadam_seq_id. AND memory_source = 'MEM'
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE memory_size WHERE eadam_seq_id = &&eadam_seq_id. AND memory_source = 'AWR'
/

COMMIT;

INSERT INTO memory_size
( eadam_seq_id            
, memory_source           
, aggregate_level
, dbid                    
, db_name                 
, host_name               
, instance_number         
, instance_name           
, total_required          
, total_required_gb       
, memory_target           
, memory_target_gb        
, memory_max_target       
, memory_max_target_gb    
, sga_target              
, sga_target_gb           
, sga_max_size            
, sga_max_size_gb         
, max_sga_alloc           
, max_sga_alloc_gb        
, pga_aggregate_target    
, pga_aggregate_target_gb 
, max_pga_alloc           
, max_pga_alloc_gb        
)
WITH
max_snap AS (
SELECT /*+ &&sq_fact_hints. */
       MAX(snap_id) snap_id,
       dbid,
       instance_number,
       parameter_name
  FROM dba_hist_parameter_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND parameter_name IN ('memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 'pga_aggregate_target')
   AND (snap_id, dbid, instance_number) IN (SELECT s.snap_id, s.dbid, s.instance_number FROM dba_hist_snapshot_s s WHERE s.eadam_seq_id = &&eadam_seq_id. AND s.dbid = &&eadam_dbid.)
 GROUP BY
       dbid,
       instance_number,
       parameter_name
),
last_value AS (
SELECT /*+ &&sq_fact_hints. */
       s.snap_id,
       s.dbid,
       s.instance_number,
       s.parameter_name,
       p.value
  FROM max_snap s,
       dba_hist_parameter_s p
 WHERE p.eadam_seq_id = &&eadam_seq_id.
   AND p.dbid = &&eadam_dbid.
   AND p.snap_id = s.snap_id
   AND p.dbid = s.dbid
   AND p.instance_number = s.instance_number
   AND p.parameter_name = s.parameter_name
),
last_snap AS (
SELECT /*+ &&sq_fact_hints. */
       p.snap_id,
       p.dbid,
       p.instance_number,
       p.parameter_name,
       p.value,
       s.startup_time
  FROM last_value p,
       dba_hist_snapshot_s s
 WHERE s.eadam_seq_id = &&eadam_seq_id.
   AND s.dbid = &&eadam_dbid.
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
),
par AS (
SELECT /*+ &&sq_fact_hints. */
       di.eadam_seq_id,
       p.dbid,
       di.db_name,
       di.host_name,
       p.instance_number,
       di.instance_name,
       SUM(CASE p.parameter_name WHEN 'memory_target' THEN TO_NUMBER(p.value) ELSE 0 END) memory_target,
       SUM(CASE p.parameter_name WHEN 'memory_max_target' THEN TO_NUMBER(p.value) ELSE 0 END) memory_max_target,
       SUM(CASE p.parameter_name WHEN 'sga_target' THEN TO_NUMBER(p.value) ELSE 0 END) sga_target,
       SUM(CASE p.parameter_name WHEN 'sga_max_size' THEN TO_NUMBER(p.value) ELSE 0 END) sga_max_size,
       SUM(CASE p.parameter_name WHEN 'pga_aggregate_target' THEN TO_NUMBER(p.value) ELSE 0 END) pga_aggregate_target
  FROM last_snap p,
       dba_hist_database_instanc_s di
 WHERE di.eadam_seq_id = &&eadam_seq_id.
   AND di.dbid = &&eadam_dbid.
   AND di.dbid = p.dbid
   AND di.instance_number = p.instance_number
   AND di.startup_time = p.startup_time
 GROUP BY
       di.eadam_seq_id,
       p.dbid,
       di.db_name,
       di.host_name,
       p.instance_number,
       di.instance_name
),
sgainfo AS (
SELECT /*+ &&sq_fact_hints. */
       eadam_seq_id,
       snap_id,
       dbid,
       instance_number,
       SUM(value) sga_size
  FROM dba_hist_sga_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 GROUP BY
       eadam_seq_id,
       snap_id,
       dbid,
       instance_number
),
sga_max AS (
SELECT /*+ &&sq_fact_hints. */
       dbid,
       instance_number,
       MAX(sga_size) bytes
  FROM sgainfo
 GROUP BY
       dbid,
       instance_number
),
pga_max AS (
SELECT /*+ &&sq_fact_hints. */
       dbid,
       instance_number,
       MAX(value) bytes
  FROM dba_hist_pgastat_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND name = 'maximum PGA allocated'
 GROUP BY
       dbid,
       instance_number
),
pga AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.pga_aggregate_target,
       pga_max.bytes max_bytes,
       GREATEST(NVL(par.pga_aggregate_target, 0), NVL(pga_max.bytes, 0)) bytes
  FROM pga_max,
       par
 WHERE par.dbid = pga_max.dbid
   AND par.instance_number = pga_max.instance_number
),
amm AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.memory_target,
       par.memory_max_target,
       GREATEST(NVL(par.memory_target, 0), NVL(par.memory_max_target, 0)) + (6 * 1024 * 1024) bytes
  FROM par
),
asmm AS (
SELECT /*+ &&sq_fact_hints. */
       par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.sga_target,
       par.sga_max_size,
       pga.bytes pga_bytes,
       GREATEST(NVL(par.sga_target, 0), NVL(par.sga_max_size, 0)) + NVL(pga.bytes, 0) + (6 * 1024 * 1024) bytes
  FROM pga,
       par
 WHERE par.dbid = pga.dbid
   AND par.instance_number = pga.instance_number
),
no_mm AS (
SELECT /*+ &&sq_fact_hints. */
       pga.eadam_seq_id,
       pga.dbid,
       pga.db_name,
       pga.host_name,
       pga.instance_number,
       pga.instance_name,
       sga_max.bytes max_sga,
       pga.bytes max_pga,
       pga.pga_aggregate_target,
       sga_max.bytes + pga.bytes + (5 * 1024 * 1024) bytes
  FROM pga,
       sga_max
 WHERE sga_max.dbid = pga.dbid
   AND sga_max.instance_number = pga.instance_number
),
them_all AS (
SELECT /*+ &&sq_fact_hints. */
       amm.eadam_seq_id,
       amm.dbid,
       amm.db_name,
       amm.host_name,
       amm.instance_number,
       amm.instance_name,
       GREATEST(NVL(amm.bytes, 0), NVL(asmm.bytes, 0), NVL(no_mm.bytes, 0)) bytes,
       amm.memory_target,
       amm.memory_max_target,
       asmm.sga_target,
       asmm.sga_max_size,
       no_mm.max_sga,
       no_mm.pga_aggregate_target,
       no_mm.max_pga
  FROM amm,
       asmm,
       no_mm
 WHERE asmm.instance_number = amm.instance_number
   AND asmm.dbid = amm.dbid
   AND no_mm.instance_number = amm.instance_number
   AND no_mm.dbid = amm.dbid
)
SELECT eadam_seq_id,
       'AWR' memory_source,
       'I' aggregate_level,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name,
       bytes total_required,
       ROUND(bytes/POWER(2,30),3) total_required_gb,
       memory_target,
       ROUND(memory_target/POWER(2,30),3) memory_target_gb,
       memory_max_target,
       ROUND(memory_max_target/POWER(2,30),3) memory_max_target_gb,
       sga_target,
       ROUND(sga_target/POWER(2,30),3) sga_target_gb,
       sga_max_size,
       ROUND(sga_max_size/POWER(2,30),3) sga_max_size_gb,
       max_sga max_sga_alloc,
       ROUND(max_sga/POWER(2,30),3) max_sga_alloc_gb,
       pga_aggregate_target,
       ROUND(pga_aggregate_target/POWER(2,30),3) pga_aggregate_target_gb,
       max_pga max_pga_alloc,
       ROUND(max_pga/POWER(2,30),3) max_pga_alloc_gb
  FROM them_all
 UNION ALL
SELECT MIN(eadam_seq_id) eadam_seq_id,
       'AWR' memory_source,
       'D' aggregate_level,
       MIN(dbid) dbid,
       MIN(db_name) db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       SUM(bytes) total_required,
       ROUND(SUM(bytes)/POWER(2,30),3) total_required_gb,
       SUM(memory_target) memory_target,
       ROUND(SUM(memory_target)/POWER(2,30),3) memory_target_gb,
       SUM(memory_max_target) memory_max_target,
       ROUND(SUM(memory_max_target)/POWER(2,30),3) memory_max_target_gb,
       SUM(sga_target) sga_target,
       ROUND(SUM(sga_target)/POWER(2,30),3) sga_target_gb,
       SUM(sga_max_size) sga_max_size,
       ROUND(SUM(sga_max_size)/POWER(2,30),3) sga_max_size_gb,
       SUM(max_sga) max_sga_alloc,
       ROUND(SUM(max_sga)/POWER(2,30),3) max_sga_alloc_gb,
       SUM(pga_aggregate_target) pga_aggregate_target,
       ROUND(SUM(pga_aggregate_target)/POWER(2,30),3) pga_aggregate_target_gb,
       SUM(max_pga) max_pga_alloc,
       ROUND(SUM(max_pga)/POWER(2,30),3) max_pga_alloc_gb
  FROM them_all
/

COMMIT;

SELECT * FROM memory_size WHERE eadam_seq_id = &&eadam_seq_id. AND memory_source = 'AWR'
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ memory_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO memory_series 
( eadam_seq_id        
, aggregate_level
, dbid                
, db_name             
, host_name           
, instance_number     
, instance_name       
, snap_id             
, begin_interval_time 
, end_interval_time   
, begin_time          
, end_time            
, mem_gb
, sga_gb
, pga_gb
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT
  i.eadam_seq_id
, 'I' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.mem_gb
, s.sga_gb
, s.pga_gb
  FROM my_instances i, TABLE(eadam.memory_usage_awr(&&eadam_seq_id., i.instance_number)) s
 WHERE s.dbid = &&eadam_dbid.
 UNION ALL
SELECT 
  d.eadam_seq_id
, 'D' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.mem_gb
, s.sga_gb
, s.pga_gb
  FROM my_databases d, TABLE(eadam.memory_usage_awr(&&eadam_seq_id.)) s
 WHERE s.dbid = &&eadam_dbid.
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM memory_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE database_size WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO database_size
( eadam_seq_id
, dbid        
, db_name     
, file_type   
, size_bytes  
, size_gb     
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
),
sizes AS (
SELECT /*+ &&sq_fact_hints. */
       'Data' file_type,
       SUM(bytes) bytes
  FROM v_datafile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 UNION ALL
SELECT 'Temp' file_type,
       SUM(bytes) bytes
  FROM v_tempfile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 UNION ALL
SELECT 'Log' file_type,
       SUM(bytes) * MAX(members) bytes
  FROM gv_log_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 UNION ALL
SELECT 'Control' file_type,
       SUM(block_size * file_size_blks) bytes
  FROM v_controlfile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
),
dbsize AS (
SELECT /*+ &&sq_fact_hints. */
       'Total' file_type,
       SUM(bytes) bytes
  FROM sizes
)
SELECT d.eadam_seq_id,
       d.dbid,
       d.db_name,
       s.file_type,
       s.bytes,
       ROUND(s.bytes/POWER(2,30),3) gb
  FROM my_databases d,
       sizes s
 UNION ALL
SELECT d.eadam_seq_id,
       d.dbid,
       d.db_name,
       s.file_type,
       s.bytes,
       ROUND(s.bytes/POWER(2,30),3) gb
  FROM my_databases d,
       dbsize s
/

COMMIT;

SELECT * FROM database_size WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE iops_and_mbps WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO iops_and_mbps
( eadam_seq_id      
, aggregate_level
, dbid              
, db_name           
, host_name         
, instance_number   
, instance_name     
, rw_iops_peak      
, r_iops_peak       
, w_iops_peak       
, rw_mbps_peak      
, r_mbps_peak       
, w_mbps_peak       
, rw_iops_perc_99_99
, r_iops_perc_99_99 
, w_iops_perc_99_99 
, rw_mbps_perc_99_99
, r_mbps_perc_99_99 
, w_mbps_perc_99_99 
, rw_iops_perc_99_9 
, r_iops_perc_99_9  
, w_iops_perc_99_9  
, rw_mbps_perc_99_9 
, r_mbps_perc_99_9  
, w_mbps_perc_99_9  
, rw_iops_perc_99   
, r_iops_perc_99    
, w_iops_perc_99    
, rw_mbps_perc_99   
, r_mbps_perc_99    
, w_mbps_perc_99    
, rw_iops_perc_95   
, r_iops_perc_95    
, w_iops_perc_95    
, rw_mbps_perc_95   
, r_mbps_perc_95    
, w_mbps_perc_95    
, rw_iops_perc_90   
, r_iops_perc_90    
, w_iops_perc_90    
, rw_mbps_perc_90   
, r_mbps_perc_90    
, w_mbps_perc_90    
, rw_iops_perc_75   
, r_iops_perc_75    
, w_iops_perc_75    
, rw_mbps_perc_75   
, r_mbps_perc_75    
, w_mbps_perc_75    
, rw_iops_perc_50   
, r_iops_perc_50    
, w_iops_perc_50    
, rw_mbps_perc_50   
, r_mbps_perc_50    
, w_mbps_perc_50    
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT /*+ ORDERED */
       i.eadam_seq_id,
       'I' aggregate_level,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       io_peak.rw_iops        rw_iops_peak,
       io_peak.r_iops         r_iops_peak,
       io_peak.w_iops         w_iops_peak,
       mb_peak.rw_mbps        rw_mbps_peak,
       mb_peak.r_mbps         r_mbps_peak,
       mb_peak.w_mbps         w_mbps_peak,
       io_perc_99_99.rw_iops  rw_iops_perc_99_99,
       io_perc_99_99.r_iops   r_iops_perc_99_99,
       io_perc_99_99.w_iops   w_iops_perc_99_99,
       mb_perc_99_99.rw_mbps  rw_mbps_perc_99_99,
       mb_perc_99_99.r_mbps   r_mbps_perc_99_99,
       mb_perc_99_99.w_mbps   w_mbps_perc_99_99,
       io_perc_99_9.rw_iops   rw_iops_perc_99_9,
       io_perc_99_9.r_iops    r_iops_perc_99_9,
       io_perc_99_9.w_iops    w_iops_perc_99_9,
       mb_perc_99_9.rw_mbps   rw_mbps_perc_99_9,
       mb_perc_99_9.r_mbps    r_mbps_perc_99_9,
       mb_perc_99_9.w_mbps    w_mbps_perc_99_9,
       io_perc_99.rw_iops     rw_iops_perc_99,
       io_perc_99.r_iops      r_iops_perc_99,
       io_perc_99.w_iops      w_iops_perc_99,
       mb_perc_99.rw_mbps     rw_mbps_perc_99,
       mb_perc_99.r_mbps      r_mbps_perc_99,
       mb_perc_99.w_mbps      w_mbps_perc_99,
       io_perc_95.rw_iops     rw_iops_perc_95,
       io_perc_95.r_iops      r_iops_perc_95,
       io_perc_95.w_iops      w_iops_perc_95,
       mb_perc_95.rw_mbps     rw_mbps_perc_95,
       mb_perc_95.r_mbps      r_mbps_perc_95,
       mb_perc_95.w_mbps      w_mbps_perc_95,
       io_perc_90.rw_iops     rw_iops_perc_90,
       io_perc_90.r_iops      r_iops_perc_90,
       io_perc_90.w_iops      w_iops_perc_90,
       mb_perc_90.rw_mbps     rw_mbps_perc_90,
       mb_perc_90.r_mbps      r_mbps_perc_90,
       mb_perc_90.w_mbps      w_mbps_perc_90,
       io_perc_75.rw_iops     rw_iops_perc_75,
       io_perc_75.r_iops      r_iops_perc_75,
       io_perc_75.w_iops      w_iops_perc_75,
       mb_perc_75.rw_mbps     rw_mbps_perc_75,
       mb_perc_75.r_mbps      r_mbps_perc_75,
       mb_perc_75.w_mbps      w_mbps_perc_75,
       io_perc_50.rw_iops     rw_iops_perc_50,
       io_perc_50.r_iops      r_iops_perc_50,
       io_perc_50.w_iops      w_iops_perc_50,
       mb_perc_50.rw_mbps     rw_mbps_perc_50,
       mb_perc_50.r_mbps      r_mbps_perc_50,
       mb_perc_50.w_mbps      w_mbps_perc_50
  FROM my_instances i,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 1     )) io_peak,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.9999)) io_perc_99_99,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.999 )) io_perc_99_9,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.99  )) io_perc_99,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.95  )) io_perc_95,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.9   )) io_perc_90,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.75  )) io_perc_75,
       TABLE(eadam.iops_peak(i.eadam_seq_id, i.inst_id, 0.50  )) io_perc_50,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 1     )) mb_peak,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.9999)) mb_perc_99_99,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.999 )) mb_perc_99_9,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.99  )) mb_perc_99,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.95  )) mb_perc_95,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.9   )) mb_perc_90,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.75  )) mb_perc_75,
       TABLE(eadam.mbps_peak(i.eadam_seq_id, i.inst_id, 0.50  )) mb_perc_50
 WHERE io_perc_99_99.rw_iops > 0
 UNION ALL
SELECT /*+ ORDERED */
       d.eadam_seq_id,
       'D' aggregate_level,
       d.dbid,
       d.db_name,
       '-1' host_name,
       -1 instance_number,
       '-1' instance_name,
       io_peak.rw_iops        rw_iops_peak,
       io_peak.r_iops         r_iops_peak,
       io_peak.w_iops         w_iops_peak,
       mb_peak.rw_mbps        rw_mbps_peak,
       mb_peak.r_mbps         r_mbps_peak,
       mb_peak.w_mbps         w_mbps_peak,
       io_perc_99_99.rw_iops  rw_iops_perc_99_99,
       io_perc_99_99.r_iops   r_iops_perc_99_99,
       io_perc_99_99.w_iops   w_iops_perc_99_99,
       mb_perc_99_99.rw_mbps  rw_mbps_perc_99_99,
       mb_perc_99_99.r_mbps   r_mbps_perc_99_99,
       mb_perc_99_99.w_mbps   w_mbps_perc_99_99,
       io_perc_99_9.rw_iops   rw_iops_perc_99_9,
       io_perc_99_9.r_iops    r_iops_perc_99_9,
       io_perc_99_9.w_iops    w_iops_perc_99_9,
       mb_perc_99_9.rw_mbps   rw_mbps_perc_99_9,
       mb_perc_99_9.r_mbps    r_mbps_perc_99_9,
       mb_perc_99_9.w_mbps    w_mbps_perc_99_9,
       io_perc_99.rw_iops     rw_iops_perc_99,
       io_perc_99.r_iops      r_iops_perc_99,
       io_perc_99.w_iops      w_iops_perc_99,
       mb_perc_99.rw_mbps     rw_mbps_perc_99,
       mb_perc_99.r_mbps      r_mbps_perc_99,
       mb_perc_99.w_mbps      w_mbps_perc_99,
       io_perc_95.rw_iops     rw_iops_perc_95,
       io_perc_95.r_iops      r_iops_perc_95,
       io_perc_95.w_iops      w_iops_perc_95,
       mb_perc_95.rw_mbps     rw_mbps_perc_95,
       mb_perc_95.r_mbps      r_mbps_perc_95,
       mb_perc_95.w_mbps      w_mbps_perc_95,
       io_perc_90.rw_iops     rw_iops_perc_90,
       io_perc_90.r_iops      r_iops_perc_90,
       io_perc_90.w_iops      w_iops_perc_90,
       mb_perc_90.rw_mbps     rw_mbps_perc_90,
       mb_perc_90.r_mbps      r_mbps_perc_90,
       mb_perc_90.w_mbps      w_mbps_perc_90,
       io_perc_75.rw_iops     rw_iops_perc_75,
       io_perc_75.r_iops      r_iops_perc_75,
       io_perc_75.w_iops      w_iops_perc_75,
       mb_perc_75.rw_mbps     rw_mbps_perc_75,
       mb_perc_75.r_mbps      r_mbps_perc_75,
       mb_perc_75.w_mbps      w_mbps_perc_75,
       io_perc_50.rw_iops     rw_iops_perc_50,
       io_perc_50.r_iops      r_iops_perc_50,
       io_perc_50.w_iops      w_iops_perc_50,
       mb_perc_50.rw_mbps     rw_mbps_perc_50,
       mb_perc_50.r_mbps      r_mbps_perc_50,
       mb_perc_50.w_mbps      w_mbps_perc_50
  FROM my_databases d,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 1     )) io_peak,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.9999)) io_perc_99_99,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.999 )) io_perc_99_9,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.99  )) io_perc_99,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.95  )) io_perc_95,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.9   )) io_perc_90,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.75  )) io_perc_75,
       TABLE(eadam.iops_peak(d.eadam_seq_id, NULL, 0.50  )) io_perc_50,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 1     )) mb_peak,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.9999)) mb_perc_99_99,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.999 )) mb_perc_99_9,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.99  )) mb_perc_99,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.95  )) mb_perc_95,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.9   )) mb_perc_90,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.75  )) mb_perc_75,
       TABLE(eadam.mbps_peak(d.eadam_seq_id, NULL, 0.50  )) mb_perc_50
 WHERE io_perc_99_99.rw_iops > 0
/

COMMIT;

SELECT * FROM iops_and_mbps WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ iops_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO iops_series 
( eadam_seq_id        
, aggregate_level
, dbid                
, db_name             
, host_name           
, instance_number     
, instance_name       
, snap_id             
, begin_interval_time 
, end_interval_time   
, begin_time          
, end_time            
, rw_iops
, r_iops 
, w_iops 
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT
  i.eadam_seq_id
, 'I' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.rw_iops
, s.r_iops 
, s.w_iops 
  FROM my_instances i, TABLE(eadam.iops(&&eadam_seq_id., i.instance_number, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
 UNION ALL
SELECT 
  d.eadam_seq_id
, 'D' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.rw_iops
, s.r_iops 
, s.w_iops 
  FROM my_databases d, TABLE(eadam.iops(&&eadam_seq_id., NULL, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM iops_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ mbps_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO mbps_series 
( eadam_seq_id        
, aggregate_level
, dbid                
, db_name             
, host_name           
, instance_number     
, instance_name       
, snap_id             
, begin_interval_time 
, end_interval_time   
, begin_time          
, end_time            
, rw_mbps
, r_mbps 
, w_mbps 
)
WITH
my_instances AS (
SELECT /*+ &&sq_fact_hints. */ *
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
),
my_databases AS (
SELECT /*+ &&sq_fact_hints. */
       DISTINCT
       eadam_seq_id,
       dbid,
       db_name
  FROM my_instances
)
SELECT
  i.eadam_seq_id
, 'I' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.rw_mbps
, s.r_mbps 
, s.w_mbps 
  FROM my_instances i, TABLE(eadam.mbps(&&eadam_seq_id., i.instance_number, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
 UNION ALL
SELECT 
  d.eadam_seq_id
, 'D' aggregate_level
, s.dbid                
, s.db_name             
, s.host_name           
, s.instance_number     
, s.instance_name       
, s.snap_id             
, s.begin_interval_time 
, s.end_interval_time   
, s.begin_time          
, s.end_time            
, s.rw_mbps
, s.r_mbps 
, s.w_mbps 
  FROM my_databases d, TABLE(eadam.mbps(&&eadam_seq_id., NULL, &&percentile.)) s
 WHERE s.dbid = &&eadam_dbid.
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM mbps_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE /*+ PARALLEL(4) */ FROM time_series WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT /*+ APPEND PARALLEL(4) */ INTO time_series 
( eadam_seq_id       
, aggregate_level
, dbid               
, db_name            
, host_name          
, instance_number    
, instance_name      
, begin_time         
, end_time           
-- cpu demand
, cpu_demand         
, on_cpu             
, waiting_for_cpu    
, cpu_demand_max
, cpu_demand_avg
, cpu_demand_med
, cpu_demand_min
, cpu_demand_99p
, cpu_demand_95p
, cpu_demand_90p
, cpu_demand_75p
-- cpu consumption
, consumed_cpu       
, background_cpu     
, db_cpu             
-- memory
, mem_gb             
, sga_gb             
, pga_gb             
-- iops
, rw_iops            
, r_iops             
, w_iops    
-- mbps         
, rw_mbps            
, r_mbps             
, w_mbps             
)
WITH
my_time AS (
SELECT /*+ &&sq_fact_hints. PARALLEL(4) */
  eadam_seq_id   
, aggregate_level
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, begin_time     
, end_time       
  FROM cpu_demand_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 UNION
SELECT /*+ &&sq_fact_hints. PARALLEL(4) */
  eadam_seq_id   
, aggregate_level
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, begin_time     
, end_time       
  FROM cpu_consumption_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 UNION
SELECT /*+ &&sq_fact_hints. PARALLEL(4) */
  eadam_seq_id   
, aggregate_level
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, begin_time     
, end_time       
  FROM memory_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 UNION
SELECT /*+ &&sq_fact_hints. PARALLEL(4) */
  eadam_seq_id   
, aggregate_level
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, begin_time     
, end_time       
  FROM iops_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 UNION
SELECT /*+ &&sq_fact_hints. PARALLEL(4) */
  eadam_seq_id   
, aggregate_level
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
, begin_time     
, end_time       
  FROM mbps_series
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
)
SELECT /*+ PARALLEL(4) */ 
  t.eadam_seq_id   
, t.aggregate_level
, t.dbid           
, t.db_name        
, t.host_name      
, t.instance_number
, t.instance_name  
, t.begin_time     
, t.end_time 
, NVL(s1.cpu_demand, 0)      cpu_demand
, NVL(s1.on_cpu, 0)          on_cpu
, NVL(s1.waiting_for_cpu, 0) waiting_for_cpu
, NVL(s1.cpu_demand_max, 0)  cpu_demand_max
, NVL(s1.cpu_demand_avg, 0)  cpu_demand_avg
, NVL(s1.cpu_demand_med, 0)  cpu_demand_med
, NVL(s1.cpu_demand_min, 0)  cpu_demand_min
, NVL(s1.cpu_demand_99p, 0)  cpu_demand_99p
, NVL(s1.cpu_demand_95p, 0)  cpu_demand_95p
, NVL(s1.cpu_demand_90p, 0)  cpu_demand_90p
, NVL(s1.cpu_demand_75p, 0)  cpu_demand_75p
, NVL(s2.consumed_cpu, 0)    consumed_cpu
, NVL(s2.background_cpu, 0)  background_cpu
, NVL(s2.db_cpu, 0)          db_cpu
, NVL(s3.mem_gb, 0)          mem_gb
, NVL(s3.sga_gb, 0)          sga_gb
, NVL(s3.pga_gb, 0)          pga_gb
, NVL(s4.rw_iops, 0)         rw_iops
, NVL(s4.r_iops, 0)          r_iops
, NVL(s4.w_iops, 0)          w_iops
, NVL(s5.rw_mbps, 0)         rw_mbps
, NVL(s5.r_mbps, 0)          r_mbps
, NVL(s5.w_mbps, 0)          w_mbps
  FROM my_time t,
       cpu_demand_series s1,
       cpu_consumption_series s2,
       memory_series s3,
       iops_series s4,
       mbps_series s5
 WHERE s1.eadam_seq_id(+)    = t.eadam_seq_id   
   AND s1.dbid(+)            = t.dbid           
   AND s1.db_name(+)         = t.db_name        
   AND s1.host_name(+)       = t.host_name      
   AND s1.instance_number(+) = t.instance_number
   AND s1.instance_name(+)   = t.instance_name  
   AND s1.begin_time(+)      = t.begin_time     
   AND s1.end_time(+)        = t.end_time 
   AND s2.eadam_seq_id(+)    = t.eadam_seq_id   
   AND s2.dbid(+)            = t.dbid           
   AND s2.db_name(+)         = t.db_name        
   AND s2.host_name(+)       = t.host_name      
   AND s2.instance_number(+) = t.instance_number
   AND s2.instance_name(+)   = t.instance_name  
   AND s2.begin_time(+)      = t.begin_time     
   AND s2.end_time(+)        = t.end_time       
   AND s3.eadam_seq_id(+)    = t.eadam_seq_id   
   AND s3.dbid(+)            = t.dbid           
   AND s3.db_name(+)         = t.db_name        
   AND s3.host_name(+)       = t.host_name      
   AND s3.instance_number(+) = t.instance_number
   AND s3.instance_name(+)   = t.instance_name  
   AND s3.begin_time(+)      = t.begin_time     
   AND s3.end_time(+)        = t.end_time       
   AND s4.eadam_seq_id(+)    = t.eadam_seq_id   
   AND s4.dbid(+)            = t.dbid           
   AND s4.db_name(+)         = t.db_name        
   AND s4.host_name(+)       = t.host_name      
   AND s4.instance_number(+) = t.instance_number
   AND s4.instance_name(+)   = t.instance_name  
   AND s4.begin_time(+)      = t.begin_time     
   AND s4.end_time(+)        = t.end_time       
   AND s5.eadam_seq_id(+)    = t.eadam_seq_id   
   AND s5.dbid(+)            = t.dbid           
   AND s5.db_name(+)         = t.db_name        
   AND s5.host_name(+)       = t.host_name      
   AND s5.instance_number(+) = t.instance_number
   AND s5.instance_name(+)   = t.instance_name  
   AND s5.begin_time(+)      = t.begin_time     
   AND s5.end_time(+)        = t.end_time       
/

COMMIT;

SELECT /*+ PARALLEL(4) */ COUNT(*) FROM time_series WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE FROM instances WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO instances
( eadam_seq_id       
, dbid               
, db_name            
, host_name          
, instance_number    
, instance_name      
, inst_id
-- cpu time (DEM)and MEM
, aas_cpu_peak_dem_mem       
, aas_cpu_99_99_perc_dem_mem 
, aas_cpu_99_9_perc_dem_mem  
, aas_cpu_99_perc_dem_mem    
, aas_cpu_95_perc_dem_mem    
, aas_cpu_90_perc_dem_mem    
, aas_cpu_75_perc_dem_mem    
, aas_cpu_50_perc_dem_mem    
-- cpu time (DEM)and AWR
, aas_cpu_peak_dem_awr       
, aas_cpu_99_99_perc_dem_awr 
, aas_cpu_99_9_perc_dem_awr  
, aas_cpu_99_perc_dem_awr    
, aas_cpu_95_perc_dem_awr    
, aas_cpu_90_perc_dem_awr    
, aas_cpu_75_perc_dem_awr    
, aas_cpu_50_perc_dem_awr    
-- cpu time (CON)sumption AWR
, aas_cpu_peak_con_awr       
, aas_cpu_99_99_perc_con_awr 
, aas_cpu_99_9_perc_con_awr  
, aas_cpu_99_perc_con_awr    
, aas_cpu_95_perc_con_awr    
, aas_cpu_90_perc_con_awr    
, aas_cpu_75_perc_con_awr    
, aas_cpu_50_perc_con_awr    
-- memory size MEM
, mem_total_required_mem         
, mem_total_required_gb_mem      
, memory_target_mem          
, memory_target_gb_mem       
, memory_max_target_mem      
, memory_max_target_gb_mem       
, sga_target_mem             
, sga_target_gb_mem          
, sga_max_size_mem           
, sga_max_size_gb_mem        
, max_sga_alloc_mem          
, max_sga_alloc_gb_mem       
, pga_aggregate_target_mem   
, pga_aggregate_target_gb_mem
, max_pga_alloc_mem          
, max_pga_alloc_gb_mem       
-- memory size AWR
, mem_total_required_awr         
, mem_total_required_gb_awr      
, memory_target_awr          
, memory_target_gb_awr       
, memory_max_target_awr      
, memory_max_target_gb_awr       
, sga_target_awr             
, sga_target_gb_awr          
, sga_max_size_awr           
, sga_max_size_gb_awr        
, max_sga_alloc_awr          
, max_sga_alloc_gb_awr       
, pga_aggregate_target_awr   
, pga_aggregate_target_gb_awr
, max_pga_alloc_awr          
, max_pga_alloc_gb_awr       
-- disk throughput
, rw_iops_peak            
, r_iops_peak             
, w_iops_peak             
, rw_mbps_peak            
, r_mbps_peak             
, w_mbps_peak             
, rw_iops_perc_99_99      
, r_iops_perc_99_99       
, w_iops_perc_99_99       
, rw_mbps_perc_99_99      
, r_mbps_perc_99_99       
, w_mbps_perc_99_99       
, rw_iops_perc_99_9       
, r_iops_perc_99_9        
, w_iops_perc_99_9        
, rw_mbps_perc_99_9       
, r_mbps_perc_99_9        
, w_mbps_perc_99_9        
, rw_iops_perc_99         
, r_iops_perc_99          
, w_iops_perc_99          
, rw_mbps_perc_99         
, r_mbps_perc_99          
, w_mbps_perc_99          
, rw_iops_perc_95         
, r_iops_perc_95          
, w_iops_perc_95          
, rw_mbps_perc_95         
, r_mbps_perc_95          
, w_mbps_perc_95          
, rw_iops_perc_90         
, r_iops_perc_90          
, w_iops_perc_90          
, rw_mbps_perc_90         
, r_mbps_perc_90          
, w_mbps_perc_90          
, rw_iops_perc_75         
, r_iops_perc_75          
, w_iops_perc_75          
, rw_mbps_perc_75         
, r_mbps_perc_75          
, w_mbps_perc_75          
, rw_iops_perc_50         
, r_iops_perc_50          
, w_iops_perc_50          
, rw_mbps_perc_50         
, r_mbps_perc_50          
, w_mbps_perc_50          
)
WITH
i2 AS (
SELECT /*+ PARALLEL(4) */ DISTINCT
       TO_NUMBER(value) instance_number,
       inst_id
  FROM gv_system_parameter2_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND name = 'instance_number'
),
my_instances AS (
SELECT /*+ &&sq_fact_hints. */
  eadam_seq_id   
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
  FROM cpu_time
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND aggregate_level = 'I'
 UNION
SELECT /*+ &&sq_fact_hints. */
  eadam_seq_id   
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
  FROM memory_size
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND aggregate_level = 'I'
 UNION
SELECT /*+ &&sq_fact_hints. */
  eadam_seq_id   
, dbid           
, db_name        
, host_name      
, instance_number
, instance_name  
  FROM iops_and_mbps
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
   AND aggregate_level = 'I'
)
SELECT 
  i.eadam_seq_id   
, i.dbid           
, i.db_name        
, i.host_name      
, i.instance_number
, i.instance_name  
, NVL(i2.inst_id, i.instance_number) inst_id
-- cpu time (DEM)and MEM
, c1.aas_cpu_peak       aas_cpu_peak_dem_mem       
, c1.aas_cpu_99_99_perc aas_cpu_99_99_perc_dem_mem 
, c1.aas_cpu_99_9_perc  aas_cpu_99_9_perc_dem_mem  
, c1.aas_cpu_99_perc    aas_cpu_99_perc_dem_mem    
, c1.aas_cpu_95_perc    aas_cpu_95_perc_dem_mem    
, c1.aas_cpu_90_perc    aas_cpu_90_perc_dem_mem    
, c1.aas_cpu_75_perc    aas_cpu_75_perc_dem_mem    
, c1.aas_cpu_50_perc    aas_cpu_50_perc_dem_mem    
-- cpu time (DEM)and AWR
, c2.aas_cpu_peak       aas_cpu_peak_dem_awr       
, c2.aas_cpu_99_99_perc aas_cpu_99_99_perc_dem_awr 
, c2.aas_cpu_99_9_perc  aas_cpu_99_9_perc_dem_awr  
, c2.aas_cpu_99_perc    aas_cpu_99_perc_dem_awr    
, c2.aas_cpu_95_perc    aas_cpu_95_perc_dem_awr    
, c2.aas_cpu_90_perc    aas_cpu_90_perc_dem_awr    
, c2.aas_cpu_75_perc    aas_cpu_75_perc_dem_awr    
, c2.aas_cpu_50_perc    aas_cpu_50_perc_dem_awr    
-- cpu time (CON)sumption AWR
, c3.aas_cpu_peak       aas_cpu_peak_con_awr       
, c3.aas_cpu_99_99_perc aas_cpu_99_99_perc_con_awr 
, c3.aas_cpu_99_9_perc  aas_cpu_99_9_perc_con_awr  
, c3.aas_cpu_99_perc    aas_cpu_99_perc_con_awr    
, c3.aas_cpu_95_perc    aas_cpu_95_perc_con_awr    
, c3.aas_cpu_90_perc    aas_cpu_90_perc_con_awr    
, c3.aas_cpu_75_perc    aas_cpu_75_perc_con_awr    
, c3.aas_cpu_50_perc    aas_cpu_50_perc_con_awr    
-- memory size MEM
, m1.total_required          mem_total_required_mem          
, m1.total_required_gb       mem_total_required_gb_mem       
, m1.memory_target           memory_target_mem           
, m1.memory_target_gb        memory_target_gb_mem        
, m1.memory_max_target       memory_max_target_mem       
, m1.memory_max_target_gb    memory_max_target_gb_mem    
, m1.sga_target              sga_target_mem              
, m1.sga_target_gb           sga_target_gb_mem           
, m1.sga_max_size            sga_max_size_mem            
, m1.sga_max_size_gb         sga_max_size_gb_mem         
, m1.max_sga_alloc           max_sga_alloc_mem           
, m1.max_sga_alloc_gb        max_sga_alloc_gb_mem        
, m1.pga_aggregate_target    pga_aggregate_target_mem    
, m1.pga_aggregate_target_gb pga_aggregate_target_gb_mem 
, m1.max_pga_alloc           max_pga_alloc_mem           
, m1.max_pga_alloc_gb        max_pga_alloc_gb_mem        
-- memory size AWR
, m2.total_required          mem_total_required_awr          
, m2.total_required_gb       mem_total_required_gb_awr       
, m2.memory_target           memory_target_awr           
, m2.memory_target_gb        memory_target_gb_awr        
, m2.memory_max_target       memory_max_target_awr       
, m2.memory_max_target_gb    memory_max_target_gb_awr    
, m2.sga_target              sga_target_awr              
, m2.sga_target_gb           sga_target_gb_awr           
, m2.sga_max_size            sga_max_size_awr            
, m2.sga_max_size_gb         sga_max_size_gb_awr         
, m2.max_sga_alloc           max_sga_alloc_awr           
, m2.max_sga_alloc_gb        max_sga_alloc_gb_awr        
, m2.pga_aggregate_target    pga_aggregate_target_awr    
, m2.pga_aggregate_target_gb pga_aggregate_target_gb_awr 
, m2.max_pga_alloc           max_pga_alloc_awr           
, m2.max_pga_alloc_gb        max_pga_alloc_gb_awr        
-- disk throughput
, io.rw_iops_peak            
, io.r_iops_peak             
, io.w_iops_peak             
, io.rw_mbps_peak            
, io.r_mbps_peak             
, io.w_mbps_peak             
, io.rw_iops_perc_99_99      
, io.r_iops_perc_99_99       
, io.w_iops_perc_99_99       
, io.rw_mbps_perc_99_99      
, io.r_mbps_perc_99_99       
, io.w_mbps_perc_99_99       
, io.rw_iops_perc_99_9       
, io.r_iops_perc_99_9        
, io.w_iops_perc_99_9        
, io.rw_mbps_perc_99_9       
, io.r_mbps_perc_99_9        
, io.w_mbps_perc_99_9        
, io.rw_iops_perc_99         
, io.r_iops_perc_99          
, io.w_iops_perc_99          
, io.rw_mbps_perc_99         
, io.r_mbps_perc_99          
, io.w_mbps_perc_99          
, io.rw_iops_perc_95         
, io.r_iops_perc_95          
, io.w_iops_perc_95          
, io.rw_mbps_perc_95         
, io.r_mbps_perc_95          
, io.w_mbps_perc_95          
, io.rw_iops_perc_90         
, io.r_iops_perc_90          
, io.w_iops_perc_90          
, io.rw_mbps_perc_90         
, io.r_mbps_perc_90          
, io.w_mbps_perc_90          
, io.rw_iops_perc_75         
, io.r_iops_perc_75          
, io.w_iops_perc_75          
, io.rw_mbps_perc_75         
, io.r_mbps_perc_75          
, io.w_mbps_perc_75          
, io.rw_iops_perc_50         
, io.r_iops_perc_50          
, io.w_iops_perc_50          
, io.rw_mbps_perc_50         
, io.r_mbps_perc_50          
, io.w_mbps_perc_50          
  FROM my_instances i,
       i2,
       cpu_time c1,
       cpu_time c2,
       cpu_time c3,
       memory_size m1,
       memory_size m2,
       iops_and_mbps io
 WHERE i2.instance_number(+) = i.instance_number
   AND c1.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c1.dbid(+)            = i.dbid           
   AND c1.db_name(+)         = i.db_name        
   AND c1.host_name(+)       = i.host_name      
   AND c1.instance_number(+) = i.instance_number
   AND c1.instance_name(+)   = i.instance_name  
   AND c1.cpu_time_type(+)   = 'DEM'
   AND c1.cpu_time_source(+) = 'MEM'
   AND c1.aggregate_level(+) = 'I'
   AND c2.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c2.dbid(+)            = i.dbid           
   AND c2.db_name(+)         = i.db_name        
   AND c2.host_name(+)       = i.host_name      
   AND c2.instance_number(+) = i.instance_number
   AND c2.instance_name(+)   = i.instance_name  
   AND c2.cpu_time_type(+)   = 'DEM'
   AND c2.cpu_time_source(+) = 'AWR'
   AND c2.aggregate_level(+) = 'I'
   AND c3.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c3.dbid(+)            = i.dbid           
   AND c3.db_name(+)         = i.db_name        
   AND c3.host_name(+)       = i.host_name      
   AND c3.instance_number(+) = i.instance_number
   AND c3.instance_name(+)   = i.instance_name  
   AND c3.cpu_time_type(+)   = 'CON'
   AND c3.cpu_time_source(+) = 'AWR'
   AND c3.aggregate_level(+) = 'I'
   AND m1.eadam_seq_id(+)    = i.eadam_seq_id   
   AND m1.dbid(+)            = i.dbid           
   AND m1.db_name(+)         = i.db_name        
   AND m1.host_name(+)       = i.host_name      
   AND m1.instance_number(+) = i.instance_number
   AND m1.instance_name(+)   = i.instance_name  
   AND m1.memory_source(+)   = 'MEM'
   AND m1.aggregate_level(+) = 'I'
   AND m2.eadam_seq_id(+)    = i.eadam_seq_id   
   AND m2.dbid(+)            = i.dbid           
   AND m2.db_name(+)         = i.db_name        
   AND m2.host_name(+)       = i.host_name      
   AND m2.instance_number(+) = i.instance_number
   AND m2.instance_name(+)   = i.instance_name  
   AND m2.memory_source(+)   = 'AWR'
   AND m2.aggregate_level(+) = 'I'
   AND io.eadam_seq_id(+)    = i.eadam_seq_id   
   AND io.dbid(+)            = i.dbid           
   AND io.db_name(+)         = i.db_name        
   AND io.host_name(+)       = i.host_name      
   AND io.instance_number(+) = i.instance_number
   AND io.instance_name(+)   = i.instance_name  
   AND io.aggregate_level(+) = 'I'
/

COMMIT;

SELECT * FROM instances WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

/* ------------------------------------------------------------------------- */

DELETE databases WHERE eadam_seq_id = &&eadam_seq_id.
/

COMMIT;

INSERT INTO databases
( eadam_seq_id       
, dbid               
, db_name            
, host_name_src      
, db_unique_name     
, platform_name      
, version            
-- cpu time (DEM)and MEM
, aas_cpu_peak_dem_mem       
, aas_cpu_99_99_perc_dem_mem 
, aas_cpu_99_9_perc_dem_mem  
, aas_cpu_99_perc_dem_mem    
, aas_cpu_95_perc_dem_mem    
, aas_cpu_90_perc_dem_mem    
, aas_cpu_75_perc_dem_mem    
, aas_cpu_50_perc_dem_mem    
-- cpu time (DEM)and AWR
, aas_cpu_peak_dem_awr       
, aas_cpu_99_99_perc_dem_awr 
, aas_cpu_99_9_perc_dem_awr  
, aas_cpu_99_perc_dem_awr    
, aas_cpu_95_perc_dem_awr    
, aas_cpu_90_perc_dem_awr    
, aas_cpu_75_perc_dem_awr    
, aas_cpu_50_perc_dem_awr    
-- cpu time (CON)sumption AWR
, aas_cpu_peak_con_awr       
, aas_cpu_99_99_perc_con_awr 
, aas_cpu_99_9_perc_con_awr  
, aas_cpu_99_perc_con_awr    
, aas_cpu_95_perc_con_awr    
, aas_cpu_90_perc_con_awr    
, aas_cpu_75_perc_con_awr    
, aas_cpu_50_perc_con_awr    
-- memory size MEM
, mem_total_required_mem         
, mem_total_required_gb_mem      
, memory_target_mem          
, memory_target_gb_mem       
, memory_max_target_mem      
, memory_max_target_gb_mem     
, sga_target_mem             
, sga_target_gb_mem          
, sga_max_size_mem           
, sga_max_size_gb_mem        
, max_sga_alloc_mem          
, max_sga_alloc_gb_mem       
, pga_aggregate_target_mem   
, pga_aggregate_target_gb_mem
, max_pga_alloc_mem          
, max_pga_alloc_gb_mem       
-- memory size AWR
, mem_total_required_awr         
, mem_total_required_gb_awr      
, memory_target_awr          
, memory_target_gb_awr       
, memory_max_target_awr      
, memory_max_target_gb_awr     
, sga_target_awr             
, sga_target_gb_awr          
, sga_max_size_awr           
, sga_max_size_gb_awr        
, max_sga_alloc_awr          
, max_sga_alloc_gb_awr       
, pga_aggregate_target_awr   
, pga_aggregate_target_gb_awr
, max_pga_alloc_awr          
, max_pga_alloc_gb_awr       
-- database size 
, db_total_size_bytes     
, db_total_size_gb        
, db_data_size_bytes      
, db_data_size_gb         
, db_temp_size_bytes      
, db_temp_size_gb         
, db_log_size_bytes       
, db_log_size_gb          
, db_control_size_bytes   
, db_control_size_gb      
-- disk throughput
, rw_iops_peak            
, r_iops_peak             
, w_iops_peak             
, rw_mbps_peak            
, r_mbps_peak             
, w_mbps_peak             
, rw_iops_perc_99_99      
, r_iops_perc_99_99       
, w_iops_perc_99_99       
, rw_mbps_perc_99_99      
, r_mbps_perc_99_99       
, w_mbps_perc_99_99       
, rw_iops_perc_99_9       
, r_iops_perc_99_9        
, w_iops_perc_99_9        
, rw_mbps_perc_99_9       
, r_mbps_perc_99_9        
, w_mbps_perc_99_9        
, rw_iops_perc_99         
, r_iops_perc_99          
, w_iops_perc_99          
, rw_mbps_perc_99         
, r_mbps_perc_99          
, w_mbps_perc_99          
, rw_iops_perc_95         
, r_iops_perc_95          
, w_iops_perc_95          
, rw_mbps_perc_95         
, r_mbps_perc_95          
, w_mbps_perc_95          
, rw_iops_perc_90         
, r_iops_perc_90          
, w_iops_perc_90          
, rw_mbps_perc_90         
, r_mbps_perc_90          
, w_mbps_perc_90          
, rw_iops_perc_75         
, r_iops_perc_75          
, w_iops_perc_75          
, rw_mbps_perc_75         
, r_mbps_perc_75          
, w_mbps_perc_75          
, rw_iops_perc_50         
, r_iops_perc_50          
, w_iops_perc_50          
, rw_mbps_perc_50         
, r_mbps_perc_50          
, w_mbps_perc_50          
)
WITH
ctrl AS (
SELECT
  eadam_seq_id  
, dbid          
, SUBSTR(dbname, 1, 9)          db_name       
, SUBSTR(host_name, 1, 64)      host_name_src
, SUBSTR(db_unique_name, 1, 30) db_unique_name
, SUBSTR(platform_name, 1, 101) platform_name
, SUBSTR(version, 1, 17)        version     
  FROM dba_hist_xtr_control_s
 WHERE eadam_seq_id = &&eadam_seq_id.
),
sizes AS (
SELECT 
  eadam_seq_id
, dbid        
, db_name     
, SUM(CASE file_type WHEN 'Total' THEN size_bytes ELSE 0 END)   db_total_size_bytes
, SUM(CASE file_type WHEN 'Total' THEN size_gb ELSE 0 END)      db_total_size_gb
, SUM(CASE file_type WHEN 'Data' THEN size_bytes ELSE 0 END)    db_data_size_bytes
, SUM(CASE file_type WHEN 'Data' THEN size_gb ELSE 0 END)       db_data_size_gb
, SUM(CASE file_type WHEN 'Temp' THEN size_bytes ELSE 0 END)    db_temp_size_bytes
, SUM(CASE file_type WHEN 'Temp' THEN size_gb ELSE 0 END)       db_temp_size_gb
, SUM(CASE file_type WHEN 'Log' THEN size_bytes ELSE 0 END)     db_log_size_bytes
, SUM(CASE file_type WHEN 'Log' THEN size_gb ELSE 0 END)        db_log_size_gb
, SUM(CASE file_type WHEN 'Control' THEN size_bytes ELSE 0 END) db_control_size_bytes
, SUM(CASE file_type WHEN 'Control' THEN size_gb ELSE 0 END)    db_control_size_gb
  FROM database_size
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 GROUP BY
  eadam_seq_id
, dbid        
, db_name     
),
inst AS (
SELECT
  eadam_seq_id
, dbid        
, db_name     
-- memory size MEM 
, SUM(mem_total_required_mem      ) mem_total_required_mem         
, SUM(mem_total_required_gb_mem   ) mem_total_required_gb_mem      
, SUM(memory_target_mem           ) memory_target_mem          
, SUM(memory_target_gb_mem        ) memory_target_gb_mem       
, SUM(memory_max_target_mem       ) memory_max_target_mem      
, SUM(memory_max_target_gb_mem    ) memory_max_target_gb_mem      
, SUM(sga_target_mem              ) sga_target_mem             
, SUM(sga_target_gb_mem           ) sga_target_gb_mem          
, SUM(sga_max_size_mem            ) sga_max_size_mem           
, SUM(sga_max_size_gb_mem         ) sga_max_size_gb_mem        
, SUM(max_sga_alloc_mem           ) max_sga_alloc_mem          
, SUM(max_sga_alloc_gb_mem        ) max_sga_alloc_gb_mem       
, SUM(pga_aggregate_target_mem    ) pga_aggregate_target_mem   
, SUM(pga_aggregate_target_gb_mem ) pga_aggregate_target_gb_mem
, SUM(max_pga_alloc_mem           ) max_pga_alloc_mem          
, SUM(max_pga_alloc_gb_mem        ) max_pga_alloc_gb_mem       
-- memory size AWR
, SUM(mem_total_required_awr      ) mem_total_required_awr         
, SUM(mem_total_required_gb_awr   ) mem_total_required_gb_awr      
, SUM(memory_target_awr           ) memory_target_awr          
, SUM(memory_target_gb_awr        ) memory_target_gb_awr       
, SUM(memory_max_target_awr       ) memory_max_target_awr      
, SUM(memory_max_target_gb_awr    ) memory_max_target_gb_awr      
, SUM(sga_target_awr              ) sga_target_awr             
, SUM(sga_target_gb_awr           ) sga_target_gb_awr          
, SUM(sga_max_size_awr            ) sga_max_size_awr           
, SUM(sga_max_size_gb_awr         ) sga_max_size_gb_awr        
, SUM(max_sga_alloc_awr           ) max_sga_alloc_awr          
, SUM(max_sga_alloc_gb_awr        ) max_sga_alloc_gb_awr       
, SUM(pga_aggregate_target_awr    ) pga_aggregate_target_awr   
, SUM(pga_aggregate_target_gb_awr ) pga_aggregate_target_gb_awr
, SUM(max_pga_alloc_awr           ) max_pga_alloc_awr          
, SUM(max_pga_alloc_gb_awr        ) max_pga_alloc_gb_awr       
  FROM instances
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND dbid = &&eadam_dbid.
 GROUP BY
  eadam_seq_id
, dbid        
, db_name     
)
SELECT
  c.eadam_seq_id       
, c.dbid               
, c.db_name            
, c.host_name_src      
, c.db_unique_name     
, c.platform_name      
, c.version            
-- cpu time (DEM)and MEM
, c1.aas_cpu_peak       aas_cpu_peak_dem_mem       
, c1.aas_cpu_99_99_perc aas_cpu_99_99_perc_dem_mem 
, c1.aas_cpu_99_9_perc  aas_cpu_99_9_perc_dem_mem  
, c1.aas_cpu_99_perc    aas_cpu_99_perc_dem_mem    
, c1.aas_cpu_95_perc    aas_cpu_95_perc_dem_mem    
, c1.aas_cpu_90_perc    aas_cpu_90_perc_dem_mem    
, c1.aas_cpu_75_perc    aas_cpu_75_perc_dem_mem    
, c1.aas_cpu_50_perc    aas_cpu_50_perc_dem_mem    
-- cpu time (DEM)and AWR
, c2.aas_cpu_peak       aas_cpu_peak_dem_awr       
, c2.aas_cpu_99_99_perc aas_cpu_99_99_perc_dem_awr 
, c2.aas_cpu_99_9_perc  aas_cpu_99_9_perc_dem_awr  
, c2.aas_cpu_99_perc    aas_cpu_99_perc_dem_awr    
, c2.aas_cpu_95_perc    aas_cpu_95_perc_dem_awr    
, c2.aas_cpu_90_perc    aas_cpu_90_perc_dem_awr    
, c2.aas_cpu_75_perc    aas_cpu_75_perc_dem_awr    
, c2.aas_cpu_50_perc    aas_cpu_50_perc_dem_awr    
-- cpu time (CON)sumption AWR
, c3.aas_cpu_peak       aas_cpu_peak_con_awr       
, c3.aas_cpu_99_99_perc aas_cpu_99_99_perc_con_awr 
, c3.aas_cpu_99_9_perc  aas_cpu_99_9_perc_con_awr  
, c3.aas_cpu_99_perc    aas_cpu_99_perc_con_awr    
, c3.aas_cpu_95_perc    aas_cpu_95_perc_con_awr    
, c3.aas_cpu_90_perc    aas_cpu_90_perc_con_awr    
, c3.aas_cpu_75_perc    aas_cpu_75_perc_con_awr    
, c3.aas_cpu_50_perc    aas_cpu_50_perc_con_awr    
-- memory size MEM
, i.mem_total_required_mem         
, i.mem_total_required_gb_mem      
, i.memory_target_mem          
, i.memory_target_gb_mem       
, i.memory_max_target_mem      
, i.memory_max_target_gb_mem      
, i.sga_target_mem             
, i.sga_target_gb_mem          
, i.sga_max_size_mem           
, i.sga_max_size_gb_mem        
, i.max_sga_alloc_mem          
, i.max_sga_alloc_gb_mem       
, i.pga_aggregate_target_mem   
, i.pga_aggregate_target_gb_mem
, i.max_pga_alloc_mem          
, i.max_pga_alloc_gb_mem       
-- memory size AWR
, i.mem_total_required_awr         
, i.mem_total_required_gb_awr      
, i.memory_target_awr          
, i.memory_target_gb_awr       
, i.memory_max_target_awr      
, i.memory_max_target_gb_awr      
, i.sga_target_awr             
, i.sga_target_gb_awr          
, i.sga_max_size_awr           
, i.sga_max_size_gb_awr        
, i.max_sga_alloc_awr          
, i.max_sga_alloc_gb_awr       
, i.pga_aggregate_target_awr   
, i.pga_aggregate_target_gb_awr
, i.max_pga_alloc_awr          
, i.max_pga_alloc_gb_awr       
-- database size 
, s.db_total_size_bytes     
, s.db_total_size_gb        
, s.db_data_size_bytes      
, s.db_data_size_gb         
, s.db_temp_size_bytes      
, s.db_temp_size_gb         
, s.db_log_size_bytes       
, s.db_log_size_gb          
, s.db_control_size_bytes   
, s.db_control_size_gb      
-- disk throughput
, io.rw_iops_peak            
, io.r_iops_peak             
, io.w_iops_peak             
, io.rw_mbps_peak            
, io.r_mbps_peak             
, io.w_mbps_peak             
, io.rw_iops_perc_99_99      
, io.r_iops_perc_99_99       
, io.w_iops_perc_99_99       
, io.rw_mbps_perc_99_99      
, io.r_mbps_perc_99_99       
, io.w_mbps_perc_99_99       
, io.rw_iops_perc_99_9       
, io.r_iops_perc_99_9        
, io.w_iops_perc_99_9        
, io.rw_mbps_perc_99_9       
, io.r_mbps_perc_99_9        
, io.w_mbps_perc_99_9        
, io.rw_iops_perc_99         
, io.r_iops_perc_99          
, io.w_iops_perc_99          
, io.rw_mbps_perc_99         
, io.r_mbps_perc_99          
, io.w_mbps_perc_99          
, io.rw_iops_perc_95         
, io.r_iops_perc_95          
, io.w_iops_perc_95          
, io.rw_mbps_perc_95         
, io.r_mbps_perc_95          
, io.w_mbps_perc_95          
, io.rw_iops_perc_90         
, io.r_iops_perc_90          
, io.w_iops_perc_90          
, io.rw_mbps_perc_90         
, io.r_mbps_perc_90          
, io.w_mbps_perc_90          
, io.rw_iops_perc_75         
, io.r_iops_perc_75          
, io.w_iops_perc_75          
, io.rw_mbps_perc_75         
, io.r_mbps_perc_75          
, io.w_mbps_perc_75          
, io.rw_iops_perc_50         
, io.r_iops_perc_50          
, io.w_iops_perc_50          
, io.rw_mbps_perc_50         
, io.r_mbps_perc_50          
, io.w_mbps_perc_50          
  FROM ctrl c,
       sizes s,
       inst i,
       cpu_time c1,
       cpu_time c2,
       cpu_time c3,
       iops_and_mbps io
 WHERE c1.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c1.dbid(+)            = i.dbid           
   AND c1.db_name(+)         = i.db_name        
   AND c1.host_name(+)       = '-1'      
   AND c1.instance_number(+) = -1
   AND c1.instance_name(+)   = '-1'  
   AND c1.cpu_time_type(+)   = 'DEM'
   AND c1.cpu_time_source(+) = 'MEM'
   AND c1.aggregate_level(+) = 'D'
   AND c2.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c2.dbid(+)            = i.dbid           
   AND c2.db_name(+)         = i.db_name        
   AND c2.host_name(+)       = '-1'      
   AND c2.instance_number(+) = -1
   AND c2.instance_name(+)   = '-1'  
   AND c2.cpu_time_type(+)   = 'DEM'
   AND c2.cpu_time_source(+) = 'AWR'
   AND c2.aggregate_level(+) = 'D'
   AND c3.eadam_seq_id(+)    = i.eadam_seq_id   
   AND c3.dbid(+)            = i.dbid           
   AND c3.db_name(+)         = i.db_name        
   AND c3.host_name(+)       = '-1'      
   AND c3.instance_number(+) = -1
   AND c3.instance_name(+)   = '-1' 
   AND c3.cpu_time_type(+)   = 'CON'
   AND c3.cpu_time_source(+) = 'AWR'
   AND c3.aggregate_level(+) = 'D'
   AND io.eadam_seq_id(+)    = i.eadam_seq_id   
   AND io.dbid(+)            = i.dbid           
   AND io.db_name(+)         = i.db_name        
   AND io.host_name(+)       = '-1'      
   AND io.instance_number(+) = -1
   AND io.instance_name(+)   = '-1'  
   AND io.aggregate_level(+) = 'D'
/

COMMIT;

SELECT * FROM databases WHERE eadam_seq_id = &&eadam_seq_id.
/

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

PRO Row Count for EADAM
PRO ~~~~~~~~~
SET SERVEROUT ON;
DECLARE
  l_row_count NUMBER;
BEGIN
  FOR i IN (SELECT table_name FROM user_tables WHERE table_name NOT LIKE '%\_E' ESCAPE '\' ORDER BY table_name)
  LOOP
    EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL(4) */ COUNT(*) FROM '||i.table_name INTO l_row_count;
    DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_row_count, '999,999,999,990'), 17)||'  '||i.table_name);
  END LOOP;
END;
/
SET SERVEROUT OFF;

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

PRO Row Count for EADAM_SEQ_ID "&&eadam_seq_id."
PRO ~~~~~~~~~
SET SERVEROUT ON;
DECLARE
  l_row_count NUMBER;
BEGIN
  FOR i IN (SELECT table_name FROM user_tab_columns WHERE column_name = 'EADAM_SEQ_ID' ORDER BY table_name)
  LOOP
    EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL(4) */ COUNT(*) FROM '||i.table_name||' WHERE eadam_seq_id = &&eadam_seq_id.' INTO l_row_count;
    DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_row_count, '999,999,999,990'), 17)||'  '||i.table_name);
  END LOOP;
END;
/
SET SERVEROUT OFF;

SPO eadam_08_xso_&&eadam_seq_id..txt APP;

PRO Row Count for EADAM_SEQ_ID "&&eadam_seq_id." and DBID = "&&eadam_dbid."
PRO ~~~~~~~~~
SET SERVEROUT ON;
DECLARE
  l_row_count NUMBER;
BEGIN
  FOR i IN (SELECT s.table_name FROM user_tab_columns s, user_tab_columns d  WHERE s.column_name = 'EADAM_SEQ_ID' AND d.column_name = 'DBID' AND d.table_name = s.table_name ORDER BY s.table_name)
  LOOP
    EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL(4) */ COUNT(*) FROM '||i.table_name||' WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid.' INTO l_row_count;
    DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_row_count, '999,999,999,990'), 17)||'  '||i.table_name);
  END LOOP;
END;
/
SET SERVEROUT OFF;

WHENEVER SQLERROR CONTINUE;
SPO eadam_08_xso_&&eadam_seq_id..txt APP;

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
PRO
PRO eadam_seq_id: &&eadam_seq_id.

/* ------------------------------------------------------------------------- */

SPO OFF;
