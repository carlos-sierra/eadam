-- Creates Libraries

SPO eadam_04_clb.txt;
SET ECHO ON FEED ON;

/* ------------------------------------------------------------------------- */

DROP PACKAGE BODY eadam;
DROP PACKAGE eadam;

DROP TYPE cpu_demand_type_table;
DROP TYPE cpu_demand_type;
DROP TYPE cpu_demand_mm_type_table;
DROP TYPE cpu_demand_mm_type;
DROP TYPE cpu_consumption_type_table;
DROP TYPE cpu_consumption_type;
DROP TYPE memory_usage_type_table;
DROP TYPE memory_usage_type;
DROP TYPE iops_type_table;
DROP TYPE iops_type;
DROP TYPE mbps_type_table;
DROP TYPE mbps_type;

CREATE OR REPLACE TYPE cpu_demand_type AS OBJECT 
( dbid                NUMBER
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
)
/

CREATE OR REPLACE TYPE cpu_demand_type_table AS TABLE of cpu_demand_type
/

CREATE OR REPLACE TYPE cpu_demand_mm_type AS OBJECT 
( dbid                NUMBER
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

CREATE OR REPLACE TYPE cpu_demand_mm_type_table AS TABLE of cpu_demand_mm_type
/

CREATE OR REPLACE TYPE cpu_consumption_type AS OBJECT 
( dbid                NUMBER
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

CREATE OR REPLACE TYPE cpu_consumption_type_table AS TABLE of cpu_consumption_type
/

CREATE OR REPLACE TYPE memory_usage_type AS OBJECT 
( dbid                NUMBER
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

CREATE OR REPLACE TYPE memory_usage_type_table AS TABLE of memory_usage_type
/

CREATE OR REPLACE TYPE iops_type AS OBJECT 
( dbid                NUMBER
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

CREATE OR REPLACE TYPE iops_type_table AS TABLE of iops_type
/

CREATE OR REPLACE TYPE mbps_type AS OBJECT 
( dbid                NUMBER
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

CREATE OR REPLACE TYPE mbps_type_table AS TABLE of mbps_type
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE PACKAGE eadam AS

FUNCTION get_other_xml_awr 
( p_eadam_seq_id    IN NUMBER
, p_dbid            IN NUMBER
, p_sql_id          IN VARCHAR2
, p_plan_hash_value IN NUMBER
, p_id              IN NUMBER 
)
RETURN CLOB;

FUNCTION get_other_xml_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER
, p_sql_id          IN VARCHAR2
, p_child_number    IN NUMBER
, p_id              IN NUMBER
)
RETURN CLOB;

FUNCTION bytes_to_kmgtp_value
( p_bytes IN INTEGER
)
RETURN NUMBER;

FUNCTION bytes_to_kmgtp_unit
( p_bytes IN INTEGER
)
RETURN VARCHAR2;

FUNCTION bytes_to_kmgtp
( p_bytes IN INTEGER
)
RETURN VARCHAR2;

FUNCTION cpu_demand_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED;

FUNCTION cpu_demand_peak_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED;

FUNCTION cpu_demand_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED;

FUNCTION cpu_demand_peak_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED;

FUNCTION cpu_demand_mm_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_mm_type_table PIPELINED;

FUNCTION cpu_consumption_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_consumption_type_table PIPELINED;

FUNCTION cpu_consumption_peak_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_consumption_type_table PIPELINED;

FUNCTION memory_usage_awr
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN memory_usage_type_table PIPELINED;

FUNCTION iops
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN iops_type_table PIPELINED;

FUNCTION iops_peak
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN iops_type_table PIPELINED;

FUNCTION mbps
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN mbps_type_table PIPELINED;

FUNCTION mbps_peak
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN mbps_type_table PIPELINED;

END eadam;
/

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE PACKAGE BODY eadam AS

g_null_c VARCHAR2(2) := '-1';
g_null_n NUMBER := -1;

FUNCTION get_other_xml_awr 
( p_eadam_seq_id    IN NUMBER
, p_dbid            IN NUMBER
, p_sql_id          IN VARCHAR2
, p_plan_hash_value IN NUMBER
, p_id              IN NUMBER 
)
RETURN CLOB IS
  l_row_num NUMBER;
  l_other_xml CLOB;
  l_other_xml_2 CLOB;
BEGIN
  SELECT row_num, other_xml 
    INTO l_row_num, l_other_xml_2 
    FROM dba_hist_sql_plan_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND dbid = p_dbid
     AND sql_id = p_sql_id
     AND plan_hash_value = p_plan_hash_value
     AND id = p_id;
  IF l_other_xml_2 IS NULL OR 
     (DBMS_LOB.instr(l_other_xml_2, '<other_xml>') > 0 AND DBMS_LOB.instr(l_other_xml_2, '</other_xml>') > 0)
  THEN
    RETURN l_other_xml_2;
  END IF;
  DBMS_LOB.createtemporary(l_other_xml, TRUE, DBMS_LOB.call);
  DBMS_LOB.append(l_other_xml, l_other_xml_2);
  FOR i IN (SELECT /*+ PARALLEL(4) */ other_xml
              FROM dba_hist_sql_plan_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND row_num > l_row_num
               AND row_num < l_row_num + 1000 -- max of 255,000 bytes are considered
               AND sql_id IS NULL -- continuation line
               AND other_xml IS NOT NULL
             ORDER BY
                   row_num)
  LOOP
    IF DBMS_LOB.instr(i.other_xml, '<other_xml>') > 0 THEN
      EXIT;
    END IF;
    DBMS_LOB.append(l_other_xml, i.other_xml);
    IF DBMS_LOB.instr(l_other_xml, '</other_xml>') > 0 THEN
      EXIT;
    END IF;
  END LOOP;
  RETURN l_other_xml;
END get_other_xml_awr;

FUNCTION get_other_xml_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER
, p_sql_id          IN VARCHAR2
, p_child_number    IN NUMBER
, p_id              IN NUMBER
)
RETURN CLOB IS
  l_row_num NUMBER;
  l_other_xml CLOB;
  l_other_xml_2 CLOB;
BEGIN
  SELECT /*+ PARALLEL(4) */ row_num, other_xml 
    INTO l_row_num, l_other_xml_2 
    FROM gv_sql_plan_statistics_al_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND inst_id = p_inst_id
     AND sql_id = p_sql_id
     AND child_number = p_child_number
     AND id = p_id;
  IF l_other_xml_2 IS NULL OR 
     (DBMS_LOB.instr(l_other_xml_2, '<other_xml>') > 0 AND DBMS_LOB.instr(l_other_xml_2, '</other_xml>') > 0)
  THEN
    RETURN l_other_xml_2;
  END IF;
  DBMS_LOB.createtemporary(l_other_xml, TRUE, DBMS_LOB.call);
  DBMS_LOB.append(l_other_xml, l_other_xml_2);
  FOR i IN (SELECT /*+ PARALLEL(4) */ other_xml
              FROM gv_sql_plan_statistics_al_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND row_num > l_row_num
               AND row_num < l_row_num + 1000 -- max of 255,000 bytes are considered
               AND sql_id IS NULL -- continuation line
               AND other_xml IS NOT NULL
             ORDER BY
                   row_num)
  LOOP
    IF DBMS_LOB.instr(i.other_xml, '<other_xml>') > 0 THEN
      EXIT;
    END IF;
    DBMS_LOB.append(l_other_xml, i.other_xml);
    IF DBMS_LOB.instr(l_other_xml, '</other_xml>') > 0 THEN
      EXIT;
    END IF;
  END LOOP;
  RETURN l_other_xml;
END get_other_xml_mem;

FUNCTION bytes_to_kmgtp_value
( p_bytes IN INTEGER
)
RETURN NUMBER IS
BEGIN
  IF    p_bytes > POWER(2,50) THEN RETURN ROUND(p_bytes/POWER(2,50),3);
  ELSIF p_bytes > POWER(2,40) THEN RETURN ROUND(p_bytes/POWER(2,40),3);
  ELSIF p_bytes > POWER(2,30) THEN RETURN ROUND(p_bytes/POWER(2,30),3);
  ELSIF p_bytes > POWER(2,20) THEN RETURN ROUND(p_bytes/POWER(2,20),3);
  ELSIF p_bytes > POWER(2,10) THEN RETURN ROUND(p_bytes/POWER(2,10),3);
  ELSIF p_bytes > 0           THEN RETURN p_bytes;
  ELSE                             RETURN NULL;
  END IF;
END bytes_to_kmgtp_value;

FUNCTION bytes_to_kmgtp_unit
( p_bytes IN INTEGER
)
RETURN VARCHAR2 IS
BEGIN
  IF    p_bytes > POWER(2,50) THEN RETURN 'P';
  ELSIF p_bytes > POWER(2,40) THEN RETURN 'T';
  ELSIF p_bytes > POWER(2,30) THEN RETURN 'G';
  ELSIF p_bytes > POWER(2,20) THEN RETURN 'M';
  ELSIF p_bytes > POWER(2,10) THEN RETURN 'K';
  ELSIF p_bytes > 0           THEN RETURN 'B';
  ELSE                             RETURN NULL;
  END IF;
END bytes_to_kmgtp_unit;

FUNCTION bytes_to_kmgtp
( p_bytes IN INTEGER
)
RETURN VARCHAR2 IS
BEGIN
  RETURN bytes_to_kmgtp_value(p_bytes)||' '||bytes_to_kmgtp_unit(p_bytes);
END bytes_to_kmgtp;

FUNCTION cpu_demand_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED IS
  r_cpu_demand_type cpu_demand_type := cpu_demand_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (WITH /*+ eadam.cpu_demand_mem */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   i.dbid,
                   i.db_name,
                   i.host_name,
                   h.inst_id,
                   i.instance_number,
                   i.instance_name,
                   h.sample_time,
                   TRUNC(CAST(h.sample_time AS DATE), 'MI') begin_time,
                   TRUNC(CAST(h.sample_time AS DATE) + (1/24/60), 'MI') end_time,
                   COUNT(*) cpu_demand,
                   SUM(CASE h.session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
                   SUM(CASE h.event WHEN 'resmgr:cpu quantum' THEN 1 ELSE 0 END) waiting_for_cpu
              FROM gv_active_session_history_s h,
                   my_instances i
             WHERE h.eadam_seq_id = p_eadam_seq_id
               AND h.inst_id = NVL(p_inst_id, h.inst_id)
               AND h.sample_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND (h.session_state = 'ON CPU' OR h.event = 'resmgr:cpu quantum')
               AND i.inst_id = h.inst_id
             GROUP BY
                   i.dbid,
                   i.db_name,
                   i.host_name,
                   h.inst_id,
                   i.instance_number,
                   i.instance_name,
                   h.sample_time
            ),
            max_cpu_demand AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   inst_id,
                   PERCENTILE_DISC(p_percentile) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand
              FROM samples
             GROUP BY
                   inst_id            
            ),
            capped_samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.inst_id,
                   s.instance_number,
                   s.instance_name,
                   s.sample_time,
                   s.begin_time,
                   s.end_time,
                   LEAST(s.cpu_demand, m.cpu_demand) cpu_demand,
                   LEAST(s.on_cpu, m.cpu_demand) on_cpu,
                   LEAST(s.waiting_for_cpu, m.cpu_demand) waiting_for_cpu
              FROM samples s,
                   max_cpu_demand m
             WHERE m.inst_id = s.inst_id
            ),
            peak_demand_per_min AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   inst_id,
                   begin_time,
                   MAX(cpu_demand) cpu_demand
              FROM capped_samples
             GROUP BY
                   inst_id,
                   begin_time 
            ),
            max_sample_per_min_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.inst_id,
                   s.begin_time,
                   MIN(s.sample_time) sample_time
              FROM peak_demand_per_min m,
                   capped_samples s
             WHERE s.inst_id = m.inst_id
               AND s.begin_time = m.begin_time
               AND s.cpu_demand = m.cpu_demand
             GROUP BY
                   s.inst_id,
                   s.begin_time 
            ),
            max_per_min_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.inst_id,
                   s.instance_number,
                   s.instance_name,
                   s.sample_time,
                   s.begin_time,
                   s.end_time,
                   (s.on_cpu + s.waiting_for_cpu) cpu_demand,
                   s.on_cpu,
                   s.waiting_for_cpu
              FROM max_sample_per_min_and_inst m,
                   capped_samples s
             WHERE s.inst_id = m.inst_id
               AND s.begin_time = m.begin_time
               AND s.sample_time = m.sample_time 
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_inst_id, MIN(host_name), g_null_c) host_name,
                   NVL2(p_inst_id, MIN(inst_id), g_null_n) inst_id,
                   NVL2(p_inst_id, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_inst_id, MIN(instance_name), g_null_c) instance_name,
                   MIN(sample_time) sample_time,
                   begin_time, 
                   end_time,
                   SUM(cpu_demand) cpu_demand,
                   SUM(on_cpu) on_cpu,
                   SUM(waiting_for_cpu) waiting_for_cpu
              FROM max_per_min_and_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY 
                   end_time
            )
  LOOP
    r_cpu_demand_type.dbid            := i.dbid;       
    r_cpu_demand_type.db_name         := i.db_name;       
    r_cpu_demand_type.host_name       := i.host_name;       
    r_cpu_demand_type.instance_number := i.instance_number;       
    r_cpu_demand_type.instance_name   := i.instance_name;   
    r_cpu_demand_type.sample_time     := i.sample_time;
    r_cpu_demand_type.begin_time      := i.begin_time;       
    r_cpu_demand_type.end_time        := i.end_time;       
    r_cpu_demand_type.cpu_demand      := i.cpu_demand;     
    r_cpu_demand_type.on_cpu          := i.on_cpu;         
    r_cpu_demand_type.waiting_for_cpu := i.waiting_for_cpu;
    PIPE ROW(r_cpu_demand_type);
  END LOOP;
  RETURN;
END cpu_demand_mem;

FUNCTION cpu_demand_peak_mem 
( p_eadam_seq_id    IN NUMBER
, p_inst_id         IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED IS
  r_cpu_demand_type cpu_demand_type := cpu_demand_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (SELECT /*+ eadam.cpu_demand_peak_mem */ * 
            FROM TABLE(eadam.cpu_demand_mem(p_eadam_seq_id, p_inst_id, p_percentile, p_date_from, p_date_to)))
  LOOP
    IF i.cpu_demand >= NVL(r_cpu_demand_type.cpu_demand, 0) THEN
      r_cpu_demand_type.dbid            := i.dbid;       
      r_cpu_demand_type.db_name         := i.db_name;       
      r_cpu_demand_type.host_name       := i.host_name;       
      r_cpu_demand_type.instance_number := i.instance_number;       
      r_cpu_demand_type.instance_name   := i.instance_name;   
      r_cpu_demand_type.sample_time     := i.sample_time;
      r_cpu_demand_type.begin_time      := i.begin_time;       
      r_cpu_demand_type.end_time        := i.end_time;       
      r_cpu_demand_type.cpu_demand      := i.cpu_demand;     
      r_cpu_demand_type.on_cpu          := i.on_cpu;         
      r_cpu_demand_type.waiting_for_cpu := i.waiting_for_cpu;
    END IF;
  END LOOP;
  PIPE ROW(r_cpu_demand_type);
  RETURN;
END cpu_demand_peak_mem;

FUNCTION cpu_demand_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED IS
  r_cpu_demand_type cpu_demand_type := cpu_demand_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (WITH /* cpu_demand_awr */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   h.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   TRUNC(CAST(h.sample_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(h.sample_time AS DATE) + (1/24), 'HH') end_time,
                   COUNT(*) cpu_demand,
                   SUM(CASE h.session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
                   SUM(CASE h.event WHEN 'resmgr:cpu quantum' THEN 1 ELSE 0 END) waiting_for_cpu
              FROM dba_hist_active_sess_hist_s h,
                   my_instances i,
                   dba_hist_snapshot_s s
             WHERE h.eadam_seq_id = p_eadam_seq_id
               AND h.instance_number = NVL(p_instance_number, h.instance_number)
               AND h.sample_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND (h.session_state = 'ON CPU' OR h.event = 'resmgr:cpu quantum')
               AND i.instance_number = h.instance_number
               AND s.eadam_seq_id = p_eadam_seq_id
               AND s.instance_number = NVL(p_instance_number, s.instance_number)
               AND s.end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND s.snap_id = h.snap_id
               AND s.dbid = h.dbid
               AND s.instance_number = h.instance_number
             GROUP BY
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   h.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time
            ),
            max_cpu_demand AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   PERCENTILE_DISC(p_percentile) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand
              FROM samples
             GROUP BY
                   dbid,
                   instance_number            
            ),
            capped_samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   LEAST(s.cpu_demand, m.cpu_demand) cpu_demand,
                   LEAST(s.on_cpu, m.cpu_demand) on_cpu,
                   LEAST(s.waiting_for_cpu, m.cpu_demand) waiting_for_cpu
              FROM samples s,
                   max_cpu_demand m
             WHERE m.dbid = s.dbid
               AND m.instance_number = s.instance_number
            ),
            peak_demand_per_hour AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   MIN(snap_id) snap_id,
                   dbid,
                   instance_number,
                   begin_time,
                   MAX(cpu_demand) cpu_demand
              FROM capped_samples
             GROUP BY
                   dbid,
                   instance_number,
                   begin_time 
            ),
            max_sample_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.instance_number,
                   s.begin_time,
                   MIN(s.sample_time) sample_time
              FROM peak_demand_per_hour m,
                   capped_samples s
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.cpu_demand = m.cpu_demand
             GROUP BY
                   s.dbid,
                   s.instance_number,
                   s.begin_time 
            ),
            max_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   (s.on_cpu + s.waiting_for_cpu) cpu_demand,
                   s.on_cpu,
                   s.waiting_for_cpu
              FROM max_sample_per_hour_and_inst m,
                   capped_samples s
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.sample_time = m.sample_time 
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(sample_time) sample_time,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time, 
                   end_time,
                   SUM(cpu_demand) cpu_demand,
                   SUM(on_cpu) on_cpu,
                   SUM(waiting_for_cpu) waiting_for_cpu
              FROM max_per_hour_and_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY 
                   end_time
            )
  LOOP
    r_cpu_demand_type.dbid                := i.dbid;       
    r_cpu_demand_type.db_name             := i.db_name;       
    r_cpu_demand_type.host_name           := i.host_name;       
    r_cpu_demand_type.instance_number     := i.instance_number;       
    r_cpu_demand_type.instance_name       := i.instance_name;   
    r_cpu_demand_type.sample_time         := i.sample_time;
    r_cpu_demand_type.snap_id             := i.snap_id;       
    r_cpu_demand_type.begin_interval_time := i.begin_interval_time;
    r_cpu_demand_type.end_interval_time   := i.end_interval_time;
    r_cpu_demand_type.begin_time          := i.begin_time;       
    r_cpu_demand_type.end_time            := i.end_time;       
    r_cpu_demand_type.cpu_demand          := i.cpu_demand;     
    r_cpu_demand_type.on_cpu              := i.on_cpu;         
    r_cpu_demand_type.waiting_for_cpu     := i.waiting_for_cpu;
    PIPE ROW(r_cpu_demand_type);
  END LOOP;
  RETURN;
END cpu_demand_awr;

FUNCTION cpu_demand_peak_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_type_table PIPELINED IS
  r_cpu_demand_type cpu_demand_type := cpu_demand_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (SELECT /*+ eadam.cpu_demand_peak_awr */ * 
            FROM TABLE(eadam.cpu_demand_awr(p_eadam_seq_id, p_instance_number, p_percentile, p_date_from, p_date_to)))
  LOOP
    IF i.cpu_demand >= NVL(r_cpu_demand_type.cpu_demand, 0) THEN
      r_cpu_demand_type.dbid                := i.dbid;       
      r_cpu_demand_type.db_name             := i.db_name;       
      r_cpu_demand_type.host_name           := i.host_name;       
      r_cpu_demand_type.instance_number     := i.instance_number;       
      r_cpu_demand_type.instance_name       := i.instance_name;   
      r_cpu_demand_type.sample_time         := i.sample_time;
      r_cpu_demand_type.snap_id             := i.snap_id;       
      r_cpu_demand_type.begin_interval_time := i.begin_interval_time;
      r_cpu_demand_type.end_interval_time   := i.end_interval_time;
      r_cpu_demand_type.begin_time          := i.begin_time;       
      r_cpu_demand_type.end_time            := i.end_time;       
      r_cpu_demand_type.cpu_demand          := i.cpu_demand;     
      r_cpu_demand_type.on_cpu              := i.on_cpu;         
      r_cpu_demand_type.waiting_for_cpu     := i.waiting_for_cpu;
    END IF;
  END LOOP;
  PIPE ROW(r_cpu_demand_type);
  RETURN;
END cpu_demand_peak_awr;

FUNCTION cpu_demand_mm_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_demand_mm_type_table PIPELINED IS
  r_cpu_demand_mm_type cpu_demand_mm_type := cpu_demand_mm_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (WITH /* cpu_demand_awr */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   h.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   TRUNC(CAST(h.sample_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(h.sample_time AS DATE) + (1/24), 'HH') end_time,
                   COUNT(*) cpu_demand
              FROM dba_hist_active_sess_hist_s h,
                   my_instances i,
                   dba_hist_snapshot_s s
             WHERE h.eadam_seq_id = p_eadam_seq_id
               AND h.instance_number = NVL(p_instance_number, h.instance_number)
               AND h.sample_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND (h.session_state = 'ON CPU' OR h.event = 'resmgr:cpu quantum')
               AND i.instance_number = h.instance_number
               AND s.eadam_seq_id = p_eadam_seq_id
               AND s.instance_number = NVL(p_instance_number, s.instance_number)
               AND s.end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND s.snap_id = h.snap_id
               AND s.dbid = h.dbid
               AND s.instance_number = h.instance_number
             GROUP BY
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   h.sample_time,
                   s.begin_interval_time,
                   s.end_interval_time
            ),
            mm_demand_per_hour AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   db_name,
                   host_name,
                   instance_number,
                   instance_name,
                   begin_time,
                   end_time,
                   MIN(sample_time) sample_time,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   MAX(cpu_demand)                                          cpu_demand_max,
                   ROUND(AVG(cpu_demand), 1)                                cpu_demand_avg,
                   ROUND(MEDIAN(cpu_demand), 1)                             cpu_demand_med,
                   MIN(cpu_demand)                                          cpu_demand_min,
                   PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand_99p,
                   PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand_95p,
                   PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand_90p,
                   PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY cpu_demand) cpu_demand_75p
              FROM samples
             GROUP BY
                   dbid,
                   db_name,
                   host_name,
                   instance_number,
                   instance_name,
                   begin_time,
                   end_time
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(sample_time) sample_time,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time, 
                   end_time,
                   SUM(cpu_demand_max) cpu_demand_max,
                   SUM(cpu_demand_avg) cpu_demand_avg,
                   SUM(cpu_demand_med) cpu_demand_med,
                   SUM(cpu_demand_min) cpu_demand_min,
                   SUM(cpu_demand_99p) cpu_demand_99p,
                   SUM(cpu_demand_95p) cpu_demand_95p,
                   SUM(cpu_demand_90p) cpu_demand_90p,
                   SUM(cpu_demand_75p) cpu_demand_75p
              FROM mm_demand_per_hour
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY 
                   begin_time,
                   end_time
            )
  LOOP
    r_cpu_demand_mm_type.dbid                := i.dbid;       
    r_cpu_demand_mm_type.db_name             := i.db_name;       
    r_cpu_demand_mm_type.host_name           := i.host_name;       
    r_cpu_demand_mm_type.instance_number     := i.instance_number;       
    r_cpu_demand_mm_type.instance_name       := i.instance_name;   
    r_cpu_demand_mm_type.sample_time         := i.sample_time;
    r_cpu_demand_mm_type.snap_id             := i.snap_id;       
    r_cpu_demand_mm_type.begin_interval_time := i.begin_interval_time;
    r_cpu_demand_mm_type.end_interval_time   := i.end_interval_time;
    r_cpu_demand_mm_type.begin_time          := i.begin_time;       
    r_cpu_demand_mm_type.end_time            := i.end_time;       
    r_cpu_demand_mm_type.cpu_demand_max      := i.cpu_demand_max;     
    r_cpu_demand_mm_type.cpu_demand_avg      := i.cpu_demand_avg;         
    r_cpu_demand_mm_type.cpu_demand_med      := i.cpu_demand_med;
    r_cpu_demand_mm_type.cpu_demand_min      := i.cpu_demand_min;
    r_cpu_demand_mm_type.cpu_demand_99p      := i.cpu_demand_99p;
    r_cpu_demand_mm_type.cpu_demand_95p      := i.cpu_demand_95p;
    r_cpu_demand_mm_type.cpu_demand_90p      := i.cpu_demand_90p;
    r_cpu_demand_mm_type.cpu_demand_75p      := i.cpu_demand_75p;
    PIPE ROW(r_cpu_demand_mm_type);
  END LOOP;
  RETURN;
END cpu_demand_mm_awr;

FUNCTION cpu_consumption_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_consumption_type_table PIPELINED IS
  l_minimum_snap_id NUMBER;
  l_maximum_snap_id NUMBER;
  r_cpu_consumption_type cpu_consumption_type := cpu_consumption_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  SELECT MIN(snap_id) , MAX(snap_id) 
    INTO l_minimum_snap_id, l_maximum_snap_id
    FROM dba_hist_snapshot_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND instance_number = NVL(p_instance_number, instance_number)
     AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1;

  FOR i IN (WITH /*+ eadam.cpu_consumption_awr */
            cpu_time AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   instance_number,
                   SUM(value / 1e6) consumed_cpu,
                   SUM(CASE stat_name WHEN 'background cpu time' THEN value / 1e6 ELSE 0 END) background_cpu,
                   SUM(CASE stat_name WHEN 'DB CPU' THEN value / 1e6 ELSE 0 END) db_cpu
              FROM dba_hist_sys_time_model_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND instance_number = NVL(p_instance_number, instance_number)
               AND snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND stat_name IN ('background cpu time', 'DB CPU')
             GROUP BY
                   snap_id,
                   dbid,
                   instance_number
            ),
            cpu_time_extended AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE ORDERED */
                   h1.snap_id,
                   h1.dbid,
                   di.db_name,
                   di.host_name,
                   h1.instance_number,
                   di.instance_name,
                   s1.begin_interval_time,
                   s1.end_interval_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') + (1/24) end_time,
                   ROUND((CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 24 * 60 * 60) interval_secs,
                   (h1.consumed_cpu - h0.consumed_cpu) consumed_cpu,
                   (h1.background_cpu - h0.background_cpu) background_cpu,
                   (h1.db_cpu - h0.db_cpu) db_cpu
              FROM cpu_time h0,
                   cpu_time h1,
                   dba_hist_snapshot_s s0,
                   dba_hist_snapshot_s s1,
                   dba_hist_database_instanc_s di
             WHERE h1.snap_id = h0.snap_id + 1
               AND h1.dbid = h0.dbid
               AND h1.instance_number = h0.instance_number
               AND s0.eadam_seq_id = p_eadam_seq_id
               AND s0.instance_number = NVL(p_instance_number, s0.instance_number)
               AND s0.end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND s0.snap_id = h0.snap_id
               AND s0.dbid = h0.dbid
               AND s0.instance_number = h0.instance_number
               AND s1.eadam_seq_id = p_eadam_seq_id
               AND s1.instance_number = NVL(p_instance_number, s1.instance_number)
               AND s1.end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND s1.snap_id = h1.snap_id
               AND s1.dbid = h1.dbid
               AND s1.instance_number = h1.instance_number
               AND s1.snap_id = s0.snap_id + 1
               AND s1.dbid = s0.dbid
               AND s1.instance_number = s0.instance_number
               AND s1.startup_time = s0.startup_time
               AND s1.begin_interval_time > (s0.begin_interval_time + (1 / (24 * 60))) /* filter out snaps apart < 1 min */
               AND di.eadam_seq_id = p_eadam_seq_id
               AND di.dbid = s1.dbid
               AND di.instance_number = s1.instance_number
               AND di.startup_time = s1.startup_time
            ),
            cpu_time_aas AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   db_name,
                   host_name,
                   instance_number,
                   instance_name,
                   begin_interval_time,
                   end_interval_time,
                   begin_time,
                   end_time,
                   interval_secs,
                   consumed_cpu,
                   background_cpu,
                   db_cpu,
                   ROUND(consumed_cpu / interval_secs, 1) aas_consumed_cpu,
                   ROUND(background_cpu / interval_secs, 1) aas_background_cpu,
                   ROUND(db_cpu / interval_secs, 1) aas_db_cpu
              FROM cpu_time_extended
            ),
            max_cpu_consumption AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   PERCENTILE_DISC(p_percentile) WITHIN GROUP (ORDER BY aas_consumed_cpu) aas_consumed_cpu
              FROM cpu_time_aas
             GROUP BY
                   dbid,
                   instance_number            
            ),
            capped_samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   LEAST(s.aas_consumed_cpu, m.aas_consumed_cpu) aas_consumed_cpu,
                   LEAST(s.aas_background_cpu, m.aas_consumed_cpu) aas_background_cpu,
                   LEAST(s.aas_db_cpu, m.aas_consumed_cpu) aas_db_cpu
              FROM cpu_time_aas s,
                   max_cpu_consumption m
             WHERE m.dbid = s.dbid
               AND m.instance_number = s.instance_number
            ),
            peak_consumption_per_hour AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   begin_time,
                   MAX(aas_consumed_cpu) aas_consumed_cpu
              FROM capped_samples
             GROUP BY
                   dbid,
                   instance_number,
                   begin_time 
            ),
            max_sample_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.instance_number,
                   s.begin_time,
                   MIN(s.snap_id) snap_id
              FROM peak_consumption_per_hour m,
                   capped_samples s
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.aas_consumed_cpu = m.aas_consumed_cpu
             GROUP BY
                   s.dbid,
                   s.instance_number,
                   s.begin_time 
            ),
            max_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   (s.aas_background_cpu + s.aas_db_cpu) aas_consumed_cpu,
                   s.aas_background_cpu,
                   s.aas_db_cpu
              FROM max_sample_per_hour_and_inst m,
                   capped_samples s
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.snap_id = m.snap_id 
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time, 
                   end_time,
                   SUM(aas_consumed_cpu) consumed_cpu,
                   SUM(aas_background_cpu) background_cpu,
                   SUM(aas_db_cpu) db_cpu
              FROM max_per_hour_and_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY 
                   end_time
            )
  LOOP
    r_cpu_consumption_type.dbid                := i.dbid;       
    r_cpu_consumption_type.db_name             := i.db_name;       
    r_cpu_consumption_type.host_name           := i.host_name;       
    r_cpu_consumption_type.instance_number     := i.instance_number;       
    r_cpu_consumption_type.instance_name       := i.instance_name;   
    r_cpu_consumption_type.snap_id             := i.snap_id;
    r_cpu_consumption_type.begin_interval_time := i.begin_interval_time;
    r_cpu_consumption_type.end_interval_time   := i.end_interval_time;
    r_cpu_consumption_type.begin_time          := i.begin_time;       
    r_cpu_consumption_type.end_time            := i.end_time;       
    r_cpu_consumption_type.consumed_cpu        := i.consumed_cpu;     
    r_cpu_consumption_type.background_cpu      := i.background_cpu;         
    r_cpu_consumption_type.db_cpu              := i.db_cpu;
    PIPE ROW(r_cpu_consumption_type);
  END LOOP;
  RETURN;
END cpu_consumption_awr;

FUNCTION cpu_consumption_peak_awr 
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN cpu_consumption_type_table PIPELINED IS
  r_cpu_consumption_type cpu_consumption_type := cpu_consumption_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (SELECT /*+ eadam.cpu_consumption_peak_awr */ * 
            FROM TABLE(eadam.cpu_consumption_awr(p_eadam_seq_id, p_instance_number, p_percentile, p_date_from, p_date_to)))
  LOOP
    IF i.consumed_cpu >= NVL(r_cpu_consumption_type.consumed_cpu, 0) THEN
      r_cpu_consumption_type.dbid                := i.dbid;       
      r_cpu_consumption_type.db_name             := i.db_name;       
      r_cpu_consumption_type.host_name           := i.host_name;       
      r_cpu_consumption_type.instance_number     := i.instance_number;       
      r_cpu_consumption_type.instance_name       := i.instance_name;   
      r_cpu_consumption_type.snap_id             := i.snap_id;
      r_cpu_consumption_type.begin_interval_time := i.begin_interval_time;
      r_cpu_consumption_type.end_interval_time   := i.end_interval_time;
      r_cpu_consumption_type.begin_time          := i.begin_time;       
      r_cpu_consumption_type.end_time            := i.end_time;       
      r_cpu_consumption_type.consumed_cpu        := i.consumed_cpu;     
      r_cpu_consumption_type.background_cpu      := i.background_cpu;         
      r_cpu_consumption_type.db_cpu              := i.db_cpu;
    END IF;
  END LOOP;
  PIPE ROW(r_cpu_consumption_type);
  RETURN;
END cpu_consumption_peak_awr;

FUNCTION memory_usage_awr
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN memory_usage_type_table PIPELINED IS
  l_minimum_snap_id NUMBER;
  l_maximum_snap_id NUMBER;
  r_memory_usage_type memory_usage_type := memory_usage_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  SELECT MIN(snap_id) , MAX(snap_id) 
    INTO l_minimum_snap_id, l_maximum_snap_id
    FROM dba_hist_snapshot_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND instance_number = NVL(p_instance_number, instance_number)
     AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1;

  FOR i IN (WITH /*+ eadam.memory_usage_awr */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            sga AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   instance_number,
                   SUM(value) bytes
              FROM dba_hist_sga_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND instance_number = NVL(p_instance_number, instance_number)
               AND snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
             GROUP BY
                   snap_id,
                   dbid,
                   instance_number
            ),
            pga AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   instance_number,
                   value bytes
              FROM dba_hist_pgastat_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND instance_number = NVL(p_instance_number, instance_number)
               AND snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND name = 'maximum PGA allocated'
            ),
            mem AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE ORDERED */
                   snp.snap_id,
                   snp.dbid,
                   ins.db_name,
                   ins.host_name,
                   snp.instance_number,
                   ins.instance_name,
                   ins.inst_id,
                   snp.begin_interval_time,
                   snp.end_interval_time,
                   TRUNC(CAST(snp.begin_interval_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(snp.begin_interval_time AS DATE), 'HH') + (1/24) end_time,
                   sga.bytes sga_bytes,
                   pga.bytes pga_bytes,
                   (sga.bytes + pga.bytes) mem_bytes
              FROM sga, pga, dba_hist_snapshot_s snp, my_instances ins
             WHERE pga.snap_id = sga.snap_id
               AND pga.dbid = sga.dbid
               AND pga.instance_number = sga.instance_number
               AND snp.eadam_seq_id = p_eadam_seq_id
               AND snp.instance_number = NVL(p_instance_number, snp.instance_number)
               AND snp.snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND snp.end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
               AND snp.snap_id = sga.snap_id
               AND snp.dbid = sga.dbid
               AND snp.instance_number = sga.instance_number
               AND ins.instance_number = snp.instance_number
            ),
            hourly_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   MIN(snap_id) snap_id,
                   dbid,
                   db_name,
                   host_name,
                   instance_number,
                   instance_name,
                   inst_id,
                   begin_time,
                   end_time,
                   MAX(mem_bytes) mem_bytes,
                   MAX(sga_bytes) sga_bytes,
                   MAX(pga_bytes) pga_bytes,
                   MIN(begin_interval_time) begin_interval_time,
                   MAX(end_interval_time) end_interval_time
              FROM mem
             GROUP BY
                   dbid,
                   db_name,
                   host_name,
                   instance_number,
                   instance_name,
                   inst_id,
                   begin_time,
                   end_time
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time,
                   end_time,
                   ROUND(SUM(mem_bytes) / POWER(2, 30), 3) mem_gb,
                   ROUND(SUM(sga_bytes) / POWER(2, 30), 3) sga_gb,
                   ROUND(SUM(pga_bytes) / POWER(2, 30), 3) pga_gb
              FROM hourly_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY
                   end_time
            )
  LOOP
    r_memory_usage_type.dbid                := i.dbid;       
    r_memory_usage_type.db_name             := i.db_name;       
    r_memory_usage_type.host_name           := i.host_name;       
    r_memory_usage_type.instance_number     := i.instance_number;       
    r_memory_usage_type.instance_name       := i.instance_name;   
    r_memory_usage_type.snap_id             := i.snap_id;       
    r_memory_usage_type.begin_interval_time := i.begin_interval_time;
    r_memory_usage_type.end_interval_time   := i.end_interval_time;
    r_memory_usage_type.begin_time          := i.begin_time;
    r_memory_usage_type.end_time            := i.end_time;  
    r_memory_usage_type.mem_gb              := i.mem_gb;    
    r_memory_usage_type.sga_gb              := i.sga_gb;   
    r_memory_usage_type.pga_gb              := i.pga_gb;    
    PIPE ROW(r_memory_usage_type);
  END LOOP;
  RETURN;
END memory_usage_awr;

FUNCTION iops
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN iops_type_table PIPELINED IS
  l_minimum_snap_id NUMBER;
  l_maximum_snap_id NUMBER;
  r_iops_type iops_type := iops_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  SELECT MIN(snap_id) , MAX(snap_id) 
    INTO l_minimum_snap_id, l_maximum_snap_id
    FROM dba_hist_snapshot_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND instance_number = NVL(p_instance_number, instance_number)
     AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1;

  FOR i IN (WITH /*+ eadam.iops */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            sysstat_io AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN value ELSE 0 END) r_reqs,
                   SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN value ELSE 0 END) w_reqs,
                   SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN value ELSE 0 END) r_bytes,
                   SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN value ELSE 0 END) w_bytes
              FROM dba_hist_sysstat_s h,
                   my_instances i
             WHERE h.eadam_seq_id = p_eadam_seq_id
               AND h.instance_number = NVL(p_instance_number, h.instance_number)
               AND h.snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND h.stat_name IN ('physical read total IO requests', 'physical write total IO requests', 'redo writes', 'physical read total bytes', 'physical write total bytes', 'redo size')
               AND i.instance_number = h.instance_number
             GROUP BY
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id
            ),
            snaps AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   instance_number,
                   begin_interval_time,
                   end_interval_time,
                   ((CAST(end_interval_time AS DATE) - CAST(begin_interval_time AS DATE)) * 24 * 60 * 60) elapsed_sec,
                   startup_time
              FROM dba_hist_snapshot_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND instance_number = NVL(p_instance_number, instance_number)
               AND snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
            ),
            rw_per_snap_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE ORDERED */
                   t1.snap_id,
                   t1.dbid,
                   t1.db_name,
                   t1.host_name,
                   t1.instance_number,
                   t1.instance_name,
                   t1.inst_id,
                   s1.begin_interval_time,
                   s1.end_interval_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') + (1/24) end_time,
                   ROUND((t1.r_reqs - t0.r_reqs + t1.w_reqs - t0.w_reqs) / s1.elapsed_sec) rw_iops,
                   ROUND((t1.r_reqs - t0.r_reqs) / s1.elapsed_sec) r_iops,
                   ROUND((t1.w_reqs - t0.w_reqs) / s1.elapsed_sec) w_iops
              FROM sysstat_io t0,
                   sysstat_io t1,
                   snaps s0,
                   snaps s1
             WHERE t1.snap_id = t0.snap_id + 1
               AND t1.dbid = t0.dbid
               AND t1.instance_number = t0.instance_number
               AND s0.snap_id = t0.snap_id
               AND s0.dbid = t0.dbid
               AND s0.instance_number = t0.instance_number
               AND s1.snap_id = t1.snap_id
               AND s1.dbid = t1.dbid
               AND s1.instance_number = t1.instance_number
               AND s1.snap_id = s0.snap_id + 1
               AND s1.startup_time = s0.startup_time
               AND s1.elapsed_sec > 60 -- ignore snaps too close
            ),
            max_rw_iops AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   PERCENTILE_DISC(p_percentile) WITHIN GROUP (ORDER BY rw_iops) rw_iops
              FROM rw_per_snap_and_inst
             GROUP BY
                   dbid,
                   instance_number            
            ),
            capped_samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   LEAST(s.rw_iops, m.rw_iops) rw_iops,
                   LEAST(s.r_iops, m.rw_iops) r_iops,
                   LEAST(s.w_iops, m.rw_iops) w_iops
              FROM rw_per_snap_and_inst s,
                   max_rw_iops m
             WHERE m.dbid = s.dbid
               AND m.instance_number = s.instance_number
            ),
            max_rw_per_hour_and_inst AS ( 
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   begin_time,
                   MAX(rw_iops) rw_iops
              FROM capped_samples
             GROUP BY
                   dbid,
                   instance_number,
                   begin_time
            ),
            snap_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.instance_number,
                   s.begin_time,
                   MIN(s.snap_id) snap_id
              FROM capped_samples s,
                   max_rw_per_hour_and_inst m
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.rw_iops = m.rw_iops
             GROUP BY
                   s.dbid,
                   s.instance_number,
                   s.begin_time
            ),
            max_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.begin_time,
                   s.end_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.r_iops,
                   s.w_iops,
                   (s.r_iops + s.w_iops) rw_iops
              FROM capped_samples s,
                   snap_per_hour_and_inst h
             WHERE h.dbid = s.dbid
               AND h.instance_number = s.instance_number
               AND h.begin_time = s.begin_time
               AND h.snap_id = s.snap_id
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time,
                   end_time,
                   SUM(rw_iops) rw_iops,
                   SUM(r_iops) r_iops,
                   SUM(w_iops) w_iops
              FROM max_per_hour_and_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY
                   end_time
            )
  LOOP
    r_iops_type.dbid                := i.dbid;       
    r_iops_type.db_name             := i.db_name;       
    r_iops_type.host_name           := i.host_name;       
    r_iops_type.instance_number     := i.instance_number;       
    r_iops_type.instance_name       := i.instance_name;   
    r_iops_type.snap_id             := i.snap_id;       
    r_iops_type.begin_interval_time := i.begin_interval_time;
    r_iops_type.end_interval_time   := i.end_interval_time;
    r_iops_type.begin_time          := i.begin_time;
    r_iops_type.end_time            := i.end_time;  
    r_iops_type.rw_iops             := i.rw_iops;   
    r_iops_type.r_iops              := i.r_iops;    
    r_iops_type.w_iops              := i.w_iops;    
    PIPE ROW(r_iops_type);
  END LOOP;
  RETURN;
END iops;

FUNCTION iops_peak
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN iops_type_table PIPELINED IS
  r_iops_type iops_type := iops_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (SELECT /*+ eadam.io_iops_peak */ * 
            FROM TABLE(eadam.iops(p_eadam_seq_id, p_instance_number, p_percentile, p_date_from, p_date_to)))
  LOOP
    IF i.rw_iops >= NVL(r_iops_type.rw_iops, 0) THEN
      r_iops_type.dbid                := i.dbid;       
      r_iops_type.db_name             := i.db_name;       
      r_iops_type.host_name           := i.host_name;       
      r_iops_type.instance_number     := i.instance_number;       
      r_iops_type.instance_name       := i.instance_name;   
      r_iops_type.snap_id             := i.snap_id;       
      r_iops_type.begin_interval_time := i.begin_interval_time;
      r_iops_type.end_interval_time   := i.end_interval_time;
      r_iops_type.begin_time          := i.begin_time;
      r_iops_type.end_time            := i.end_time;  
      r_iops_type.rw_iops             := i.rw_iops;   
      r_iops_type.r_iops              := i.r_iops;    
      r_iops_type.w_iops              := i.w_iops;    
    END IF;
  END LOOP;
  PIPE ROW(r_iops_type);
  RETURN;
END iops_peak;

FUNCTION mbps
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN mbps_type_table PIPELINED IS
  l_minimum_snap_id NUMBER;
  l_maximum_snap_id NUMBER;
  r_mbps_type mbps_type := mbps_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  SELECT MIN(snap_id) , MAX(snap_id) 
    INTO l_minimum_snap_id, l_maximum_snap_id
    FROM dba_hist_snapshot_s
   WHERE eadam_seq_id = p_eadam_seq_id
     AND instance_number = NVL(p_instance_number, instance_number)
     AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1;

  FOR i IN (WITH /*+ eadam.mbps */
            my_instances AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */ *
              FROM instances
             WHERE eadam_seq_id = p_eadam_seq_id
            ),
            sysstat_io AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id,
                   SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN value ELSE 0 END) r_reqs,
                   SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN value ELSE 0 END) w_reqs,
                   SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN value ELSE 0 END) r_bytes,
                   SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN value ELSE 0 END) w_bytes
              FROM dba_hist_sysstat_s h,
                   my_instances i
             WHERE h.eadam_seq_id = p_eadam_seq_id
               AND h.instance_number = NVL(p_instance_number, h.instance_number)
               AND h.snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND h.stat_name IN ('physical read total IO requests', 'physical write total IO requests', 'redo writes', 'physical read total bytes', 'physical write total bytes', 'redo size')
               AND i.instance_number = h.instance_number
             GROUP BY
                   h.snap_id,
                   h.dbid,
                   i.db_name,
                   i.host_name,
                   h.instance_number,
                   i.instance_name,
                   i.inst_id
            ),
            snaps AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   snap_id,
                   dbid,
                   instance_number,
                   begin_interval_time,
                   end_interval_time,
                   ((CAST(end_interval_time AS DATE) - CAST(begin_interval_time AS DATE)) * 24 * 60 * 60) elapsed_sec,
                   startup_time
              FROM dba_hist_snapshot_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND instance_number = NVL(p_instance_number, instance_number)
               AND snap_id BETWEEN l_minimum_snap_id AND l_maximum_snap_id
               AND end_interval_time BETWEEN TRUNC(p_date_from) AND TRUNC(p_date_to) + 1
            ),
            rw_per_snap_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE ORDERED */
                   t1.snap_id,
                   t1.dbid,
                   t1.db_name,
                   t1.host_name,
                   t1.instance_number,
                   t1.instance_name,
                   t1.inst_id,
                   s1.begin_interval_time,
                   s1.end_interval_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') begin_time,
                   TRUNC(CAST(s1.begin_interval_time AS DATE), 'HH') + (1/24) end_time,
                   ROUND((t1.r_bytes - t0.r_bytes + t1.w_bytes - t0.w_bytes) / POWER(2, 20) / s1.elapsed_sec) rw_mbps,
                   ROUND((t1.r_bytes - t0.r_bytes) / POWER(2, 20) / s1.elapsed_sec) r_mbps,
                   ROUND((t1.w_bytes - t0.w_bytes) / POWER(2, 20) / s1.elapsed_sec) w_mbps
              FROM sysstat_io t0,
                   sysstat_io t1,
                   snaps s0,
                   snaps s1
             WHERE t1.snap_id = t0.snap_id + 1
               AND t1.dbid = t0.dbid
               AND t1.instance_number = t0.instance_number
               AND s0.snap_id = t0.snap_id
               AND s0.dbid = t0.dbid
               AND s0.instance_number = t0.instance_number
               AND s1.snap_id = t1.snap_id
               AND s1.dbid = t1.dbid
               AND s1.instance_number = t1.instance_number
               AND s1.snap_id = s0.snap_id + 1
               AND s1.startup_time = s0.startup_time
               AND s1.elapsed_sec > 60 -- ignore snaps too close
            ),
            max_rw_mbps AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   PERCENTILE_DISC(p_percentile) WITHIN GROUP (ORDER BY rw_mbps) rw_mbps
              FROM rw_per_snap_and_inst
             GROUP BY
                   dbid,
                   instance_number            
            ),
            capped_samples AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.begin_time,
                   s.end_time,
                   LEAST(s.rw_mbps, m.rw_mbps) rw_mbps,
                   LEAST(s.r_mbps, m.rw_mbps) r_mbps,
                   LEAST(s.w_mbps, m.rw_mbps) w_mbps
              FROM rw_per_snap_and_inst s,
                   max_rw_mbps m
             WHERE m.dbid = s.dbid
               AND m.instance_number = s.instance_number
            ),
            max_rw_per_hour_and_inst AS ( 
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   dbid,
                   instance_number,
                   begin_time,
                   MAX(rw_mbps) rw_mbps
              FROM capped_samples
             GROUP BY
                   dbid,
                   instance_number,
                   begin_time
            ),
            snap_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.dbid,
                   s.instance_number,
                   s.begin_time,
                   MIN(s.snap_id) snap_id
              FROM capped_samples s,
                   max_rw_per_hour_and_inst m
             WHERE s.dbid = m.dbid
               AND s.instance_number = m.instance_number
               AND s.begin_time = m.begin_time
               AND s.rw_mbps = m.rw_mbps
             GROUP BY
                   s.dbid,
                   s.instance_number,
                   s.begin_time
            ),
            max_per_hour_and_inst AS (
            SELECT /*+ PARALLEL(4) MATERIALIZE NO_MERGE */
                   s.snap_id,
                   s.dbid,
                   s.db_name,
                   s.host_name,
                   s.instance_number,
                   s.instance_name,
                   s.inst_id,
                   s.begin_time,
                   s.end_time,
                   s.begin_interval_time,
                   s.end_interval_time,
                   s.r_mbps,
                   s.w_mbps,
                   (s.r_mbps + s.w_mbps) rw_mbps
              FROM capped_samples s,
                   snap_per_hour_and_inst h
             WHERE h.dbid = s.dbid
               AND h.instance_number = s.instance_number
               AND h.begin_time = s.begin_time
               AND h.snap_id = s.snap_id
            )
            SELECT MIN(dbid) dbid,
                   MIN(db_name) db_name,
                   NVL2(p_instance_number, MIN(host_name), g_null_c) host_name,
                   NVL2(p_instance_number, MIN(instance_number), g_null_n) instance_number,
                   NVL2(p_instance_number, MIN(instance_name), g_null_c) instance_name,
                   MIN(snap_id) snap_id,
                   MIN(begin_interval_time) begin_interval_time,
                   MIN(end_interval_time) end_interval_time,
                   begin_time,
                   end_time,
                   SUM(rw_mbps) rw_mbps,
                   SUM(r_mbps) r_mbps,
                   SUM(w_mbps) w_mbps
              FROM max_per_hour_and_inst
             GROUP BY
                   begin_time,
                   end_time
             ORDER BY
                   end_time
            )
  LOOP
    r_mbps_type.dbid                := i.dbid;       
    r_mbps_type.db_name             := i.db_name;       
    r_mbps_type.host_name           := i.host_name;       
    r_mbps_type.instance_number     := i.instance_number;       
    r_mbps_type.instance_name       := i.instance_name;   
    r_mbps_type.snap_id             := i.snap_id;       
    r_mbps_type.begin_interval_time := i.begin_interval_time;
    r_mbps_type.end_interval_time   := i.end_interval_time;
    r_mbps_type.begin_time          := i.begin_time;
    r_mbps_type.end_time            := i.end_time;  
    r_mbps_type.rw_mbps             := i.rw_mbps;   
    r_mbps_type.r_mbps              := i.r_mbps;    
    r_mbps_type.w_mbps              := i.w_mbps;    
    PIPE ROW(r_mbps_type);
  END LOOP;
  RETURN;
END mbps;

FUNCTION mbps_peak
( p_eadam_seq_id    IN NUMBER
, p_instance_number IN NUMBER DEFAULT NULL
, p_percentile      IN NUMBER DEFAULT 1 /* 0-1: 1 -> 100%, 0.9999 -> 99.99%, 0.999 -> 99.9%, 0.99 -> 99%, 0.95 -> 95%, 0.5 -> median */
, p_date_from       IN DATE   DEFAULT ADD_MONTHS(SYSDATE, -120)
, p_date_to         IN DATE   DEFAULT SYSDATE
)
RETURN mbps_type_table PIPELINED IS
  r_mbps_type mbps_type := mbps_type(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
BEGIN
  FOR i IN (SELECT /*+ eadam.io_mbps_peak */ * 
            FROM TABLE(eadam.mbps(p_eadam_seq_id, p_instance_number, p_percentile, p_date_from, p_date_to)))
  LOOP
    IF i.rw_mbps >= NVL(r_mbps_type.rw_mbps, 0) THEN
      r_mbps_type.dbid                := i.dbid;       
      r_mbps_type.db_name             := i.db_name;       
      r_mbps_type.host_name           := i.host_name;       
      r_mbps_type.instance_number     := i.instance_number;       
      r_mbps_type.instance_name       := i.instance_name;   
      r_mbps_type.snap_id             := i.snap_id;       
      r_mbps_type.begin_interval_time := i.begin_interval_time;
      r_mbps_type.end_interval_time   := i.end_interval_time;
      r_mbps_type.begin_time          := i.begin_time;
      r_mbps_type.end_time            := i.end_time;  
      r_mbps_type.rw_mbps             := i.rw_mbps;   
      r_mbps_type.r_mbps              := i.r_mbps;    
      r_mbps_type.w_mbps              := i.w_mbps;    
    END IF;
  END LOOP;
  PIPE ROW(r_mbps_type);
  RETURN;
END mbps_peak;

END eadam;
/

SHO ERRORS;

/* ------------------------------------------------------------------------- */

SET ECHO OFF FEED OFF;
SPO OFF;
