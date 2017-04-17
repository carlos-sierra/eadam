DEF section_name = 'Performance Summaries';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;


DEF title = 'SQL Monitor Recent Executions Detail';
DEF abstract = 'Aggregated by SQL_ID and SQL Execution. Sorted by SQL_ID and Execution Start Time.';
DEF main_table = 'GV_SQL_MONITOR_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       sql_id,
       sql_exec_start,
       sql_exec_id,
       NVL(MAX(px_qcinst_id), MAX(inst_id)) inst_id,
       MAX(sql_plan_hash_value) sql_plan_hash_value,
       MAX(username) username,
       MAX(service_name) service_name,
       MAX(module) module,
       MAX(px_is_cross_instance) px_is_cross_instance,
       MAX(px_maxdop) px_maxdop,
       MAX(px_maxdop_instances) px_maxdop_instances,
       MAX(px_servers_requested) px_servers_requested,
       MAX(px_servers_allocated) px_servers_allocated,
       MAX(error_number) error_number,
       MAX(error_facility) error_facility,
       MAX(error_message) error_message,
       COUNT(*) processes,
       1 executions,
       SUM(fetches) fetches,
       SUM(buffer_gets) buffer_gets,
       SUM(disk_reads) disk_reads,
       SUM(direct_writes) direct_writes,
       SUM(io_interconnect_bytes) io_interconnect_bytes,
       SUM(physical_read_requests) physical_read_requests,
       SUM(physical_read_bytes) physical_read_bytes,
       SUM(physical_write_requests) physical_write_requests,
       SUM(physical_write_bytes) physical_write_bytes,
       SUM(elapsed_time) elapsed_time,
       SUM(queuing_time) queuing_time,
       SUM(cpu_time) cpu_time,
       SUM(application_wait_time) application_wait_time,
       SUM(concurrency_wait_time) concurrency_wait_time,
       SUM(cluster_wait_time) cluster_wait_time,
       SUM(user_io_wait_time) user_io_wait_time,
       SUM(plsql_exec_time) plsql_exec_time,
       SUM(java_exec_time) java_exec_time,
       MAX(sql_text) sql_text
  FROM gv_sql_monitor_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND status LIKE ''DONE%''
 GROUP BY
       sql_id,
       sql_exec_start,
       sql_exec_id
HAVING MAX(sql_text) IS NOT NULL
 ORDER BY
       sql_id,
       sql_exec_start,
       sql_exec_id
';
END;
/
@@&&skip_tuning.&&skip_10g.&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'SQL Monitor Recent Executions Summary';
DEF abstract = 'Aggregated by SQL_ID and sorted by Total Elapsed Time.';
DEF main_table = 'GV_SQL_MONITOR_S';
BEGIN
  :sql_text := '
WITH
monitored_sql AS (
SELECT /*+ &&sq_fact_hints. */
       sql_id,
       sql_exec_start,
       sql_exec_id,
       NVL(MAX(px_qcinst_id), MAX(inst_id)) inst_id,
       MAX(sql_plan_hash_value) sql_plan_hash_value,
       MAX(username) username,
       MAX(service_name) service_name,
       MAX(module) module,
       MAX(px_is_cross_instance) px_is_cross_instance,
       MAX(px_maxdop) px_maxdop,
       MAX(px_maxdop_instances) px_maxdop_instances,
       MAX(px_servers_requested) px_servers_requested,
       MAX(px_servers_allocated) px_servers_allocated,
       MAX(error_number) error_number,
       MAX(error_facility) error_facility,
       MAX(error_message) error_message,
       COUNT(*) processes,
       1 executions,
       SUM(fetches) fetches,
       SUM(buffer_gets) buffer_gets,
       SUM(disk_reads) disk_reads,
       SUM(direct_writes) direct_writes,
       SUM(io_interconnect_bytes) io_interconnect_bytes,
       SUM(physical_read_requests) physical_read_requests,
       SUM(physical_read_bytes) physical_read_bytes,
       SUM(physical_write_requests) physical_write_requests,
       SUM(physical_write_bytes) physical_write_bytes,
       SUM(elapsed_time) elapsed_time,
       SUM(queuing_time) queuing_time,
       SUM(cpu_time) cpu_time,
       SUM(application_wait_time) application_wait_time,
       SUM(concurrency_wait_time) concurrency_wait_time,
       SUM(cluster_wait_time) cluster_wait_time,
       SUM(user_io_wait_time) user_io_wait_time,
       SUM(plsql_exec_time) plsql_exec_time,
       SUM(java_exec_time) java_exec_time,
       MAX(sql_text) sql_text
  FROM gv_sql_monitor_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND status LIKE ''DONE%''
 GROUP BY
       sql_id,
       sql_exec_start,
       sql_exec_id
HAVING MAX(sql_text) IS NOT NULL
)
SELECT /*+ &&top_level_hints. */
       sql_id,
       SUM(executions) executions,
       MIN(sql_exec_start) min_sql_exec_start,
       MAX(sql_exec_start) max_sql_exec_start,
       SUM(elapsed_time) sum_elapsed_time,
       ROUND(AVG(elapsed_time)) avg_elapsed_time,
       ROUND(MIN(elapsed_time)) min_elapsed_time,
       ROUND(MAX(elapsed_time)) max_elapsed_time,
       SUM(cpu_time) sum_cpu_time,
       ROUND(AVG(cpu_time)) avg_cpu_time,
       ROUND(MIN(cpu_time)) min_cpu_time,
       ROUND(MAX(cpu_time)) max_cpu_time,
       SUM(user_io_wait_time) sum_user_io_wait_time,
       ROUND(AVG(user_io_wait_time)) avg_user_io_wait_time,
       ROUND(MIN(user_io_wait_time)) min_user_io_wait_time,
       ROUND(MAX(user_io_wait_time)) max_user_io_wait_time,
       SUM(buffer_gets) sum_buffer_gets,
       ROUND(AVG(buffer_gets)) avg_buffer_gets,
       ROUND(MIN(buffer_gets)) min_buffer_gets,
       ROUND(MAX(buffer_gets)) max_buffer_gets,
       SUM(disk_reads) sum_disk_reads,
       ROUND(AVG(disk_reads)) avg_disk_reads,
       ROUND(MIN(disk_reads)) min_disk_reads,
       ROUND(MAX(disk_reads)) max_disk_reads,
       SUM(processes) sum_processes,
       ROUND(AVG(processes)) avg_processes,
       ROUND(MIN(processes)) min_processes,
       ROUND(MAX(processes)) max_processes,
       COUNT(DISTINCT inst_id) distinct_inst_id,
       MIN(inst_id) min_inst_id,
       MAX(inst_id) max_inst_id,
       COUNT(DISTINCT sql_plan_hash_value) distinct_sql_plan_hash_value,
       MIN(sql_plan_hash_value) min_sql_plan_hash_value,
       MAX(sql_plan_hash_value) max_sql_plan_hash_value,
       COUNT(DISTINCT username) distinct_username,
       MAX(username) max_username,
       COUNT(DISTINCT service_name) distinct_service_name,
       MAX(service_name) max_service_name,
       COUNT(DISTINCT module) distinct_module,
       MAX(module) max_module,
       MAX(px_is_cross_instance) max_px_is_cross_instance,
       MIN(px_is_cross_instance) min_px_is_cross_instance,
       MAX(px_maxdop) max_px_maxdop,
       MIN(px_maxdop) min_px_maxdop,
       MAX(px_maxdop_instances) max_px_maxdop_instances,
       MIN(px_maxdop_instances) min_px_maxdop_instances,
       MAX(px_servers_requested) max_px_servers_requested,
       MIN(px_servers_requested) min_px_servers_requested,
       MAX(px_servers_allocated) max_px_servers_allocated,
       MIN(px_servers_allocated) min_px_servers_allocated,
       MAX(error_number) max_error_number,
       MAX(error_facility) max_error_facility,
       MAX(error_message) max_error_message,
       MAX(sql_text) sql_text
  FROM monitored_sql
 GROUP BY
       sql_id
 ORDER BY
       sum_elapsed_time DESC,
       sql_id
';
END;
/
@@&&skip_tuning.&&skip_10g.&&skip_pt.eadam36_9a_pre_one.sql

DEF title = 'SQL Monitor Recent Executions DONE (ERROR)';
DEF abstract = 'Aggregated by SQL_ID and Error.';
DEF main_table = 'GV_SQL_MONITOR_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       sql_id,
       error_number,
       error_facility,
       error_message,
       COUNT(*) executions
  FROM gv_sql_monitor_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND status = ''DONE (ERROR)''
 GROUP BY
       sql_id,
       error_number,
       error_facility,
       error_message
HAVING MAX(sql_text) IS NOT NULL
 ORDER BY
       sql_id,
       error_number,
       error_facility,
       error_message
';
END;
/
@@&&skip_tuning.&&skip_10g.&&skip_pt.eadam36_9a_pre_one.sql




