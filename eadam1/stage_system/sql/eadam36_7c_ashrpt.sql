SET VER OFF FEED OFF SERVEROUT ON HEAD OFF PAGES 50000 LIN 32767 TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100;
DEF section_name = 'ASH Reports';
SPO &&main_report_name..html APP;
PRO <h2 title="For largest 'DB time' or 'background elapsed time' for past 4 hours, 1 and 7 days (for each instance)">&&section_name.</h2>
SPO OFF;
