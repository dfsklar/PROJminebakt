for X in exports_02/*.data
do
    perl minefile.pl $X || exit
done

