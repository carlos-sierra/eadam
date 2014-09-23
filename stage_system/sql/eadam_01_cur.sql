-- Creates eAdam user and directory. Use this script on initial installation
-- parameters: default and temporary tablespaces for eAdam user, the user/pwd for it

SPO eadam_01_cur.txt;
SET ECHO ON FEED ON VER ON;

-- eadam/stage_system where TAR files are placed
DEF eadam_directory = 'EADAM_DIR';

CONN / AS SYSDBA;
 
SET TERM ON ECHO OFF;

-- displays existing tablespaces
WITH f AS (
        SELECT tablespace_name, NVL(ROUND(SUM(bytes)/1024/1024), 0) free_space_mb
          FROM (SELECT tablespace_name, SUM( bytes ) bytes 
		          FROM sys.dba_free_space 
				 GROUP BY tablespace_name
                UNION ALL
                SELECT tablespace_name, SUM( maxbytes - bytes ) bytes 
				  FROM sys.dba_data_files 
				 WHERE maxbytes - bytes > 0 
 				 GROUP BY tablespace_name )
         GROUP BY tablespace_name)
SELECT t.tablespace_name, f.free_space_mb
  FROM sys.dba_tablespaces t, f
WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name = f.tablespace_name
   AND f.free_space_mb > 50
ORDER BY f.free_space_mb;
PRO
PRO Parameter 1:
PRO DEFAULT_TABLESPACE:
PRO
DEF default_tablespace = '&1';
PRO
SELECT t.tablespace_name
  FROM sys.dba_tablespaces t
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND NOT EXISTS (
SELECT NULL
  FROM sys.dba_tablespace_groups tg
 WHERE t.tablespace_name = tg.tablespace_name )
 UNION
SELECT tg.group_name
  FROM sys.dba_tablespaces t,
       sys.dba_tablespace_groups tg
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND t.tablespace_name = tg.tablespace_name;
PRO
PRO Parameter 2:
PRO TEMPORARY_TABLESPACE:
PRO
DEF temporary_tablespace = '&2';
PRO
PRO Parameter 3:
PRO EADAM_USER:
PRO
DEF eadam_user = '&3';
PRO
PRO Parameter 4:
PRO EADAM_PWD:
PRO
DEF eadam_pwd = '&4';
PRO

SET ECHO ON;
GRANT DBA TO &&eadam_user. IDENTIFIED BY &&eadam_pwd.;
GRANT ANALYZE ANY TO &&eadam_user.;
ALTER USER &&eadam_user. DEFAULT TABLESPACE &&default_tablespace.;
ALTER USER &&eadam_user. QUOTA UNLIMITED ON &&default_tablespace.;
ALTER USER &&eadam_user. TEMPORARY TABLESPACE &&temporary_tablespace.;

HOS pwd
CREATE OR REPLACE DIRECTORY &&eadam_directory. AS '&&directory_path.';
GRANT read,write ON DIRECTORY &&eadam_directory. TO &&eadam_user.;

/* ------------------------------------------------------------------------- */

UNDEF 1 2 3 4
SET ECHO OFF FEED OFF;
SPO OFF;
