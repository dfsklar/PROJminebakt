/bin/rm cookies.txt
/bin/rm login_result.png
/bin/rm /home/skldevbox/login_result.png

nice phantomjs --cookies-file=./cookies.txt loadloginpage_v2.js

cp login_result.png /home/skldevbox
