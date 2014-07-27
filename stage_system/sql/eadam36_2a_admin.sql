DEF section_name = 'Database Administration';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF title = 'REDO LOG';
DEF main_table = 'GV_LOG_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
     *
  FROM gv_log_s
 WHERE eadam_seq_id = &&eadam_seq_id.    
 ORDER BY 1, 2, 3, 4, 5, 6, 7
';
END;
/
@@eadam36_9a_pre_one.sql

DEF title = 'SQL using Literals or many children (by COUNT)';
DEF main_table = 'GV_SQL_S';
COL force_matching_signature FOR 99999999999999999999;
BEGIN
  :sql_text := '
WITH
lit AS (
SELECT /*+ &&sq_fact_hints. */
       force_matching_signature, COUNT(*) cnt, MIN(sql_id) min_sql_id, MAX(SQL_ID) max_sql_id
  FROM gv_sql_s
 WHERE eadam_seq_id = &&eadam_seq_id.   
   AND force_matching_signature > 0
 GROUP BY
       force_matching_signature
HAVING COUNT(*) > 49
)
SELECT /*+ &&top_level_hints. */ 
       DISTINCT lit.cnt, s.force_matching_signature, s.parsing_schema_name owner,
       s.program_id, s.program_line#,
       SUBSTR(s.sql_text, 1, 200) sql_text
  FROM lit, gv_sql_s s
 WHERE s.eadam_seq_id = &&eadam_seq_id.   
   AND s.force_matching_signature = lit.force_matching_signature
   AND s.sql_id = lit.min_sql_id
 ORDER BY 
       1 DESC, 2
';
END;
/
@@&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'SQL using Literals or many children (by OWNER)';
DEF main_table = 'GV_SQL_S';
COL force_matching_signature FOR 99999999999999999999;
BEGIN
  :sql_text := '
WITH
lit AS (
SELECT /*+ &&sq_fact_hints. */
       force_matching_signature, COUNT(*) cnt, MIN(sql_id) min_sql_id, MAX(SQL_ID) max_sql_id
  FROM gv_sql_s
 WHERE eadam_seq_id = &&eadam_seq_id.   
   AND force_matching_signature > 0
 GROUP BY
       force_matching_signature
HAVING COUNT(*) > 49
)
SELECT /*+ &&top_level_hints. */ 
       DISTINCT s.parsing_schema_name owner, lit.cnt, s.force_matching_signature,
       s.program_id, s.program_line#,
       SUBSTR(s.sql_text, 1, 200) sql_text
  FROM lit, gv_sql_s s
 WHERE s.eadam_seq_id = &&eadam_seq_id.   
   AND s.force_matching_signature = lit.force_matching_signature
   AND s.sql_id = lit.min_sql_id
 ORDER BY 
       1, 2 DESC, 3
';
END;
/
@@&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'High Cursor Count';
DEF main_table = 'GV_SQL_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */ 
       v1.sql_id,
       COUNT(*) child_cursors,
       MIN(inst_id) min_inst_id,
       MAX(inst_id) max_inst_id,
       MIN(child_number) min_child,
       MAX(child_number) max_child,
       (SELECT v2.sql_text FROM gv_sql_s v2 WHERE v2.eadam_seq_id = &&eadam_seq_id. AND v2.sql_id = v1.sql_id AND ROWNUM = 1) sql_text
  FROM gv_sql_s v1
 WHERE v1.eadam_seq_id = &&eadam_seq_id.   
 GROUP BY
       v1.sql_id
HAVING COUNT(*) > 49
 ORDER BY
       child_cursors DESC,
       v1.sql_id
';
END;
/
@@&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'Top SQL by Buffer Gets consolidating duplicates';
DEF main_table = 'GV_SQL_S';
COL total_buffer_gets NEW_V total_buffer_gets;
COL total_disk_reads NEW_V total_disk_reads;
SELECT SUM(buffer_gets) total_buffer_gets, SUM(disk_reads) total_disk_reads FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id.;
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */ 
   FORCE_MATCHING_SIGNATURE,
   duplicate_count,
   executions,
   buffer_gets,
   buffer_gets_per_exec,
   disk_reads,
   disk_reads_per_exec,
   rows_processed,
   rows_processed_per_exec,
   elapsed_seconds,
   elapsed_seconds_per_exec,
   pct_total_buffer_gets,
   pct_total_disk_reads,
   (SELECT v2.sql_text FROM gv_sql_s v2 WHERE v2.eadam_seq_id = &&eadam_seq_id. AND v2.force_matching_signature = v1.force_matching_signature AND ROWNUM = 1) sql_text
from
  (select
      FORCE_MATCHING_SIGNATURE,
      count(*) duplicate_count,
      sum(executions) executions,
      sum(buffer_gets) buffer_gets,
      ROUND(sum(buffer_gets)/greatest(sum(executions),1)) buffer_gets_per_exec,
      sum(disk_reads) disk_reads,
      ROUND(sum(disk_reads)/greatest(sum(executions),1)) disk_reads_per_exec,
      sum(rows_processed) rows_processed,
      ROUND(sum(rows_processed)/greatest(sum(executions),1)) rows_processed_per_exec,
      round(sum(elapsed_time)/1000000, 3) elapsed_seconds,
      ROUND(sum(elapsed_time)/1000000/greatest(sum(executions),1), 3) elapsed_seconds_per_exec,
      ROUND(sum(buffer_gets)*100/&&total_buffer_gets., 1) pct_total_buffer_gets,
      ROUND(sum(disk_reads)*100/&&total_disk_reads., 1) pct_total_disk_reads,
      rank() over (order by sum(buffer_gets) desc nulls last) AS sql_rank
   from
      gv_sql_s
   where
      eadam_seq_id = &&eadam_seq_id. and
      FORCE_MATCHING_SIGNATURE <> 0 and 
      FORCE_MATCHING_SIGNATURE <> EXACT_MATCHING_SIGNATURE 
   group by
      FORCE_MATCHING_SIGNATURE
   having
      count(*) >= 30
   order by
      buffer_gets desc
  ) v1
where
   sql_rank < 31
';
END;
/
@@&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'Top SQL by number of duplicates';
DEF main_table = 'GV_SQL_S';
COL total_buffer_gets NEW_V total_buffer_gets;
COL total_disk_reads NEW_V total_disk_reads;
SELECT SUM(buffer_gets) total_buffer_gets, SUM(disk_reads) total_disk_reads FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id.;
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */ 
   FORCE_MATCHING_SIGNATURE,
   duplicate_count,
   executions,
   buffer_gets,
   buffer_gets_per_exec,
   disk_reads,
   disk_reads_per_exec,
   rows_processed,
   rows_processed_per_exec,
   elapsed_seconds,
   elapsed_seconds_per_exec,
   pct_total_buffer_gets,
   pct_total_disk_reads,
   (SELECT v2.sql_text FROM gv_sql_s v2 WHERE v2.eadam_seq_id = &&eadam_seq_id. AND v2.force_matching_signature = v1.force_matching_signature AND ROWNUM = 1) sql_text
from
  (select
      FORCE_MATCHING_SIGNATURE,
      count(*) duplicate_count,
      sum(executions) executions,
      sum(buffer_gets) buffer_gets,
      ROUND(sum(buffer_gets)/greatest(sum(executions),1)) buffer_gets_per_exec,
      sum(disk_reads) disk_reads,
      ROUND(sum(disk_reads)/greatest(sum(executions),1)) disk_reads_per_exec,
      sum(rows_processed) rows_processed,
      ROUND(sum(rows_processed)/greatest(sum(executions),1)) rows_processed_per_exec,
      round(sum(elapsed_time)/1000000, 3) elapsed_seconds,
      ROUND(sum(elapsed_time)/1000000/greatest(sum(executions),1), 3) elapsed_seconds_per_exec,
      ROUND(sum(buffer_gets)*100/&&total_buffer_gets., 1) pct_total_buffer_gets,
      ROUND(sum(disk_reads)*100/&&total_disk_reads., 1) pct_total_disk_reads,
      rank() over (order by count(*) desc nulls last) AS sql_rank
   from
      gv_sql_s
   where
      eadam_seq_id = &&eadam_seq_id. and
      FORCE_MATCHING_SIGNATURE <> 0 and 
      FORCE_MATCHING_SIGNATURE <> EXACT_MATCHING_SIGNATURE 
   group by
      FORCE_MATCHING_SIGNATURE
   order by
      count(*) desc
  ) v1
where
   sql_rank < 31
';
END;
/
@@&&skip_pt.eadam36_9a_pre_one.sql
