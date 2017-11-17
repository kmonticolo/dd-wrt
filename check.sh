#!/bin/bash

mail="mail@gmail.com"
d=`date +%Y`
a=`cat ~/.ile`
b=`curl -s -o - ftp://ftp.dd-wrt.com/betas/$d/ | wc -l`
if ( [ $a -ne $b ] ); then {
  path=`curl -s -o - ftp://ftp.dd-wrt.com/betas/$d/|tail -1 |awk '{ print $9 }'`
  echo Check ftp://ftp.dd-wrt.com/betas/$d/$path/broadcom/dd-wrt.v24_std_generic.bin | mail -s DDWRT $mail
  echo $b > ~/.ile
}
fi
