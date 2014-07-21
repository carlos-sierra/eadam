--@@eadam36_0b_pre.sql
DEF max_col_number = '7';
DEF column_number = '0';
SPO &&main_report_name..html APP;
PRO <table><tr>
PRO <td class="c">1/&&max_col_number.</td>
PRO <td class="c">2/&&max_col_number.</td>
PRO <td class="c">3/&&max_col_number.</td>
PRO <td class="c">4/&&max_col_number.</td>
PRO <td class="c">5/&&max_col_number.</td>
PRO <td class="c">6/&&max_col_number.</td>
PRO <td class="c">7/&&max_col_number.</td>
PRO </tr><tr><td>
PRO
SPO OFF;

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '1';

@@eadam36_1a_configuration.sql
@@eadam36_1b_security.sql
@@eadam36_1c_memory.sql
@@eadam36_1d_resources.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '2';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_2a_admin.sql
@@eadam36_2b_storage.sql
@@eadam36_2c_asm.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '3';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_3a_resource_mgm.sql
@@eadam36_3b_plan_stability.sql
@@eadam36_3c_cbo_stats.sql
@@eadam36_3d_performance.sql
@@eadam36_3e_os_stats.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '4';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_4a_sga_stats.sql
@@eadam36_4b_pga_stats.sql
@@eadam36_4c_mem_stats.sql
@@eadam36_4d_time_model.sql
@@&&skip_10g.eadam36_4e_io_waits.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '5';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_5a_ash.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '6';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_6a_ash_top.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEF column_number = '7';

SPO &&main_report_name..html APP;
PRO
PRO </td><td>
PRO
SPO OFF;

@@eadam36_7a_awrrpt.sql
@@eadam36_7b_addmrpt.sql
@@eadam36_7c_ashrpt.sql
@@eadam36_7d_sql_sample.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- log footer
SPO &&eadam36_log..txt APP;
PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
DEF;
PRO
PRO end log
SPO OFF;

-- main footer
SPO &&main_report_name..html APP;
PRO
PRO </td></tr></table>
SPO OFF;
@@eadam36_0c_post.sql