for X in exports/*.data
do
    perl minefile.pl $X || exit
done

