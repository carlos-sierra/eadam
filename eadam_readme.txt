There are 3 versions of eadam. Versions 2 and 3 are designed to work in conjunction with
edb360, but they can be used stand-alone.

1. eadam1

   This is the original eadam, which extracts around 30 DBA_HIST, DBA, GV$ and V$ views
   as text files from a source system. This extracted files can be imported into a target
   database for further analysis. Please refer to eadam1/eadam1_readme.txt

2. eadam2

   Version 2.0 is similar to version 1.0, but instead of 30 views it extracts 219. It is
   based on text files. It looses some data from CLOB and XMLTYPE columns. Please refer to 
   eadam2/eadam2_readme.txt

3. eadam3

   Version 3.0 is similar to version 2.0, but instead of using text files it implements
   external tables, making it faster and consuming less disk space. No data is lost.
   Please refer to eadam3/eadam3_readme.txt

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
