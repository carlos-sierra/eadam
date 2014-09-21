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

/* ------------------------------------------------------------------------- */

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

CREATE OR REPLACE VIEW database_instance_v AS
WITH
last_snap_num_cpus AS (
SELECT eadam_seq_id,
       instance_number,
       MAX(snap_id) snap_id
  FROM dba_hist_osstat_s
 WHERE stat_name = 'NUM_CPUS'
 GROUP BY
       eadam_seq_id,
       instance_number
),
last_num_cpus AS (
SELECT h.eadam_seq_id,
       h.instance_number,
       h.value num_cpus
  FROM last_snap_num_cpus l,
       dba_hist_osstat_s h
 WHERE h.stat_name = 'NUM_CPUS'
   AND h.eadam_seq_id = l.eadam_seq_id
   AND h.instance_number = l.instance_number
   AND h.snap_id = l.snap_id
),
last_startup_time AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       instance_name,
       MAX(startup_time) startup_time
  FROM dba_hist_database_instanc_s
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       instance_name
),
last_host AS (
SELECT h.eadam_seq_id,
       h.dbid,
       h.instance_number,
       h.instance_name,
       SUBSTR(h.host_name, 1, 64) host_name
  FROM dba_hist_database_instanc_s h,
       last_startup_time s
 WHERE s.eadam_seq_id = h.eadam_seq_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND s.instance_name = h.instance_name
   AND s.startup_time = h.startup_time
)
SELECT c.eadam_seq_id,
       c.dbid,
       SUBSTR(c.dbname, 1, 9) db_name,
       SUBSTR(c.db_unique_name, 1, 30) db_unique_name,
       i1.inst_id,
       CASE TO_NUMBER(i1.value) WHEN 0 THEN i1.inst_id ELSE TO_NUMBER(i1.value) END instance_number,
       SUBSTR(i2.value, 1, 16) instance_name,
       SUBSTR(NVL(
       (SELECT h.host_name
          FROM last_host h
         WHERE h.eadam_seq_id    = c.eadam_seq_id
           AND h.dbid            = c.dbid
           AND h.instance_number = TO_NUMBER(i1.value)
           AND h.instance_name   = i2.value), host_name
       ), 1, 64) host_name,
       COALESCE(TO_NUMBER(i3.value), lc.num_cpus, 0) cpu_count,
       SUBSTR(c.platform_name, 1, 101) platform_name,
       SUBSTR(c.version, 1, 17) version,
       SUBSTR(c.host_name, 1, 64) host_name_src
  FROM dba_hist_xtr_control_s c,
       gv_system_parameter2_s i1,
       gv_system_parameter2_s i2,
       gv_system_parameter2_s i3,
       last_num_cpus          lc
 WHERE i1.eadam_seq_id       = c.eadam_seq_id 
   AND i1.name               = 'instance_number'
   AND i2.eadam_seq_id       = i1.eadam_seq_id 
   AND i2.name               = 'instance_name'
   AND i2.inst_id            = i1.inst_id
   AND i3.eadam_seq_id(+)    = i1.eadam_seq_id /* old eadam versions did not extract cpu_count */
   AND i3.name(+)            = 'cpu_count'
   AND i3.inst_id(+)         = i1.inst_id
   AND lc.eadam_seq_id(+)    = i1.eadam_seq_id 
   AND lc.instance_number(+) = TO_NUMBER(i1.value)
/

GRANT SELECT ON database_instance_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_database_instance_v FOR database_instance_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW database_v AS
SELECT eadam_seq_id,
       dbid,
       db_name,
       db_unique_name,
       platform_name,
       version,
       host_name_src,
       COUNT(*) instances,
       SUM(cpu_count) cpu_count
  FROM database_instance_v
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name,
       db_unique_name,
       platform_name,
       version,
       host_name_src
/

GRANT SELECT ON database_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_database_v FOR database_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW cpu_demand_mem_v AS
WITH 
samples_on_cpu AS (
SELECT eadam_seq_id,
       inst_id,
       sample_id,
       COUNT(*) aas_on_cpu_and_resmgr,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) aas_on_cpu,
       SUM(CASE event WHEN 'resmgr:cpu quantum' THEN 1 ELSE 0 END) aas_resmgr_cpu_quantum       
  FROM gv_active_session_history_s
 WHERE (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum')
 GROUP BY
       eadam_seq_id,
       inst_id,
       sample_id
),
sub_totals AS (
SELECT c.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       i.cpu_count,
       MAX(c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_peak,
       MAX(c.aas_on_cpu) aas_on_cpu_peak,
       MAX(c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_peak,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_9999,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_9999,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_9999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_999,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_99,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_99,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_99,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_95,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_95,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_95,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_90,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_90,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_90,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_75,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_75,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_75,
       MEDIAN(c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_median,
       MEDIAN(c.aas_on_cpu) aas_on_cpu_median,
       MEDIAN(c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_median,
       ROUND(AVG(c.aas_on_cpu_and_resmgr), 1) aas_on_cpu_and_resmgr_avg,
       ROUND(AVG(c.aas_on_cpu), 1) aas_on_cpu_avg,
       ROUND(AVG(c.aas_resmgr_cpu_quantum), 1) aas_resmgr_cpu_quantum_avg
  FROM samples_on_cpu c,
       database_instance_v i
 WHERE i.eadam_seq_id = c.eadam_seq_id 
   AND i.inst_id = c.inst_id
 GROUP BY
       c.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       i.cpu_count
)
SELECT eadam_seq_id,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name,
       cpu_count,
       aas_on_cpu_and_resmgr_peak,
       aas_on_cpu_peak,
       aas_resmgr_cpu_quantum_peak,
       aas_on_cpu_and_resmgr_9999,
       aas_on_cpu_9999,
       aas_resmgr_cpu_quantum_9999,
       aas_on_cpu_and_resmgr_999,
       aas_on_cpu_999,
       aas_resmgr_cpu_quantum_999,
       aas_on_cpu_and_resmgr_99,
       aas_on_cpu_99,
       aas_resmgr_cpu_quantum_99,
       aas_on_cpu_and_resmgr_95,
       aas_on_cpu_95,
       aas_resmgr_cpu_quantum_95,
       aas_on_cpu_and_resmgr_90,
       aas_on_cpu_90,
       aas_resmgr_cpu_quantum_90,
       aas_on_cpu_and_resmgr_75,
       aas_on_cpu_75,
       aas_resmgr_cpu_quantum_75,
       aas_on_cpu_and_resmgr_median,
       aas_on_cpu_median,
       aas_resmgr_cpu_quantum_median,
       aas_on_cpu_and_resmgr_avg,
       aas_on_cpu_avg,
       aas_resmgr_cpu_quantum_avg
  FROM sub_totals
 UNION ALL
SELECT eadam_seq_id,
       MAX(dbid) dbid,
       MAX(db_name) db_name,
       NULL host_name,
       -1 instance_number,
       NULL instance_name,
       SUM(cpu_count)                     cpu_count,
       SUM(aas_on_cpu_and_resmgr_peak)    aas_on_cpu_and_resmgr_peak,
       SUM(aas_on_cpu_peak)               aas_on_cpu_peak,
       SUM(aas_resmgr_cpu_quantum_peak)   aas_resmgr_cpu_quantum_peak,
       SUM(aas_on_cpu_and_resmgr_9999)    aas_on_cpu_and_resmgr_9999,
       SUM(aas_on_cpu_9999)               aas_on_cpu_9999,
       SUM(aas_resmgr_cpu_quantum_9999)   aas_resmgr_cpu_quantum_9999,
       SUM(aas_on_cpu_and_resmgr_999)     aas_on_cpu_and_resmgr_999,
       SUM(aas_on_cpu_999)                aas_on_cpu_999,
       SUM(aas_resmgr_cpu_quantum_999)    aas_resmgr_cpu_quantum_999,
       SUM(aas_on_cpu_and_resmgr_99)      aas_on_cpu_and_resmgr_99,
       SUM(aas_on_cpu_99)                 aas_on_cpu_99,
       SUM(aas_resmgr_cpu_quantum_99)     aas_resmgr_cpu_quantum_99,
       SUM(aas_on_cpu_and_resmgr_95)      aas_on_cpu_and_resmgr_95,
       SUM(aas_on_cpu_95)                 aas_on_cpu_95,
       SUM(aas_resmgr_cpu_quantum_95)     aas_resmgr_cpu_quantum_95,
       SUM(aas_on_cpu_and_resmgr_90)      aas_on_cpu_and_resmgr_90,
       SUM(aas_on_cpu_90)                 aas_on_cpu_90,
       SUM(aas_resmgr_cpu_quantum_90)     aas_resmgr_cpu_quantum_90,
       SUM(aas_on_cpu_and_resmgr_75)      aas_on_cpu_and_resmgr_75,
       SUM(aas_on_cpu_75)                 aas_on_cpu_75,
       SUM(aas_resmgr_cpu_quantum_75)     aas_resmgr_cpu_quantum_75,
       SUM(aas_on_cpu_and_resmgr_median)  aas_on_cpu_and_resmgr_median,
       SUM(aas_on_cpu_median)             aas_on_cpu_median,
       SUM(aas_resmgr_cpu_quantum_median) aas_resmgr_cpu_quantum_median,
       SUM(aas_on_cpu_and_resmgr_avg)     aas_on_cpu_and_resmgr_avg,
       SUM(aas_on_cpu_avg)                aas_on_cpu_avg,
       SUM(aas_resmgr_cpu_quantum_avg)    aas_resmgr_cpu_quantum_avg
  FROM sub_totals
 GROUP BY
       eadam_seq_id
/

GRANT SELECT ON cpu_demand_mem_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_cpu_demand_mem_v FOR cpu_demand_mem_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW cpu_demand_awr_v AS
WITH 
samples_on_cpu AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       snap_id,
       sample_id,
       COUNT(*) aas_on_cpu_and_resmgr,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) aas_on_cpu,
       SUM(CASE event WHEN 'resmgr:cpu quantum' THEN 1 ELSE 0 END) aas_resmgr_cpu_quantum       
  FROM dba_hist_active_sess_hist_s
 WHERE (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum')
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       snap_id,
       sample_id
),
sub_totals AS (
SELECT c.eadam_seq_id,
       c.dbid,
       i.db_name,
       i.host_name,
       c.instance_number,
       i.instance_name,
       i.cpu_count,
       MAX(c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_peak,
       MAX(c.aas_on_cpu) aas_on_cpu_peak,
       MAX(c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_peak,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_9999,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_9999,
       PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_9999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_999,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_999,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_99,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_99,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_99,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_95,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_95,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_95,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_90,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_90,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_90,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_75,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_on_cpu) aas_on_cpu_75,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_75,
       MEDIAN(c.aas_on_cpu_and_resmgr) aas_on_cpu_and_resmgr_median,
       MEDIAN(c.aas_on_cpu) aas_on_cpu_median,
       MEDIAN(c.aas_resmgr_cpu_quantum) aas_resmgr_cpu_quantum_median,
       ROUND(AVG(c.aas_on_cpu_and_resmgr), 1) aas_on_cpu_and_resmgr_avg,
       ROUND(AVG(c.aas_on_cpu), 1) aas_on_cpu_avg,
       ROUND(AVG(c.aas_resmgr_cpu_quantum), 1) aas_resmgr_cpu_quantum_avg
  FROM samples_on_cpu c,
       database_instance_v i
 WHERE i.eadam_seq_id = c.eadam_seq_id 
   AND i.dbid = c.dbid
   AND i.instance_number = c.instance_number
 GROUP BY
       c.eadam_seq_id,
       c.dbid,
       i.db_name,
       i.host_name,
       c.instance_number,
       i.instance_name,
       i.cpu_count
)
SELECT eadam_seq_id,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name,
       cpu_count,
       aas_on_cpu_and_resmgr_peak,
       aas_on_cpu_peak,
       aas_resmgr_cpu_quantum_peak,
       aas_on_cpu_and_resmgr_9999,
       aas_on_cpu_9999,
       aas_resmgr_cpu_quantum_9999,
       aas_on_cpu_and_resmgr_999,
       aas_on_cpu_999,
       aas_resmgr_cpu_quantum_999,
       aas_on_cpu_and_resmgr_99,
       aas_on_cpu_99,
       aas_resmgr_cpu_quantum_99,
       aas_on_cpu_and_resmgr_95,
       aas_on_cpu_95,
       aas_resmgr_cpu_quantum_95,
       aas_on_cpu_and_resmgr_90,
       aas_on_cpu_90,
       aas_resmgr_cpu_quantum_90,
       aas_on_cpu_and_resmgr_75,
       aas_on_cpu_75,
       aas_resmgr_cpu_quantum_75,
       aas_on_cpu_and_resmgr_median,
       aas_on_cpu_median,
       aas_resmgr_cpu_quantum_median,
       aas_on_cpu_and_resmgr_avg,
       aas_on_cpu_avg,
       aas_resmgr_cpu_quantum_avg
  FROM sub_totals
 UNION ALL
SELECT eadam_seq_id,
       MAX(dbid) dbid,
       MAX(db_name) db_name,
       NULL host_name,
       -1 instance_number,
       NULL instance_name,
       SUM(cpu_count)                     cpu_count,
       SUM(aas_on_cpu_and_resmgr_peak)    aas_on_cpu_and_resmgr_peak,
       SUM(aas_on_cpu_peak)               aas_on_cpu_peak,
       SUM(aas_resmgr_cpu_quantum_peak)   aas_resmgr_cpu_quantum_peak,
       SUM(aas_on_cpu_and_resmgr_9999)    aas_on_cpu_and_resmgr_9999,
       SUM(aas_on_cpu_9999)               aas_on_cpu_9999,
       SUM(aas_resmgr_cpu_quantum_9999)   aas_resmgr_cpu_quantum_9999,
       SUM(aas_on_cpu_and_resmgr_999)     aas_on_cpu_and_resmgr_999,
       SUM(aas_on_cpu_999)                aas_on_cpu_999,
       SUM(aas_resmgr_cpu_quantum_999)    aas_resmgr_cpu_quantum_999,
       SUM(aas_on_cpu_and_resmgr_99)      aas_on_cpu_and_resmgr_99,
       SUM(aas_on_cpu_99)                 aas_on_cpu_99,
       SUM(aas_resmgr_cpu_quantum_99)     aas_resmgr_cpu_quantum_99,
       SUM(aas_on_cpu_and_resmgr_95)      aas_on_cpu_and_resmgr_95,
       SUM(aas_on_cpu_95)                 aas_on_cpu_95,
       SUM(aas_resmgr_cpu_quantum_95)     aas_resmgr_cpu_quantum_95,
       SUM(aas_on_cpu_and_resmgr_90)      aas_on_cpu_and_resmgr_90,
       SUM(aas_on_cpu_90)                 aas_on_cpu_90,
       SUM(aas_resmgr_cpu_quantum_90)     aas_resmgr_cpu_quantum_90,
       SUM(aas_on_cpu_and_resmgr_75)      aas_on_cpu_and_resmgr_75,
       SUM(aas_on_cpu_75)                 aas_on_cpu_75,
       SUM(aas_resmgr_cpu_quantum_75)     aas_resmgr_cpu_quantum_75,
       SUM(aas_on_cpu_and_resmgr_median)  aas_on_cpu_and_resmgr_median,
       SUM(aas_on_cpu_median)             aas_on_cpu_median,
       SUM(aas_resmgr_cpu_quantum_median) aas_resmgr_cpu_quantum_median,
       SUM(aas_on_cpu_and_resmgr_avg)     aas_on_cpu_and_resmgr_avg,
       SUM(aas_on_cpu_avg)                aas_on_cpu_avg,
       SUM(aas_resmgr_cpu_quantum_avg)    aas_resmgr_cpu_quantum_avg
  FROM sub_totals
 GROUP BY
       eadam_seq_id
/

GRANT SELECT ON cpu_demand_awr_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_cpu_demand_awr_v FOR cpu_demand_awr_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW cpu_demand_series_v AS
WITH 
cpu_per_inst_and_sample AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       snap_id,
       sample_id,
       MIN(sample_time) sample_time,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
       SUM(CASE event WHEN 'resmgr:cpu quantum' THEN 1 ELSE 0 END) resmgr,
       COUNT(*) on_cpu_and_resmgr
  FROM dba_hist_active_sess_hist_s
 WHERE (session_state = 'ON CPU' OR event = 'resmgr:cpu quantum')
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       snap_id,
       sample_id
),
cpu_per_inst_and_hour AS (
SELECT c.eadam_seq_id,
       c.instance_number, 
       TRUNC(CAST(c.sample_time AS DATE), 'HH')               begin_time, 
       TRUNC(CAST(c.sample_time AS DATE), 'HH') + (1/24)      end_time, 
       i.cpu_count,
       MAX(c.on_cpu)                                          on_cpu,
       MAX(c.resmgr)                                          resmgr,
       MAX(c.on_cpu_and_resmgr)                               on_cpu_and_resmgr,
       MAX(c.on_cpu)                                          on_cpu_max, /* sames as on_cpu */
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY c.on_cpu) on_cpu_99p,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY c.on_cpu) on_cpu_95p,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY c.on_cpu) on_cpu_90p,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY c.on_cpu) on_cpu_75p,
       ROUND(MEDIAN(c.on_cpu), 1)                             on_cpu_med,
       ROUND(AVG(c.on_cpu), 1)                                on_cpu_avg
  FROM cpu_per_inst_and_sample c,
       database_instance_v i
 WHERE i.eadam_seq_id = c.eadam_seq_id 
   AND i.dbid = c.dbid
   AND i.instance_number = c.instance_number
 GROUP BY
       c.eadam_seq_id,
       c.instance_number,
       i.cpu_count,
       TRUNC(CAST(c.sample_time AS DATE), 'HH')
)
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       end_time,
       cpu_count,
       on_cpu,
       resmgr,
       on_cpu_and_resmgr,
       on_cpu_max,
       on_cpu_99p,
       on_cpu_95p,
       on_cpu_90p,
       on_cpu_75p,
       on_cpu_med,
       on_cpu_avg
  FROM cpu_per_inst_and_hour
 UNION ALL
SELECT eadam_seq_id,
       -1 instance_number,
       begin_time,
       end_time,
       SUM(cpu_count)         cpu_count,
       SUM(on_cpu)            on_cpu,
       SUM(resmgr)            resmgr,
       SUM(on_cpu_and_resmgr) on_cpu_and_resmgr,
       SUM(on_cpu_max)        on_cpu_max,
       SUM(on_cpu_99p)        on_cpu_99p,
       SUM(on_cpu_95p)        on_cpu_95p,
       SUM(on_cpu_90p)        on_cpu_90p,
       SUM(on_cpu_75p)        on_cpu_75p,
       SUM(on_cpu_med)        on_cpu_med,
       SUM(on_cpu_avg)        on_cpu_avg
  FROM cpu_per_inst_and_hour
 GROUP BY
       eadam_seq_id,
       begin_time,
       end_time
/

GRANT SELECT ON cpu_demand_series_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_cpu_demand_series_v FOR cpu_demand_series_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW memory_mem_v AS
WITH
par AS (
SELECT d.eadam_seq_id,
       d.dbid,
       d.db_name,
       d.inst_id,
       d.host_name,
       d.instance_number,
       d.instance_name,
       SUM(CASE p.name WHEN 'memory_target' THEN TO_NUMBER(value) END) memory_target,
       SUM(CASE p.name WHEN 'memory_max_target' THEN TO_NUMBER(value) END) memory_max_target,
       SUM(CASE p.name WHEN 'sga_target' THEN TO_NUMBER(value) END) sga_target,
       SUM(CASE p.name WHEN 'sga_max_size' THEN TO_NUMBER(value) END) sga_max_size,
       SUM(CASE p.name WHEN 'pga_aggregate_target' THEN TO_NUMBER(value) END) pga_aggregate_target
  FROM database_instance_v d,
       gv_system_parameter2_s p
 WHERE p.eadam_seq_id = d.eadam_seq_id
   AND p.inst_id = d.inst_id
   AND p.name IN ('memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 'pga_aggregate_target')
 GROUP BY
       d.eadam_seq_id,
       d.dbid,
       d.db_name,
       d.inst_id,
       d.host_name,
       d.instance_number,
       d.instance_name
),
start_up AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       MAX(startup_time) max_startup_time
  FROM dba_hist_snapshot_s
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number
),
snap_id_from AS (
SELECT s.eadam_seq_id,
       s.dbid,
       s.instance_number,
       MIN(s.snap_id) min_snap_id
  FROM dba_hist_snapshot_s s,
       start_up u
 WHERE s.eadam_seq_id = u.eadam_seq_id
   AND s.dbid = u.dbid
   AND s.instance_number = u.instance_number
   AND s.startup_time = u.max_startup_time
 GROUP BY
       s.eadam_seq_id,
       s.dbid,
       s.instance_number
),
sga_per_snap AS (
SELECT h.eadam_seq_id,
       h.dbid,
       h.instance_number,
       h.snap_id,
       SUM(h.value) sga
  FROM dba_hist_sga_s h,
       snap_id_from s
 WHERE h.eadam_seq_id = s.eadam_seq_id
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
   AND h.snap_id >= s.min_snap_id
 GROUP BY
       h.eadam_seq_id,
       h.dbid,
       h.instance_number,
       h.snap_id
),
sga_max AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       MAX(sga) bytes
  FROM sga_per_snap
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number
),
pga_max AS (
SELECT h.eadam_seq_id,
       h.dbid,
       h.instance_number,
       MAX(h.value) bytes
  FROM dba_hist_pgastat_s h,
       snap_id_from s
 WHERE h.eadam_seq_id = s.eadam_seq_id
   AND h.dbid = s.dbid
   AND h.instance_number = s.instance_number
   AND h.snap_id >= s.min_snap_id
   AND h.name = 'maximum PGA allocated'
 GROUP BY
       h.eadam_seq_id,
       h.dbid,
       h.instance_number
),
pga AS (
SELECT par.eadam_seq_id,
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
 WHERE par.eadam_seq_id = pga_max.eadam_seq_id(+)
   AND par.dbid = pga_max.dbid(+)
   AND par.instance_number = pga_max.instance_number(+)
),
amm AS (
SELECT par.eadam_seq_id,
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
SELECT par.eadam_seq_id,
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
 WHERE par.eadam_seq_id = pga.eadam_seq_id
   AND par.dbid = pga.dbid
   AND par.instance_number = pga.instance_number
),
no_mm AS (
SELECT pga.eadam_seq_id,
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
  FROM pga, 
       sga_max
 WHERE sga_max.eadam_seq_id(+) = pga.eadam_seq_id
   AND sga_max.dbid(+) = pga.dbid
   AND sga_max.instance_number(+) = pga.instance_number
),
them_all AS (
SELECT amm.eadam_seq_id,
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
 WHERE asmm.eadam_seq_id = amm.eadam_seq_id
   AND asmm.dbid = amm.dbid
   AND asmm.instance_number = amm.instance_number
   AND no_mm.eadam_seq_id = amm.eadam_seq_id
   AND no_mm.dbid = amm.dbid
   AND no_mm.instance_number = amm.instance_number
)
SELECT eadam_seq_id,
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
SELECT eadam_seq_id,
       dbid,
       db_name,
       NULL host_name,
       -1 instance_number,
       NULL instance_name,
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
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name
/

GRANT SELECT ON memory_mem_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_memory_mem_v FOR memory_mem_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW memory_awr_v AS
WITH
max_snap AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       parameter_name,
       MAX(snap_id) snap_id
  FROM dba_hist_parameter_s
 WHERE parameter_name IN ('memory_target', 'memory_max_target', 'sga_target', 'sga_max_size', 'pga_aggregate_target')
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       parameter_name
),
last_value AS (
SELECT s.eadam_seq_id,
       s.dbid,
       s.instance_number,
       s.parameter_name,
       s.snap_id,
       p.value
  FROM max_snap s,
       dba_hist_parameter_s p
 WHERE p.eadam_seq_id = s.eadam_seq_id
   AND p.dbid = s.dbid
   AND p.instance_number = s.instance_number
   AND p.parameter_name = s.parameter_name
   AND p.snap_id = s.snap_id
),
par AS (
SELECT di.eadam_seq_id,
       di.dbid,
       di.db_name,
       di.host_name,
       di.instance_number,
       di.instance_name,
       SUM(CASE p.parameter_name WHEN 'memory_target' THEN TO_NUMBER(p.value) ELSE 0 END) memory_target,
       SUM(CASE p.parameter_name WHEN 'memory_max_target' THEN TO_NUMBER(p.value) ELSE 0 END) memory_max_target,
       SUM(CASE p.parameter_name WHEN 'sga_target' THEN TO_NUMBER(p.value) ELSE 0 END) sga_target,
       SUM(CASE p.parameter_name WHEN 'sga_max_size' THEN TO_NUMBER(p.value) ELSE 0 END) sga_max_size,
       SUM(CASE p.parameter_name WHEN 'pga_aggregate_target' THEN TO_NUMBER(p.value) ELSE 0 END) pga_aggregate_target
  FROM last_value p,
       database_instance_v di
 WHERE di.eadam_seq_id = p.eadam_seq_id
   AND di.dbid = p.dbid
   AND di.instance_number = p.instance_number
 GROUP BY
       di.eadam_seq_id,
       di.dbid,
       di.db_name,
       di.host_name,
       di.instance_number,
       di.instance_name
),
sgainfo AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       snap_id,
       SUM(value) sga_size
  FROM dba_hist_sga_s
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       snap_id
),
sga_max AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       MAX(sga_size) bytes
  FROM sgainfo
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number
),
pga_max AS (
SELECT eadam_seq_id,
       dbid,
       instance_number,
       MAX(value) bytes
  FROM dba_hist_pgastat_s
 WHERE name = 'maximum PGA allocated'
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number
),
pga AS (
SELECT par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.pga_aggregate_target,
       pga_max.bytes max_bytes,
       GREATEST(NVL(par.pga_aggregate_target, 0), NVL(pga_max.bytes, 0)) bytes
  FROM par,
       pga_max
 WHERE par.eadam_seq_id = pga_max.eadam_seq_id(+)
   AND par.dbid = pga_max.dbid(+)
   AND par.instance_number = pga_max.instance_number(+)
),
amm AS (
SELECT par.eadam_seq_id,
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
SELECT par.eadam_seq_id,
       par.dbid,
       par.db_name,
       par.host_name,
       par.instance_number,
       par.instance_name,
       par.sga_target,
       par.sga_max_size,
       pga.bytes pga_bytes,
       GREATEST(NVL(par.sga_target, 0), NVL(par.sga_max_size, 0)) + NVL(pga.bytes, 0) + (6 * 1024 * 1024) bytes
  FROM par,
       pga
 WHERE par.eadam_seq_id = pga.eadam_seq_id
   AND par.dbid = pga.dbid
   AND par.instance_number = pga.instance_number
),
no_mm AS (
SELECT pga.eadam_seq_id,
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
 WHERE sga_max.eadam_seq_id(+) = pga.eadam_seq_id
   AND sga_max.dbid(+) = pga.dbid
   AND sga_max.instance_number(+) = pga.instance_number
),
them_all AS (
SELECT amm.eadam_seq_id,
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
 WHERE asmm.eadam_seq_id = amm.eadam_seq_id
   AND asmm.dbid = amm.dbid
   AND asmm.instance_number = amm.instance_number
   AND no_mm.eadam_seq_id = amm.eadam_seq_id
   AND no_mm.dbid = amm.dbid
   AND no_mm.instance_number = amm.instance_number
)
SELECT eadam_seq_id,
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
SELECT eadam_seq_id,
       dbid,
       db_name,
       NULL host_name,
       -1 instance_number,
       NULL instance_name,
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
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name
/

GRANT SELECT ON memory_awr_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_memory_awr_v FOR memory_awr_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW memory_series_v AS
WITH
sga AS (
SELECT h.eadam_seq_id,
       h.instance_number,
       h.snap_id,
       TRUNC(CAST(s.end_interval_time AS DATE), 'HH') begin_time,
       SUM(h.value) bytes
  FROM dba_hist_sga_s h,
       dba_hist_snapshot_s s
 WHERE s.eadam_seq_id = h.eadam_seq_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND s.snap_id = h.snap_id
 GROUP BY
       h.eadam_seq_id,
       h.instance_number,
       h.snap_id,
       s.end_interval_time
),
sga_h AS (
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       ROUND(MAX(bytes) / POWER(2, 30), 3) gb
  FROM sga
 GROUP BY
       eadam_seq_id,
       instance_number,
       begin_time
),
pga AS (
SELECT h.eadam_seq_id,
       h.instance_number,
       h.snap_id,
       TRUNC(CAST(s.end_interval_time AS DATE), 'HH') begin_time,
       SUM(h.value) bytes
  FROM dba_hist_pgastat_s h,
       dba_hist_snapshot_s s
 WHERE  h.name = 'maximum PGA allocated'
   AND s.eadam_seq_id = h.eadam_seq_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND s.snap_id = h.snap_id
 GROUP BY
       h.eadam_seq_id,
       h.instance_number,
       h.snap_id,
       s.end_interval_time
),
pga_h AS (
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       ROUND(MAX(bytes) / POWER(2, 30), 3) gb
  FROM pga
 GROUP BY
       eadam_seq_id,
       instance_number,
       begin_time
),
mem_per_inst_and_hour AS (
SELECT s.eadam_seq_id,
       s.instance_number,
       s.begin_time,
       s.begin_time + (1/24) end_time,
       (s.gb + p.gb) mem_gb,
       s.gb sga_gb,
       p.gb pga_gb       
  FROM sga_h s,
       pga_h p
 WHERE p.eadam_seq_id = s.eadam_seq_id
   AND p.instance_number = s.instance_number
   AND p.begin_time = s.begin_time
)
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       end_time,
       mem_gb,
       sga_gb,
       pga_gb
  FROM mem_per_inst_and_hour
 UNION ALL
SELECT eadam_seq_id,
       -1 instance_number,
       begin_time,
       end_time,
       SUM(mem_gb) mem_gb,
       SUM(sga_gb) sga_gb,
       SUM(pga_gb) pga_gb
  FROM mem_per_inst_and_hour
 GROUP BY
       eadam_seq_id,
       begin_time,
       end_time
/

GRANT SELECT ON memory_series_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_memory_series_v FOR memory_series_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW db_size_v AS
WITH
sizes AS (
SELECT eadam_seq_id,
       'Data' file_type,
       SUM(bytes) bytes
  FROM v_datafile_s
 GROUP BY
       eadam_seq_id
 UNION ALL
SELECT eadam_seq_id,
       'Temp' file_type,
       SUM(bytes) bytes
  FROM v_tempfile_s
 GROUP BY
       eadam_seq_id
 UNION ALL
SELECT eadam_seq_id,
       'Log' file_type,
       SUM(bytes) * MAX(members) bytes
  FROM gv_log_s
 GROUP BY
       eadam_seq_id
 UNION ALL
SELECT eadam_seq_id,
       'Control' file_type,
       SUM(block_size * file_size_blks) bytes
  FROM v_controlfile_s
 GROUP BY
       eadam_seq_id
)
SELECT d.eadam_seq_id,
       d.dbid,
       d.db_name,
       s.file_type,
       s.bytes size_bytes,
       ROUND(s.bytes/POWER(2,30),3) size_gb
  FROM database_v d,
       sizes s
 WHERE s.eadam_seq_id = d.eadam_seq_id
 UNION ALL
SELECT d.eadam_seq_id,
       d.dbid,
       d.db_name,
       'Total' file_type,
       SUM(s.bytes) size_bytes,
       ROUND(SUM(s.bytes)/POWER(2,30),3) size_gb
  FROM database_v d,
       sizes s
 WHERE s.eadam_seq_id = d.eadam_seq_id
 GROUP BY
       d.eadam_seq_id,
       d.dbid,
       d.db_name
/

GRANT SELECT ON db_size_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_db_size_v FOR db_size_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW disk_perf_v AS
WITH
sysstat_io AS (
SELECT i.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       h.snap_id,
       SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN value ELSE 0 END) r_reqs,
       SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN value ELSE 0 END) w_reqs,
       SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN value ELSE 0 END) r_bytes,
       SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN value ELSE 0 END) w_bytes
  FROM dba_hist_sysstat_s h,
       database_instance_v i
 WHERE h.stat_name IN ('physical read total IO requests', 'physical write total IO requests', 'redo writes', 'physical read total bytes', 'physical write total bytes', 'redo size')
   AND i.eadam_seq_id = h.eadam_seq_id
   AND i.instance_number = h.instance_number
 GROUP BY
       i.eadam_seq_id,
       i.dbid,
       i.db_name,
       i.host_name,
       i.instance_number,
       i.instance_name,
       h.snap_id
),
io_per_inst_and_snap_id AS (
SELECT h1.eadam_seq_id,
       h1.dbid,
       h1.db_name,
       h1.host_name,
       h1.instance_number,
       h1.instance_name,
       h1.snap_id,
       (h1.r_reqs - h0.r_reqs) r_reqs,
       (h1.w_reqs - h0.w_reqs) w_reqs,
       (h1.r_bytes - h0.r_bytes) r_bytes,
       (h1.w_bytes - h0.w_bytes) w_bytes,
       (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400 elapsed_sec
  FROM sysstat_io h0,
       dba_hist_snapshot_s s0,
       sysstat_io h1,
       dba_hist_snapshot_s s1
 WHERE s0.eadam_seq_id = h0.eadam_seq_id
   AND s0.dbid = h0.dbid
   AND s0.snap_id = h0.snap_id
   AND s0.instance_number = h0.instance_number
   AND h1.eadam_seq_id = h0.eadam_seq_id
   AND h1.dbid = h0.dbid
   AND h1.instance_number = h0.instance_number
   AND h1.snap_id = h0.snap_id + 1
   AND s1.eadam_seq_id = h1.eadam_seq_id
   AND s1.dbid = h1.dbid
   AND s1.snap_id = h1.snap_id
   AND s1.instance_number = h1.instance_number
   AND s1.snap_id = s0.snap_id + 1
   AND s1.startup_time = s0.startup_time
),
io_per_snap_id AS (
SELECT eadam_seq_id,
       dbid,
       db_name,
       snap_id,
       SUM(r_reqs) r_reqs,
       SUM(w_reqs) w_reqs,
       SUM(r_bytes) r_bytes,
       SUM(w_bytes) w_bytes,
       AVG(elapsed_sec) elapsed_sec
  FROM io_per_inst_and_snap_id
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name,
       snap_id
),
io_per_inst AS (
SELECT eadam_seq_id,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name,
       ROUND(100 * SUM(r_reqs) / (SUM(r_reqs) + SUM(w_reqs)), 1) r_reqs_perc,
       ROUND(100 * SUM(w_reqs) / (SUM(r_reqs) + SUM(w_reqs)), 1) w_reqs_perc,
       ROUND(MAX((r_reqs + w_reqs) / elapsed_sec)) rw_iops_peak,
       ROUND(MAX(r_reqs / elapsed_sec)) r_iops_peak,
       ROUND(MAX(w_reqs / elapsed_sec)) w_iops_peak,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_999,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_99,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_95,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_90,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_75,
       ROUND(MEDIAN((r_reqs + w_reqs) / elapsed_sec)) rw_iops_median,
       ROUND(MEDIAN(r_reqs / elapsed_sec)) r_iops_median,
       ROUND(MEDIAN(w_reqs / elapsed_sec)) w_iops_median,
       ROUND(AVG((r_reqs + w_reqs) / elapsed_sec)) rw_iops_avg,
       ROUND(AVG(r_reqs / elapsed_sec)) r_iops_avg,
       ROUND(AVG(w_reqs / elapsed_sec)) w_iops_avg,
       ROUND(100 * SUM(r_bytes) / (SUM(r_bytes) + SUM(w_bytes)), 1) r_bytes_perc,
       ROUND(100 * SUM(w_bytes) / (SUM(r_bytes) + SUM(w_bytes)), 1) w_bytes_perc,
       ROUND(MAX((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_peak,
       ROUND(MAX(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_peak,
       ROUND(MAX(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_peak,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_999,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_99,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_95,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_90,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_75,
       ROUND(MEDIAN((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_median,
       ROUND(MEDIAN(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_median,
       ROUND(MEDIAN(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_median,
       ROUND(AVG((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_avg,
       ROUND(AVG(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_avg,
       ROUND(AVG(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_avg
  FROM io_per_inst_and_snap_id
 WHERE elapsed_sec > 60 -- ignore snaps too close
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name,
       host_name,
       instance_number,
       instance_name
),
io_per_cluster AS ( -- combined
SELECT eadam_seq_id,
       dbid,
       db_name,
       NULL host_name,
       -2 instance_number,
       NULL instance_name,
       ROUND(100 * SUM(r_reqs) / (SUM(r_reqs) + SUM(w_reqs)), 1) r_reqs_perc,
       ROUND(100 * SUM(w_reqs) / (SUM(r_reqs) + SUM(w_reqs)), 1) w_reqs_perc,
       ROUND(MAX((r_reqs + w_reqs) / elapsed_sec)) rw_iops_peak,
       ROUND(MAX(r_reqs / elapsed_sec)) r_iops_peak,
       ROUND(MAX(w_reqs / elapsed_sec)) w_iops_peak,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_999,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_99,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_95,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_90,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (r_reqs + w_reqs) / elapsed_sec)) rw_iops_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY r_reqs / elapsed_sec)) r_iops_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY w_reqs / elapsed_sec)) w_iops_75,
       ROUND(MEDIAN((r_reqs + w_reqs) / elapsed_sec)) rw_iops_median,
       ROUND(MEDIAN(r_reqs / elapsed_sec)) r_iops_median,
       ROUND(MEDIAN(w_reqs / elapsed_sec)) w_iops_median,
       ROUND(AVG((r_reqs + w_reqs) / elapsed_sec)) rw_iops_avg,
       ROUND(AVG(r_reqs / elapsed_sec)) r_iops_avg,
       ROUND(AVG(w_reqs / elapsed_sec)) w_iops_avg,
       ROUND(100 * SUM(r_bytes) / (SUM(r_bytes) + SUM(w_bytes)), 1) r_bytes_perc,
       ROUND(100 * SUM(w_bytes) / (SUM(r_bytes) + SUM(w_bytes)), 1) w_bytes_perc,
       ROUND(MAX((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_peak,
       ROUND(MAX(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_peak,
       ROUND(MAX(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_peak,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_999,
       ROUND(PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_999,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_99,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_99,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_95,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_95,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_90,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_90,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY (r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_75,
       ROUND(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_75,
       ROUND(MEDIAN((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_median,
       ROUND(MEDIAN(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_median,
       ROUND(MEDIAN(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_median,
       ROUND(AVG((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec)) rw_mbps_avg,
       ROUND(AVG(r_bytes / POWER(2, 20) / elapsed_sec)) r_mbps_avg,
       ROUND(AVG(w_bytes / POWER(2, 20) / elapsed_sec)) w_mbps_avg
  FROM io_per_snap_id
 WHERE elapsed_sec > 60 -- ignore snaps too close
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name
),
io_sum AS ( -- simple aggregate
SELECT eadam_seq_id,
       dbid,
       db_name,
       NULL host_name,
       -1 instance_number,
       NULL instance_name,
       ROUND(AVG(r_reqs_perc), 1) r_reqs_perc,
       ROUND(AVG(w_reqs_perc), 1) w_reqs_perc,
       SUM(rw_iops_peak),
       SUM(r_iops_peak),
       SUM(w_iops_peak),
       SUM(rw_iops_999),
       SUM(r_iops_999),
       SUM(w_iops_999),
       SUM(rw_iops_99),
       SUM(r_iops_99),
       SUM(w_iops_99),
       SUM(rw_iops_95),
       SUM(r_iops_95),
       SUM(w_iops_95),
       SUM(rw_iops_90),
       SUM(r_iops_90),
       SUM(w_iops_90),
       SUM(rw_iops_75),
       SUM(r_iops_75),
       SUM(w_iops_75),
       SUM(rw_iops_median),
       SUM(r_iops_median),
       SUM(w_iops_median),
       SUM(rw_iops_avg),
       SUM(r_iops_avg),
       SUM(w_iops_avg),
       ROUND(AVG(r_bytes_perc), 1) r_bytes_perc,
       ROUND(AVG(w_bytes_perc), 1) w_bytes_perc,
       SUM(rw_mbps_peak),
       SUM(r_mbps_peak),
       SUM(w_mbps_peak),
       SUM(rw_mbps_999),
       SUM(r_mbps_999),
       SUM(w_mbps_999),
       SUM(rw_mbps_99),
       SUM(r_mbps_99),
       SUM(w_mbps_99),
       SUM(rw_mbps_95),
       SUM(r_mbps_95),
       SUM(w_mbps_95),
       SUM(rw_mbps_90),
       SUM(r_mbps_90),
       SUM(w_mbps_90),
       SUM(rw_mbps_75),
       SUM(r_mbps_75),
       SUM(w_mbps_75),
       SUM(rw_mbps_median),
       SUM(r_mbps_median),
       SUM(w_mbps_median),
       SUM(rw_mbps_avg),
       SUM(r_mbps_avg),
       SUM(w_mbps_avg)
  FROM io_per_inst
 GROUP BY
       eadam_seq_id,
       dbid,
       db_name
)
SELECT * FROM io_per_inst
UNION ALL
SELECT * FROM io_sum
UNION ALL
SELECT * FROM io_per_cluster
/

GRANT SELECT ON disk_perf_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_disk_perf_v FOR disk_perf_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW disk_perf_series_v AS
WITH
sysstat_io AS (
SELECT i.eadam_seq_id,
       i.dbid,
       i.instance_number,
       h.snap_id,
       SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN value ELSE 0 END) r_reqs,
       SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN value ELSE 0 END) w_reqs,
       SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN value ELSE 0 END) r_bytes,
       SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN value ELSE 0 END) w_bytes
  FROM dba_hist_sysstat_s h,
       database_instance_v i
 WHERE h.stat_name IN ('physical read total IO requests', 'physical write total IO requests', 'redo writes', 'physical read total bytes', 'physical write total bytes', 'redo size')
   AND i.eadam_seq_id = h.eadam_seq_id
   AND i.instance_number = h.instance_number
 GROUP BY
       i.eadam_seq_id,
       i.dbid,
       i.instance_number,
       h.snap_id
),
io_per_inst_and_snap_id AS (
SELECT h1.eadam_seq_id,
       h1.instance_number,
       (h1.r_reqs - h0.r_reqs) r_reqs,
       (h1.w_reqs - h0.w_reqs) w_reqs,
       (h1.r_bytes - h0.r_bytes) r_bytes,
       (h1.w_bytes - h0.w_bytes) w_bytes,
       TRUNC(CAST(s1.end_interval_time AS DATE), 'HH') begin_time,
       (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400 elapsed_sec
  FROM sysstat_io h0,
       dba_hist_snapshot_s s0,
       sysstat_io h1,
       dba_hist_snapshot_s s1
 WHERE s0.eadam_seq_id = h0.eadam_seq_id
   AND s0.dbid = h0.dbid
   AND s0.snap_id = h0.snap_id
   AND s0.instance_number = h0.instance_number
   AND h1.eadam_seq_id = h0.eadam_seq_id
   AND h1.dbid = h0.dbid
   AND h1.instance_number = h0.instance_number
   AND h1.snap_id = h0.snap_id + 1
   AND s1.eadam_seq_id = h1.eadam_seq_id
   AND s1.dbid = h1.dbid
   AND s1.snap_id = h1.snap_id
   AND s1.instance_number = h1.instance_number
   AND s1.snap_id = s0.snap_id + 1
   AND s1.startup_time = s0.startup_time
),
io_per_inst_and_hr AS (
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       begin_time + (1/24) end_time,
       ROUND(MAX((r_reqs + w_reqs) / elapsed_sec)) rw_iops,
       ROUND(MAX(r_reqs / elapsed_sec)) r_iops,
       ROUND(MAX(w_reqs / elapsed_sec)) w_iops,
       ROUND(MAX((r_bytes + w_bytes) / POWER(2, 20) / elapsed_sec), 3) rw_mbps,
       ROUND(MAX(r_bytes / POWER(2, 20) / elapsed_sec), 3) r_mbps,
       ROUND(MAX(w_bytes / POWER(2, 20) / elapsed_sec), 3) w_mbps
  FROM io_per_inst_and_snap_id
 GROUP BY
       eadam_seq_id,
       instance_number,
       begin_time
)
SELECT eadam_seq_id,
       instance_number,
       begin_time,
       end_time,
       rw_iops,
       r_iops,
       w_iops,
       rw_mbps,
       r_mbps,
       w_mbps
  FROM io_per_inst_and_hr
 UNION ALL
SELECT eadam_seq_id,
       -1 instance_number,
       begin_time,
       end_time,
       SUM(rw_iops) rw_iops,
       SUM(r_iops) r_iops,
       SUM(w_iops) w_iops,
       SUM(rw_mbps) rw_mbps,
       SUM(r_mbps) r_mbps,
       SUM(w_mbps) w_mbps
  FROM io_per_inst_and_hr
 GROUP BY
       eadam_seq_id,
       begin_time,
       end_time
/

GRANT SELECT ON disk_perf_series_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_disk_perf_series_v FOR disk_perf_series_v
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW os_series_v AS
WITH 
osstat_denorm AS (
SELECT i.eadam_seq_id,
       i.dbid,
       i.instance_number,
       i.host_name,
       h.snap_id,
       SUM(CASE h.stat_name WHEN 'LOAD'                  THEN value ELSE 0 END) load,
       SUM(CASE h.stat_name WHEN 'NUM_CPUS'              THEN value ELSE 0 END) num_cpus,
       SUM(CASE h.stat_name WHEN 'NUM_CPU_CORES'         THEN value ELSE 0 END) num_cpu_cores,
       SUM(CASE h.stat_name WHEN 'PHYSICAL_MEMORY_BYTES' THEN value ELSE 0 END) physical_memory_bytes
  FROM dba_hist_osstat_s h,
       database_instance_v i
 WHERE h.stat_name IN ('LOAD', 'NUM_CPUS', 'NUM_CPU_CORES', 'PHYSICAL_MEMORY_BYTES')
   AND i.eadam_seq_id = h.eadam_seq_id
   AND i.instance_number = h.instance_number
 GROUP BY
       i.eadam_seq_id,
       i.dbid,
       i.instance_number,
       i.host_name,
       h.snap_id
)
SELECT h.eadam_seq_id,
       h.instance_number,
       h.host_name,
       TRUNC(CAST(s.end_interval_time AS DATE), 'HH') begin_time,
       TRUNC(CAST(s.end_interval_time AS DATE), 'HH') + (1/24) end_time,
       ROUND(MAX(load), 2) load,
       MAX(num_cpus) num_cpus,
       MAX(num_cpu_cores) num_cpu_cores,
       ROUND(MAX(physical_memory_bytes) / POWER(2, 30), 3) physical_memory_gb
  FROM osstat_denorm h,
       dba_hist_snapshot_s s
 WHERE s.eadam_seq_id = h.eadam_seq_id
   AND s.dbid = h.dbid
   AND s.snap_id = h.snap_id
   AND s.instance_number = h.instance_number
 GROUP BY
       h.eadam_seq_id,
       h.instance_number,
       h.host_name,
       TRUNC(CAST(s.end_interval_time AS DATE), 'HH')
/

GRANT SELECT ON os_series_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_os_series_v FOR os_series_v
/

/* ------------------------------------------------------------------------- */

-- associated to the instance from where eadam was captured
CREATE OR REPLACE VIEW disk_space_series_v AS
WITH
ts_per_snap_id AS (
SELECT us.eadam_seq_id,
       us.dbid,
       sn.instance_number,
       us.snap_id,
       TRUNC(CAST(sn.end_interval_time AS DATE), 'HH') + (1/24) end_time,
       SUM(us.tablespace_size * ts.block_size) all_tablespaces_bytes,
       SUM(CASE ts.contents WHEN 'PERMANENT' THEN us.tablespace_size * ts.block_size ELSE 0 END) perm_tablespaces_bytes,
       SUM(CASE ts.contents WHEN 'UNDO'      THEN us.tablespace_size * ts.block_size ELSE 0 END) undo_tablespaces_bytes,
       SUM(CASE ts.contents WHEN 'TEMPORARY' THEN us.tablespace_size * ts.block_size ELSE 0 END) temp_tablespaces_bytes
  FROM dba_hist_tbspc_space_usag_s us,
       dba_hist_xtr_control_s ct,
       dba_hist_snapshot_s sn,
       v_tablespace_s vt,
       dba_tablespaces_s ts
 WHERE ct.eadam_seq_id = us.eadam_seq_id
   AND sn.eadam_seq_id = us.eadam_seq_id
   AND sn.snap_id = us.snap_id
   AND sn.dbid = us.dbid
   AND sn.instance_number = ct.instance_number
   AND vt.eadam_seq_id = us.eadam_seq_id
   AND vt.ts# = us.tablespace_id
   AND ts.eadam_seq_id = vt.eadam_seq_id
   AND ts.tablespace_name = vt.name
 GROUP BY
       us.eadam_seq_id,
       us.dbid,
       sn.instance_number,
       us.snap_id,
       sn.end_interval_time
)
SELECT eadam_seq_id,
       dbid,
       instance_number,
       end_time - (1/24) begin_time,
       end_time,
       ROUND(MAX(perm_tablespaces_bytes) / POWER(2, 30), 3) perm_gb,
       ROUND(MAX(undo_tablespaces_bytes) / POWER(2, 30), 3) undo_gb,
       ROUND(MAX(temp_tablespaces_bytes) / POWER(2, 30), 3) temp_gb
  FROM ts_per_snap_id
 GROUP BY
       eadam_seq_id,
       dbid,
       instance_number,
       end_time
/

GRANT SELECT ON disk_space_series_v TO PUBLIC
/

CREATE OR REPLACE PUBLIC SYNONYM eadam_disk_space_series_v FOR disk_space_series_v
/

/* ------------------------------------------------------------------------- */

SELECT object_name views FROM user_objects WHERE object_type = 'VIEW' ORDER BY 1;

SET ECHO OFF FEED OFF;
SPO OFF;
