eadam v1701 (2017-02-23) by Carlos Sierra

eadam is a "free to use" tool to perform some data mining on AWR data extracted from
another system. For example, extract data from Production and do AWR data mining of
it on a Test or Remote system. 
It gives a glance of a database state. It also helps to document any findings.
eadam installs nothing on the source system. For better results execute as SYS or DBA.
It takes around one hour to execute. Output TAR file can be large (> 1 GB), 
so you may want to execute eadam from a system directory with at least 10 GBs of free 
space. Best time to execute eadam is close to the end of a working day.

Source System Steps:
~~~~~~~~~~~~~~~~~~~

-- extract awr, performance and some metadata from source system
1) unzip eadam-master in source server and navigate to eadam-master/source_system
2) as SYS or DBA, run @eadam_extract.sql to extract and generate one big TAR file

Notes:
1. TAR file is large so execute from directory with over 10 GBs
2. To execute eadam in all databases on host consider: sh run_eadam_master_*.sh

****************************************************************************************

Stage System Steps:
~~~~~~~~~~~~~~~~~~~

-- place tool on staging system
1) unzip eadam-master in server and navigate to eadam-master/stage_system directory
2) as SYS or DBA, run @eadam_install.sql to create eadam schema owner, staging tables, 
   libraries and views
 
-- load awr data from TAR source file into staging system
1) place TAR into eadam-master/stage_system directory
2) as SYS or DBA, run @eadam_load.sql to create external/staging tables and libraries

-- auto merge awr data from TAR source file into staging system
1) place TAR into eadam-master/stage_system directory
2) as SYS or DBA, run @eadam_automerge.sql to merge the content of new file.

-- purge sources of merged sets or those that failed verification
1) navigate to eadam-master/stage_system directory
2) as eadam user, run @eadam_autopurge.sql to purge collections no longer needed.

-- produce report (after loading awr data from TAR file as described above)
1) navigate to eadam-master/stage_system directory 
2) as eadam user, run @eadam_report.sql to create ZIP with report

****************************************************************************************

Utilities:
~~~~~~~~~

-- delete a data set
1) as eadam user, run @utl/eadam_15_del.sql

-- truncate eadam repository
1) as eadam user, run @utl/eadam_16_tnk.sql

****************************************************************************************

Notes:
~~~~~

1. If you need to execute only one piece of eadam report (i.e. resources) 
   use these 3 commands:

   SQL> @sql/eadam36_0b_pre.sql
   SQL> @sql/eadam36_1d_resources.sql
   SQL> @sql/eadam36_0c_post.sql

****************************************************************************************
   
    eadam - Enkitec's Oracle AWR Data Mining Tool
    Copyright (C) 2017  Carlos Sierra

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

****************************************************************************************
