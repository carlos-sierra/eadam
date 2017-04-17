DEF files_prefix = '';
SET VER OFF FEED OFF SERVEROUT ON HEAD OFF PAGES 50000 LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100;
DEF section_name = 'SQL Sample';
SPO &&main_report_name..html APP;
PRO <h2 title="Top SQL according to ASH&&between_dates.">&&section_name.</h2>
SPO OFF;

COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;
SPO 9997_&&common_prefix._top_sql_driver.sql;
DECLARE
  l_count NUMBER := 0;
  l_sql_text_clob CLOB;
  l_sql_text_2000 VARCHAR2(2000);
  PROCEDURE put_line(p_line IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
  PROCEDURE update_log(p_module IN VARCHAR2) IS
  BEGIN
        put_line('COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;');
		put_line('SELECT TO_CHAR(SYSDATE, ''HH24:MI:SS'') hh_mm_ss FROM DUAL;');
		put_line('-- update log');
		put_line('SPO &&eadam36_log..txt APP;');
		put_line('PRO '||CHR(38)||chr(38)||'hh_mm_ss. '||p_module);
		put_line('SPO OFF;');
  END update_log;
BEGIN
  FOR i IN (SELECT sql_id, times_on_top, samples
			  FROM (
			SELECT sql_id, 
				   COUNT(*) times_on_top, 
				   SUM(samples) samples
			  FROM (
			SELECT sql_id, samples
			  FROM (
			SELECT sql_id,
				   COUNT(*) samples
			  FROM gv_active_session_history_s
			 WHERE eadam_seq_id = &&eadam_seq_id.
			   AND CAST(sample_time AS DATE) BETWEEN TO_DATE('&&begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60)
			   AND sql_id IS NOT NULL
			 GROUP BY
				   sql_id
			 ORDER BY
				   2 DESC
			)
			 WHERE ROWNUM < 17
			 UNION ALL
			SELECT sql_id, samples
			  FROM (
			SELECT ash.sql_id,
				   COUNT(*) samples
			  FROM dba_hist_active_sess_hist_s ash,
				   dba_hist_snapshot_s snp
			 WHERE ash.eadam_seq_id = &&eadam_seq_id.
               AND ash.dbid = &&eadam_dbid.
			   AND ash.snap_id BETWEEN &&minimum_snap_id. AND &&maximum_snap_id.
			   AND CAST(ash.sample_time AS DATE) BETWEEN TO_DATE('&&begin_date.','YYYY-MM-DD/HH24:MI') AND TO_DATE('&&end_date.','YYYY-MM-DD/HH24:MI') + (1/24/60)
			   AND ash.sql_id IS NOT NULL
			   AND snp.eadam_seq_id = &&eadam_seq_id.
               AND snp.dbid = &&eadam_dbid.
			   AND snp.snap_id = ash.snap_id
			   AND snp.dbid = ash.dbid
			   AND snp.instance_number = ash.instance_number
			 GROUP BY 
				   ash.sql_id
			 ORDER BY
				   2 DESC
			)
			 WHERE ROWNUM < 17
			)
			 GROUP BY
				   sql_id
			 ORDER BY
				   times_on_top * samples DESC
			)
			WHERE ROWNUM < 17)
  LOOP
    l_count := l_count + 1;
    l_sql_text_clob := NULL;
    BEGIN
      SELECT sql_fulltext INTO l_sql_text_clob FROM gv_sql_s WHERE eadam_seq_id = &&eadam_seq_id. AND sql_id = i.sql_id AND ROWNUM = 1;    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_sql_text_clob := NULL;
    END;
    BEGIN
      IF l_sql_text_clob IS NULL THEN
        SELECT sql_text INTO l_sql_text_clob FROM dba_hist_sqltext_s WHERE eadam_seq_id = &&eadam_seq_id. AND dbid = &&eadam_dbid. AND sql_id = i.sql_id AND ROWNUM = 1;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_sql_text_clob := NULL;
    END;
    IF l_sql_text_clob IS NOT NULL THEN
      l_sql_text_2000 := DBMS_LOB.substr(l_sql_text_clob, 2000);
    END IF;
    put_line('COL hh_mm_ss NEW_V hh_mm_ss NOPRI FOR A8;');
    put_line('SELECT TO_CHAR(SYSDATE, ''HH24:MI:SS'') hh_mm_ss FROM DUAL;');
    put_line('-- update log');
    put_line('SPO &&eadam36_log..txt APP;');
    put_line('PRO');
    put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    put_line('PRO');
    put_line('PRO rank:'||l_count||' sql_id:'||i.sql_id);
    put_line('SPO OFF;');
    put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&eadam36_log..txt');
    put_line('-- update main report');
    put_line('SPO &&main_report_name..html APP;');
    put_line('PRO <li title="'||l_sql_text_2000||'">'||i.sql_id);
    put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
    put_line('SPO OFF;');
    IF l_count <= 16 THEN
      update_log('PLANX1');
      put_line('@@sql/eadam36_planx.sql &&eadam_seq_id. &&begin_date. &&end_date. '||i.sql_id);
      put_line('-- update main report');
      put_line('SPO &&main_report_name..html APP;');
      put_line('PRO <a title="between &&begin_date. and &&end_date." href="planx_'||i.sql_id||'_'||CHR(38)||chr(38)||'current_time..txt">planx1(text)</a>');
      put_line('SPO OFF;');
      put_line('-- zip');
      put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. planx_'||i.sql_id||'_'||CHR(38)||chr(38)||'current_time..txt');
      put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
    END IF;
    IF l_count <= 16 AND '&&begin_date.' != '&&min_date.' AND '&&end_date.' != '&&max_date.' THEN
      update_log('PLANX2');
      put_line('@@sql/eadam36_planx.sql &&eadam_seq_id. &&min_date. &&max_date. '||i.sql_id);
      put_line('-- update main report');
      put_line('SPO &&main_report_name..html APP;');
      put_line('PRO <a title="between &&min_date. and &&max_date." href="planx_'||i.sql_id||'_'||CHR(38)||chr(38)||'current_time..txt">planx2(text)</a>');
      put_line('SPO OFF;');
      put_line('-- zip');
      put_line('HOS zip -mq &&main_compressed_filename._&&file_creation_time. planx_'||i.sql_id||'_'||CHR(38)||chr(38)||'current_time..txt');
      put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
    END IF;
    put_line('-- update main report');
    put_line('SPO &&main_report_name..html APP;');
    put_line('PRO </li>');
    put_line('SPO OFF;');
    put_line('HOS zip -q &&main_compressed_filename._&&file_creation_time. &&main_report_name..html');
  END LOOP;
END;
/
SPO OFF;
CL COL;
@9997_&&common_prefix._top_sql_driver.sql;
SET SERVEROUT OFF HEAD ON PAGES 50;
HOS zip -mq &&main_compressed_filename._&&file_creation_time. 9997_&&common_prefix._top_sql_driver.sql
SET HEA ON LIN 32767 NEWP NONE PAGES 50 LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
CL COL;
COL row_number FOR 9999999 HEA '#' PRI;
COL eadam_seq_id_src NOPRI;
COL row_num NOPRI;
COL eadam_seq_id_1 NOPRI;
COL eadam_seq_id_2 NOPRI;


