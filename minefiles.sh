for X in exports_03/*.data
do
    perl minefile.pl $X || exit
done

