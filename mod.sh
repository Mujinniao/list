#!/bin/bash


curl -o abp1.txt https://raw.githubusercontent.com/easylist/easylist/gh-pages/easylist.txt
curl -o abp2.txt https://raw.githubusercontent.com/easylist/easylist/gh-pages/easyprivacy.txt
curl -o abp3.txt https://raw.githubusercontent.com/easylist/easylistchina/master/easylistchina.txt
curl -o abp4.txt https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt
curl -o abp5.txt https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-ublock.txt
curl -o abp6.txt https://raw.githubusercontent.com/Noyllopa/NoAppDownload/master/NoAppDownload.txt
curl -o abp7.txt https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt
curl -o abp8.txt https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/rule.txt
curl -o abp9.txt https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt
curl -o abp10.txt https://raw.githubusercontent.com/damengzhu/banad/main/jiekouAD.txt
# curl -o abp11.txt https://raw.githubusercontent.com/uBlockOrigin/uAssets/gh-pages/filters/filters.min.txt
# curl -o abp12.txt https://raw.githubusercontent.com/uBlockOrigin/uAssets/gh-pages/filters/privacy.min.txt
# curl -o abp13.txt https://raw.githubusercontent.com/uBlockOrigin/uAssets/gh-pages/filters/badware.txt
# curl -o abp14.txt https://raw.githubusercontent.com/uBlockOrigin/uAssets/gh-pages/filters/quick-fixes.txt
# curl -o abp15.txt https://raw.githubusercontent.com/uBlockOrigin/uAssets/gh-pages/filters/unbreak.txt
curl -o abp16.txt https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt
curl -o abp17.txt https://raw.githubusercontent.com/durablenapkin/scamblocklist/master/adguard.txt
curl -o abp18.txt https://raw.githubusercontent.com/Spam404/lists/master/adblock-list.txt
# curl -o abp19.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers.txt
# curl -o abp20.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers_firstparty.txt
# curl -o abp21.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/foreign.txt
# curl -o abp22.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/MobileFilter/sections/adservers.txt
# curl -o abp23.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/adservers.txt
# curl -o abp24.txt https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/adservers_firstparty.txt

curl -o adg1.txt https://raw.githubusercontent.com/ilpl/ad-hosts/master/hosts
curl -o adg2.txt https://raw.githubusercontent.com/ilpl/ad-hosts/master/filter.txt
curl -o adg3.txt https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/ublock-dynamic-rule.txt


#curl -o adg3.txt https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
#curl -o adg4.txt https://raw.githubusercontent.com/Goooler/1024_hosts/master/hosts
#curl -o adg5.txt https://raw.githubusercontent.com/francis-zhao/quarklist/master/dist/hosts
#curl -o abp2.txt https://raw.githubusercontent.com/uniartisan/adblock_list/master/adblock_plus.txt
#curl -o abp3.txt https://raw.githubusercontent.com/francis-zhao/quarklist/master/dist/quarklist.txt







cat adg*.txt | sort -u | sed -e 's/#.*//' -e '/^$/d' > adgm.txt

cat abp*.txt | sort -u | sed -e '/^\[/d' -e '/^!/d' -e '/^$/d' > abpm.txt  

cat adgm.txt abpm.txt | sort -u > adall.txt

grep '^@@' adall.txt > white.txt && sed -i -e '/^@@/d' -e '/^$/d' adall.txt

sed -i -e 's/\$important$//' -e 's/^@@//' -e 's/^||/|/' -e 's/^|/||/' white.txt

# sort adall.txt -o adall.txt

# sort white.txt -o white.txt

grep -v -F -f white.txt adall.txt > temp.txt && mv temp.txt adall.txt

# comm -23 adall.txt white.txt > temp.txt && mv temp.txt adall.txt

grep -e '^||' -e '^0.0.0.0' -e '^127.0.0.1' adall.txt > domain.txt

sed -i -e '/\//d' -e '/\$popup/d' -e '/\$third-party/d' -e '/\$domain/d' -e '/\$redirect/d' -e '/\$script/d' -e '/\$~image/d' -e '/,third-party/d' -e '/\$image/d' -e '/\^\*/d' -e '/\$csp/d' -e '/\$media/d' -e '/\$removeheader/d' -e '/\$subdocument/d' -e '/\$object/d' -e '/\$xhr/d' -e '/\$cookie/d' -e '/\$all/d' -e '/\$xmlhttprequest/d' -e '/\$document/d' -e '/domain=/d' -e '/\$~stylesheet/d' -e '/\$removeparam/d' -e '/\$websocket/d' -e '/\$~third-party/d' -e '/\$inline-script/d' -e '/\$app/d' -e '/\$header/d' -e '/\$match-case/d' -e '/\$method/d' -e '/\$to/d' -e '/^$/d' domain.txt

sort adall.txt -o adall.txt

sort domain.txt -o domain.txt

comm -23 adall.txt domain.txt > modify.txt

rm adg*.txt abp*.txt white.txt

cat ./extra/add.txt >> domain.txt

sed -e '/\*/d' -e 's/0.0.0.0 //' -e 's/127.0.0.1 //' -e 's/||//' -e 's/\^.*//' -e 's/^/domain:/' domain.txt > mos.txt







