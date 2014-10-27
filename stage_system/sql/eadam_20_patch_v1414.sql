SPO eadam_patch.txt;
SET ECHO ON VER ON FEED ON;

-- sysman.gc$metric_values_hourly
CREATE TABLE &&eadam_user..gc_metric_values_hourly_s 
( eadam_seq_id              NUMBER
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

CREATE TABLE &&eadam_user..row_counts
( eadam_seq_id              NUMBER
, table_name                VARCHAR2(30)
, external_table_row_count  NUMBER
, staging_table_row_count   NUMBER
, verification_passed       VARCHAR2(1) /* Y/N */
);

ALTER TABLE &&eadam_user..dba_hist_xtr_control_s ADD (verification_passed VARCHAR2(1));

/* ------------------------------------------------------------------------- */

-- only because i had to test patch more than once
UPDATE &&eadam_user..dba_hist_xtr_control_s SET verification_passed = NULL;
DELETE &&eadam_user..row_counts;

/* ------------------------------------------------------------------------- */

-- set row count for staging tables
DECLARE
  l_count NUMBER;
BEGIN
  FOR i IN (SELECT table_name
              FROM dba_tab_cols
             WHERE owner = UPPER('&&eadam_user.')
               AND table_name LIKE '%/_S' ESCAPE '/'
               AND column_name = 'EADAM_SEQ_ID'
               AND table_name NOT IN ('DBA_HIST_XTR_CONTROL_S') -- exclusion list
             ORDER BY
                   table_name)
  LOOP
    FOR j IN (SELECT eadam_seq_id FROM dba_hist_xtr_control_s WHERE verification_passed IS NULL ORDER BY eadam_seq_id)
    LOOP
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM &&eadam_user..'||i.table_name||' WHERE eadam_seq_id = :eadam_seq_id' INTO l_count USING IN j.eadam_seq_id;
      MERGE INTO &&eadam_user..row_counts r
      USING (SELECT j.eadam_seq_id eadam_seq_id, i.table_name table_name, l_count staging_table_row_count FROM dual) d 
      ON (r.eadam_seq_id = d.eadam_seq_id AND r.table_name = d.table_name)
      WHEN MATCHED THEN UPDATE SET r.staging_table_row_count = d.staging_table_row_count, r.verification_passed = 'Y'
      WHEN NOT MATCHED THEN INSERT (eadam_seq_id, table_name, staging_table_row_count, verification_passed) 
      VALUES (d.eadam_seq_id, d.table_name, d.staging_table_row_count, 'Y');
    END LOOP;
  END LOOP;
END;
/

-- tables with failed verification
SELECT eadam_seq_id, table_name, staging_table_row_count
  FROM &&eadam_user..row_counts
 WHERE NVL(verification_passed, 'N') != 'Y' 
 ORDER BY
       eadam_seq_id, table_name;

-- updates verification flag of tables from merged sets, then updates verification flag of loads/merges
DECLARE
  l_total NUMBER;
  l_passed NUMBER;
BEGIN
  FOR i IN (SELECT eadam_seq_id, eadam_seq_id_1, eadam_seq_id_2
              FROM &&eadam_user..dba_hist_xtr_control_s
             WHERE verification_passed IS NULL
             ORDER BY
                   eadam_seq_id)
  LOOP
    -- merged sets
    IF i.eadam_seq_id_1 IS NOT NULL AND i.eadam_seq_id_2 IS NOT NULL THEN
      FOR j IN (SELECT  m.table_name,
                        m.ROWID                    m_rowid,
                        m.staging_table_row_count  m_staging_table_row_count,
                        m.verification_passed      m_verification_passed,
                        s1.staging_table_row_count s1_staging_table_row_count,
                        s1.verification_passed     s1_verification_passed,
                        s2.staging_table_row_count s2_staging_table_row_count,
                        s2.verification_passed     s2_verification_passed
                   FROM &&eadam_user..row_counts m,
                        &&eadam_user..row_counts s1,
                        &&eadam_user..row_counts s2
                  WHERE m.eadam_seq_id     = i.eadam_seq_id
                    AND s1.eadam_seq_id(+) = i.eadam_seq_id_1
                    AND s1.table_name(+)   = m.table_name
                    AND s2.eadam_seq_id(+) = i.eadam_seq_id_2
                    AND s2.table_name(+)   = m.table_name
                  ORDER BY
                        m.table_name)
      LOOP
        IF j.m_verification_passed = 'Y' AND 
           j.s1_verification_passed = 'Y' AND 
           j.s2_verification_passed = 'Y' AND 
           j.m_staging_table_row_count BETWEEN GREATEST(j.s1_staging_table_row_count, j.s2_staging_table_row_count) AND (j.s1_staging_table_row_count + j.s2_staging_table_row_count)
        THEN -- count of rows for table on merged set matches subsets
          UPDATE &&eadam_user..row_counts SET verification_passed = 'Y' WHERE ROWID = j.m_rowid;
        ELSE
          UPDATE &&eadam_user..row_counts SET verification_passed = 'N' WHERE ROWID = j.m_rowid;
        END IF;    
      END LOOP;
    END IF;
    -- individual sets or merged ones
    SELECT COUNT(*), SUM(CASE verification_passed WHEN 'Y' THEN 1 ELSE 0 END) 
      INTO l_total, l_passed
      FROM &&eadam_user..row_counts
     WHERE eadam_seq_id = i.eadam_seq_id;
    IF l_total = l_passed 
    THEN -- all tables passed validation
      UPDATE &&eadam_user..dba_hist_xtr_control_s SET verification_passed = 'Y' WHERE eadam_seq_id = i.eadam_seq_id;
    ELSE
      UPDATE &&eadam_user..dba_hist_xtr_control_s SET verification_passed = 'N' WHERE eadam_seq_id = i.eadam_seq_id;
    END IF;    
  END LOOP;
END;
/

COMMIT;

-- tables with failed verification
SELECT eadam_seq_id, table_name, staging_table_row_count, verification_passed
  FROM &&eadam_user..row_counts
 WHERE NVL(verification_passed, 'N') != 'Y' 
 ORDER BY
       eadam_seq_id, table_name;

-- failed list
COL seq FOR 999;
COL source FOR A9;
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
  FROM &&eadam_user..dba_hist_xtr_control_s
 WHERE NVL(verification_passed, 'N') != 'Y' 
 ORDER BY 1;

-- failed merged tables
COL seq1 FOR 9999;
COL seq2 FOR 9999;
COL m_ver FOR A3;
COL s1_ver FOR A4;
COL s2_ver FOR A4;
SELECT m.eadam_seq_id seq,
       s1.eadam_seq_id seq1,
       s2.eadam_seq_id seq2,
       m.table_name,
       m.staging_table_row_count m_rows,
       s1.staging_table_row_count s1_rows,
       s2.staging_table_row_count s2_rows,
       m.verification_passed m_ver,
       s1.verification_passed s1_ver,
       s2.verification_passed s2_ver
  FROM &&eadam_user..dba_hist_xtr_control_s c,
       &&eadam_user..row_counts m,
       &&eadam_user..row_counts s1,
       &&eadam_user..row_counts s2
 WHERE NVL(c.verification_passed, 'N') != 'Y'
   AND m.eadam_seq_id = c.eadam_seq_id
   AND NVL(m.verification_passed, 'N') != 'Y'
   AND s1.eadam_seq_id = c.eadam_seq_id_1
   AND s1.table_name   = m.table_name
   AND s2.eadam_seq_id = c.eadam_seq_id_2
   AND s2.table_name   = m.table_name
 ORDER BY
       m.eadam_seq_id,
       m.table_name;

-- list
COL seq FOR 999;
COL source FOR A9;
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
  FROM &&eadam_user..dba_hist_xtr_control_s
 ORDER BY 1;

SPO OFF;