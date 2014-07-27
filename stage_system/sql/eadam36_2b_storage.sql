DEF section_name = 'Storage';
SPO &&main_report_name..html APP;
PRO <h2>&&section_name.</h2>
SPO OFF;

DEF title = 'Datafile';
DEF main_table = 'V_DATAFILE_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM v_datafile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 ORDER BY
       file#
';
END;
/
@@eadam36_9a_pre_one.sql

DEF title = 'Tempfile';
DEF main_table = 'V_TEMPFILE_S';
BEGIN
  :sql_text := '
SELECT /*+ &&top_level_hints. */
       *
  FROM v_tempfile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 ORDER BY
       file#
';
END;
/
@@eadam36_9a_pre_one.sql

DEF title = 'Database Growth per Month';
DEF main_table = 'V_DATAFILE_S';
BEGIN
  :sql_text := '
-- incarnation from health_check_4.4 (Jon Adams and Jack Agustin)
SELECT /*+ &&top_level_hints. */
       TO_CHAR(creation_time, ''YYYY-MM''),
       ROUND(SUM(bytes)/1024/1024) mb_growth,
       ROUND(SUM(bytes)/1024/1024/1024) gb_growth,
       ROUND(SUM(bytes)/1024/1024/1024/1024, 1) tb_growth
  FROM v_datafile_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 GROUP BY
       TO_CHAR(creation_time, ''YYYY-MM'')
 ORDER BY
       TO_CHAR(creation_time, ''YYYY-MM'')
';
END;
/
@@eadam36_9a_pre_one.sql
