echo "SELECT Id FROM inventory WHERE qtyallwh>0 and Type='Book' and BOOLneedsDetailsDownload='Y' LIMIT 2000" \
   | sh mysql.sh --skip-column-names  > isbnlist_one_cycle.txt
sh minefiles.sh > $$.sql
sh mysql.sh < $$.sql   &&    mv $$.sql DONEALREADY
