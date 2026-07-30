#!/bin/bash



curl -o abp1.txt https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt
curl -o abp2.txt https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockfilters.txt
curl -o abp3.txt https://raw.githubusercontent.com/8680/GOODBYEADS/master/data/rules/adblock.txt
curl -o abp4.txt https://raw.githubusercontent.com/lingeringsound/adblock_auto/main/Rules/adblock_auto.txt
curl -o adg1.txt https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/main/rule/all.txt



# 预处理并合并所有源文件
sed -i -e '/^#[^#]/d' -e '/^####/d' -e '/^### /d' -e '/^$/d' adg1.txt 
cat adg1.txt abp*.txt | sed -e '/^!/d' -e '/^# /d' -e 's/^\s*//' -e 's/\s*$//' -e 's/\r//g' -e '/^$/d' | sort -u > adall.tmp

# 处理例外规则

grep '^@@' adall.tmp | sed 's/^@@//' > except.tmp
grep -v '^@@' adall.tmp | grep -v -F -f except.tmp > adall.tmp2

# 处理 hosts 格式并转换
grep -e '^0.0.0.0' -e '^127.0.0.1' adall.tmp2 | sed -e 's/^[0-9.]* //' -e 's/^/||/' -e 's/$/^/' > hosts.tmp
grep -v -e '^0.0.0.0' -e '^127.0.0.1' adall.tmp2 > adall.tmp3

# 合并所有规则
cat hosts.tmp adall.tmp3 | sort -u > tmp && mv tmp adall.txt

# 提取和过滤包含特殊字符的规则
awk '/^\|\|/ && !/[\/^$*]/' adall.txt > adall.tmp4
awk '!/^\|\|/ || /[\/^$*]/' adall.txt > tmp && mv tmp adall.txt
awk '!/^\|\|[0-9.]+$/ || split($0, a, ".") < 4' adall.tmp4 | sed 's/$/^/' > adall.tmp5

# 合并
cat adall.tmp5 adall.txt | sort -u > tmp && mv tmp adall.txt

# 处理 HTTP/HTTPS 规则
grep -e '^||https:' -e '^||http:' adall.txt > adall.tmp6
sed -i '/^||https:/d;/^||http:/d' adall.txt
sed -e 's/||https:\/\//||/' -e 's/||http:\/\//||/' -e '/#/d' adall.tmp6 | awk '!/[/$]/ { $0 = $0 "^" } 1' > adall.tmp7

# 合并
cat adall.txt adall.tmp7 | sort -u > tmp && mv tmp adall.txt

# 处理无效规则
cat adall.txt | \
  sed -E 's/^\|\|0\.0\.0\.0\./||/' | \
  sed -E 's/^\|\|127\.0\.0\.1\./||/' | \
  grep -v -E '^\|\|(0\.0\.0\.[0-9]+|127\.0\.0\.1|::1|\[::\]|localhost|localhost\.localdomain|ip6-localhost|ip6-loopback)\^' | \
  grep -v -E '^\|\|[^\^]*\s+[^\^]*\^' | \
  grep -v '^::1' | \
  sed -e 's/^\s*//' -e 's/\s*$//' | \
  grep -v '^$' | \
  sort -u > tmp && mv tmp adall.txt

grep -E '^\|\|[a-zA-Z0-9.-]+\^$' adall.txt > damain.txt

grep -v -E '^\|\|[a-zA-Z0-9.-]+\^$' adall.txt > modify.txt

# 清理临时文件
rm -f adg1.txt abp*.txt *.tmp* 






