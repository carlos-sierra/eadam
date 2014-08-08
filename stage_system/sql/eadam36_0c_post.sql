SPO &&main_report_name..html APP;
@@eadam36_0e_html_footer.sql
SPO OFF;

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- turing trace off
ALTER SESSION SET SQL_TRACE = FALSE;

-- get udump directory path
COL eadam36_udump_path NEW_V eadam36_udump_path FOR A500;
SELECT value||DECODE(INSTR(value, '/'), 0, '\', '/') eadam36_udump_path FROM v$parameter2 WHERE name = 'user_dump_dest';

-- get pid
COL eadam36_spid NEW_V eadam36_spid FOR A5;
SELECT TO_CHAR(spid) eadam36_spid FROM v$session s, v$process p WHERE s.sid = SYS_CONTEXT('USERENV', 'SID') AND p.addr = s.paddr;

-- tkprof for trace from execution of tool in case someone reports slow performance in tool
HOS tkprof &&eadam36_udump_path.*ora_&&eadam36_spid._&&eadam36_tracefile_identifier..trc &&eadam36_tkprof._sort.txt sort=prsela exeela fchela

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- readme
SPO 0000_readme_first.txt
PRO 1. Unzip &&main_compressed_filename._&&file_creation_time..zip into a directory
PRO 2. Review &&main_report_name..html
SPO OFF;

-- cleanup
SET HEA ON LIN 80 NEWP 1 PAGES 14 long 80 LONGC 80 WRA ON TRIMS OFF TRIM OFF TI OFF TIMI OFF ARRAY 15 NUM 10 NUMF "" SQLBL OFF BLO ON RECSEP WR;
UNDEF 1 2 3 4 5 6

-- zip 
HOS zip -mq &&main_compressed_filename._&&file_creation_time. &&common_prefix._query.sql
HOS zip -dq &&main_compressed_filename._&&file_creation_time. &&common_prefix._query.sql
HOS zip -mq &&main_compressed_filename._&&file_creation_time. &&eadam36_log2..txt
HOS zip -mq &&main_compressed_filename._&&file_creation_time. &&eadam36_tkprof._sort.txt
HOS zip -mq &&main_compressed_filename._&&file_creation_time. &&eadam36_log..txt
HOS zip -mq &&main_compressed_filename._&&file_creation_time. &&main_report_name..html
HOS zip -mq &&main_compressed_filename._&&file_creation_time. 0000_readme_first.txt 
HOS unzip -l &&main_compressed_filename._&&file_creation_time.
SET TERM ON;