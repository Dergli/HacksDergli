#!/bin/bash
echo 1.- Español
echo 2.- English
read VAR
if [ "$VAR" = "1" ]; then
cp -R ./HacksDergli /home/
cp /home/HacksDergli/HacksDergli /usr/sbin/hacksdergli
chmod 755 -R /home/HacksDergli
chmod +x /usr/sbin/hacksdergli
elif [ "$VAR" = "2" ]; then
cp -R ./HacksDergli /home/
cp /home/HacksDergli/HacksDergliEnglish /usr/sbin/hacksdergli
chmod 755 -R /home/HacksDergli
chmod +x /usr/sbin/hacksdergli
fi
