-- Enkitec's AWR DAta Mining Tool (eAdam) 2014-07-12

Source System Steps:
~~~~~~~~~~~~~~~~~~~

-- extract awr data from source system
1) unzip eadam in source server directory and navigate to eadam/source_system directory
2) as SYS, run @eadam_extract.sql to extract and generate one big tar file

Notes:
1. tar file is large so place eadam script and execute extraction from directory > 10GB

*********************************************************

Stage System Steps:
~~~~~~~~~~~~~~~~~~~

-- install tool on staging system
1) unzip eadam in server and navigate to eadam/stage_system directory
2) as SYS, run @eadam_install.sql to create staging tables, libraries and views
 
-- load awr data from source into staging system
1) place tar into eadam/stage_system directory (the one that contains this readme.txt)
2) as SYS, run @eadam_load.sql to create external tables, staging tables and libraries

-- produce report (after loading awr data from tar file as described above)
1) navigate to eadam/stage_system directory (the one that contains this readme.txt)
2) as SYS or eadam user, run @eadam_report.sql to create zip with report

Notes:
1. load process automatically generates report

*********************************************************

Utilities:
~~~~~~~~~

-- delete a data set
1) as eadam user, run @utl/eadam_15_del.sql

-- truncate eadam repository
1) as eadam user, run @utl/eadam_16_tnk.sql

*********************************************************
