echo "SELECT Id FROM inventory WHERE qtyallwh>0 and Type='Book' and BOOLneedsDetailsDownload='Y' LIMIT 2000" \
     | sh mysql.sh --skip-column-names  > isbnlist_one_cycle.txt
phantomjs --cookies-file=./cookies.txt query_isbn_list.js
echo "" > $$.sql
for X in exports/*.data
do
    perl minefile.pl $X >> $$.sql || exit
done
for X in exports/*.zero
do
    perl minezero.pl $X >> $$.sql || exit
done
echo DOC1
sh mysql.sh < $$.sql   &&   mv $$.sql DONEALREADY   &&  mv exports DONEALREADY/exports_$$
echo DOC2
mkdir exports

