-- Creates Libraries

SPO eadam_04_clb.txt;
SET ECHO ON FEED ON;

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
  FOR i IN (SELECT other_xml
              FROM dba_hist_sql_plan_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND row_num > l_row_num
               AND row_num < l_row_num + 1000 -- max OF 255,000 bytes are considered
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
  SELECT row_num, other_xml 
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
  FOR i IN (SELECT other_xml
              FROM gv_sql_plan_statistics_al_s
             WHERE eadam_seq_id = p_eadam_seq_id
               AND row_num > l_row_num
               AND row_num < l_row_num + 1000 -- max OF 255,000 bytes are considered
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

END eadam;
/

SHO ERRORS;

/* ------------------------------------------------------------------------- */

SET ECHO OFF FEED OFF;
SPO OFF;
