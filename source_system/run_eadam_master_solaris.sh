# eAdam collector for linux (2017-02-23)
echo "Start eAdam collector."

export ORAENV_ASK=NO
 
ORATAB=/var/opt/oracle/oratab
 
db=`egrep -i ":Y|:N" $ORATAB | cut -d":" -f1 | grep -v "\#" | grep -v "\*"`
for i in $db ; do
       export ORACLE_SID=$i
       . oraenv

sqlplus -s /nolog <<EOF
connect / as sysdba
@eadam_extract.sql 100 PE
HOS zip -qm eadam_output.zip &&tar_filename..tar
EOF

done

echo "End eAdam collector. Output: eadam_output.zip"
