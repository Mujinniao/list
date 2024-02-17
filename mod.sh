#!/bin/bash

curl -o adg1.txt https://raw.githubusercontent.com/ilpl/ad-hosts/master/hosts
curl -o adg2.txt https://raw.githubusercontent.com/ilpl/ad-hosts/master/filter.txt
curl -o adg3.txt https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
curl -o adg4.txt https://raw.githubusercontent.com/Goooler/1024_hosts/master/hosts
curl -o adg5.txt https://raw.githubusercontent.com/francis-zhao/quarklist/master/dist/hosts
curl -o abp1.txt https://raw.githubusercontent.com/easylist/easylistchina/master/easylistchina.txt
curl -o abp2.txt https://raw.githubusercontent.com/uniartisan/adblock_list/master/adblock_plus.txt
curl -o abp3.txt https://raw.githubusercontent.com/francis-zhao/quarklist/master/dist/quarklist.txt
curl -o abp4.txt https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt
curl -o abp5.txt https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-ublock.txt
curl -o abp6.txt https://raw.githubusercontent.com/Noyllopa/NoAppDownload/master/NoAppDownload.txt
curl -o abp7.txt https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt
curl -o abp8.txt https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/rule.txt
curl -o abp9.txt https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt
curl -o abp10.txt https://raw.githubusercontent.com/damengzhu/banad/main/jiekouAD.txt
curl -o abp11.txt https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt
curl -o abp12.txt https://raw.githubusercontent.com/durablenapkin/scamblocklist/master/adguard.txt
curl -o abp13.txt https://raw.githubusercontent.com/Spam404/lists/master/adblock-list.txt


cat adg*.txt | sort -u | sed '/^#/d' > adgm.txt

cat abp*.txt | sort -u | sed -e '/^\[/d' -e '/^!/d' > abpm.txt  

cat adgm.txt abpm.txt | sort -u > adall.txt

grep '^@@' adall.txt > white.txt && sed -i '/^@@/d' adall.txt

sed -i -e 's/\$important$//' -e 's/^@@//' white.txt

sort adall.txt -o adall.txt

sort white.txt -o white.txt

comm -23 adall.txt white.txt > temp.txt && mv temp.txt adall.txt

grep -e '^||' -e '^0.0.0.0' -e '^127.0.0.1' adall.txt > domain.txt

sed -i -e '/\//d' -e '/\$popup/d' -e '/\$third-party/d' -e '/\$domain/d' -e '/\$redirect/d' -e '/\$script/d' -e '/\$~image/d' -e '/,third-party/d' -e '/\$image/d' -e '/\^\*/d' -e '/\$csp/d' -e '/\$media/d' -e '/\$removeheader/d' -e '/\$subdocument/d' -e '/\$object/d' -e '/\$xhr/d' -e '/\$cookie/d' -e '/\$all/d' -e '/\$xmlhttprequest/d' -e '/\$document/d' -e '/domain=/d' -e '/\$~stylesheet/d' -e '/\$removeparam/d' -e '/\$websocket/d' -e '/\$~third-party/d' -e '/\$inline-script/d' domain.txt

sort adall.txt -o adall.txt

sort domain.txt -o domain.txt

comm -23 adall.txt domain.txt > modify.txt

rm adg*.txt abp*.txt white.txt



#grep -vf white.txt adall.txt > temp.txt && mv temp.txt adall.txt
#grep -vf domain.txt adall.txt > modify.txt









