#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }

#####################
# 1. 下载源
#####################
sources=(
  "abp1.txt|https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt"
  "abp2.txt|https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockfilters.txt"
  "abp3.txt|https://raw.githubusercontent.com/8680/GOODBYEADS/master/data/rules/adblock.txt"
  "abp4.txt|https://raw.githubusercontent.com/lingeringsound/adblock_auto/main/Rules/adblock_auto.txt"
  "adg1.txt|https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/main/rule/all.txt"
)

download() {
  local out="$1" url="$2" n
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 300 -o "$WORKDIR/$out" "$url"
  n=$(wc -l < "$WORKDIR/$out")
  if [ "$n" -lt 100 ]; then
    log "FAIL: $out 仅 $n 行 (<100)，中止"
    return 1
  fi
  log "downloaded $out: $n lines"
}

for entry in "${sources[@]}"; do
  download "${entry%%|*}" "${entry#*|}"
done

#####################
# 2. 归一化（单遍 awk）
#####################
{
  for entry in "${sources[@]}"; do
    cat "$WORKDIR/${entry%%|*}"
  done
  if [ -f extra/add.txt ]; then
    cat extra/add.txt
  fi
} | awk '
function find_anchor(s,   i, c, L) {
  L = length(s)
  for (i = 1; i <= L; i++) {
    c = substr(s, i, 1)
    if (c == "^" || c == "$" || c == "/" || c == "|") return i
  }
  return 0
}
BEGIN { bom = sprintf("%c%c%c", 239, 187, 191) }
{
  line = $0
  if (substr(line, 1, 3) == bom) line = substr(line, 4)
  gsub(/\r/, "", line)
  sub(/^[ \t]+/, "", line)
  sub(/[ \t]+$/, "", line)
  if (line == "") { blank++; next }

  # 注释分类：先 trim 再分类
  c1 = substr(line, 1, 1)
  if (c1 == "!") { comment++; next }
  if (c1 == "#") {
    c2 = substr(line, 2, 1)
    if (c2 == "" || index("#@$?^%", c2) == 0) { comment++; next }
  }
  # 头部声明行 [Adblock Plus 2.0]（] 后有内容的扩展化妆规则不受影响）
  if (line ~ /^\[[^][]*\]$/) { header++; next }

  # 网络规则尾随注释：仅 ||/@@|| 规则
  if (line ~ /^@@?\|\|/) {
    if (sub(/[ \t]+#.*$/, "", line)) { trailc++; sub(/[ \t]+$/, "", line) }
  }

  # hosts 转换：先剥行内注释，每个域名各出一条
  if (line ~ /^(0\.0\.0\.0|127\.0\.0\.1|::1?|::)([ \t]|$)/) {
    sub(/#.*/, "", line)
    nf = split(line, hf, /[ \t]+/)
    got = 0
    for (hi = 2; hi <= nf; hi++) {
      if (hf[hi] == "") continue
      hd = tolower(hf[hi])
      sub(/\.$/, "", hd)
      if (hd == "") continue
      print "||" hd "^"
      got = 1
    }
    if (!got) hostsjunk++
    next
  }
  # 孤立 IPv6 垃圾行
  if (line ~ /^::/) { hostsjunk++; next }

  # ||http(s):// 前缀剥离
  if (line ~ /^\|\|https?:\/\//) {
    sub(/^\|\|https?:\/\//, "||", line)
    if (index(line, "#")) { httpskip++; next }
    if (line !~ /[\^\/$]/) line = line "^"
  }

  # ||0.0.0.0. / ||127.0.0.1. 前缀剥离
  if (line ~ /^\|\|0\.0\.0\.0\./) sub(/^\|\|0\.0\.0\.0\./, "||", line)
  if (line ~ /^\|\|127\.0\.0\.1\./) sub(/^\|\|127\.0\.0\.1\./, "||", line)

  # 锚点处理（|| 与 @@||）
  if (line ~ /^@@?\|\|/) {
    pre = ""
    start = 1
    if (substr(line, 1, 2) == "@@") { pre = "@@"; start = 3 }
    rest = substr(line, start + 2)
    p = find_anchor(rest)
    if (p) { anchor = substr(rest, 1, p - 1); tail = substr(rest, p) }
    else   { anchor = rest; tail = "" }
    # 锚点段含空白 -> 丢弃
    if (anchor ~ /[ \t]/) { anchorws++; next }
    anchor = tolower(anchor)
    # 裸 ||domain 正向识别补 ^（仅纯主机名字符）
    if (tail == "" && anchor != "" && anchor ~ /^[a-z0-9.-]+$/) tail = "^"
    # 纯域形态去结尾点（不触碰 ||x.$popup 类前缀规则）
    if (tail == "^" && anchor ~ /\.$/) { sub(/\.$/, "", anchor); dotstrip++ }
    # 空修饰符段清理
    if (tail ~ /^\^?\$/) {
      sep = ""
      if (substr(tail, 1, 1) == "^") { sep = "^"; mods = substr(tail, 3) }
      else mods = substr(tail, 2)
      sub(/^,/, "", mods)
      sub(/,$/, "", mods)
      while (gsub(/,,/, ",", mods) > 0) {}
      if (mods == "") tail = sep
      else tail = sep "$" mods
    }
    line = pre "||" anchor tail
  }

  print line
}
END {
  printf "[stats] norm: comment=%d header=%d hosts_junk=%d anchor_ws=%d trail_comment=%d http_skip=%d dot_strip=%d blank=%d\n", comment, header, hostsjunk, anchorws, trailc, httpskip, dotstrip, blank > "/dev/stderr"
}
' > "$WORKDIR/norm.tmp"

log "normalized: $(wc -l < "$WORKDIR/norm.tmp") rules"
LC_ALL=C sort -u "$WORKDIR/norm.tmp" > "$WORKDIR/norm.sorted"
log "sorted unique: $(wc -l < "$WORKDIR/norm.sorted") (sort 1/2)"

#####################
# 3+4. 白名单 + 父域消减 + $important 双写 + 残余分流（单 awk）
#####################
: > "$WORKDIR/domain.out"
: > "$WORKDIR/modify.out"

awk -v domainf="$WORKDIR/domain.out" -v modifyf="$WORKDIR/modify.out" '
function find_anchor(s,   i, c, L) {
  L = length(s)
  for (i = 1; i <= L; i++) {
    c = substr(s, i, 1)
    if (c == "^" || c == "$" || c == "/" || c == "|") return i
  }
  return 0
}
# 解析 || 起始文本：全局 A_anchor / A_tail
function parse_net(s,   rest, p) {
  rest = substr(s, 3)
  p = find_anchor(rest)
  if (p) { A_anchor = substr(rest, 1, p - 1); A_tail = substr(rest, p) }
  else   { A_anchor = rest; A_tail = "" }
}
function has_mod(t, name,   m, arr, n, i) {
  if (t !~ /^\^?\$/) return 0
  sub(/^\^?\$/, "", t)
  n = split(t, arr, ",")
  for (i = 1; i <= n; i++) if (arr[i] == name) return 1
  return 0
}
function valid_domain(d,   arr, n, i, lab) {
  if (length(d) > 253) return 0
  if (d !~ /^[a-z0-9.-]+$/) return 0
  if (d ~ /\.\./ || d ~ /^\./ || d ~ /\.$/) return 0
  if (d ~ /^[0-9.]+$/) return 0
  n = split(d, arr, ".")
  if (n < 2) return 0
  if (arr[n] ~ /^[0-9]+$/) return 0
  for (i = 1; i <= n; i++) {
    lab = arr[i]
    if (length(lab) < 1 || length(lab) > 63) return 0
    if (lab ~ /^-/ || lab ~ /-$/) return 0
  }
  return 1
}
# 提取 badfilter 目标：有则 BT=目标 返回 1
function bf_target(t,   seg, base, arr, n, k, out, found) {
  if (!match(t, /\$[^$]*badfilter[^$]*$/)) return 0
  seg = substr(t, RSTART + 1)
  n = split(seg, arr, ",")
  found = 0
  out = ""
  for (k = 1; k <= n; k++) {
    if (arr[k] == "badfilter") { found = 1; continue }
    out = (out == "" ? arr[k] : out "," arr[k])
  }
  if (!found) return 0
  base = substr(t, 1, RSTART - 1)
  BT = (out == "") ? base : base "$" out
  return 1
}
{
  lines[NR] = $0
}
END {
  n = NR

  # ---- a. 收集例外 ----
  for (i = 1; i <= n; i++) {
    r = lines[i]
    # 化妆例外 #@# 家族 -> 映射拦截形式入精确集合
    if (substr(r, 1, 2) == "#@") {
      if      (substr(r, 1, 3) == "#@#")  k = "##"  substr(r, 4)
      else if (substr(r, 1, 4) == "#@$#") k = "#$#" substr(r, 5)
      else if (substr(r, 1, 4) == "#@$^") k = "##^" substr(r, 5)
      else if (substr(r, 1, 4) == "#@%#") k = "#%#" substr(r, 5)
      else { cos_exc[r] = 1; cos_n++; continue }
      cos_exc[k] = 1; cos_n++
      continue
    }
    if (substr(r, 1, 2) != "@@") continue
    body = substr(r, 3)
    # badfilter 例外 -> 稍后从例外集移除
    if (bf_target(body)) { bfexc[++n_bfexc] = BT; continue }
    if (substr(body, 1, 2) == "||") {
      parse_net(body)
      anc = A_anchor; tail = A_tail
      if (substr(anc, 1, 2) == "*.") anc = substr(anc, 3)
      is_dom = 0; is_imp = 0
      if (tail == "^") is_dom = 1
      else if (tail ~ /^\^\$/) {
        m = substr(tail, 3)
        mn = split(m, marr, ",")
        ok = (mn >= 1)
        for (j = 1; j <= mn; j++) if (marr[j] != "important") ok = 0
        if (ok) { is_dom = 1; is_imp = 1 }
      }
      if (is_dom && anc != "" && anc ~ /^[a-z0-9.-]+$/) {
        if (anc in exc_dom) { if (is_imp) exc_dom[anc] = "important" }
        else exc_dom[anc] = is_imp ? "important" : "normal"
        exc_text[anc] = r
        exc_line_key[r] = anc
        exc_n++
        continue
      }
    }
    exc_exact[body] = 1
    exact_n++
  }
  # 应用 badfilter 例外
  for (b = 1; b <= n_bfexc; b++) {
    t = bfexc[b]
    if (t in exc_exact) { delete exc_exact[t]; exact_n-- }
    if (substr(t, 1, 2) == "||") {
      parse_net(t)
      anc = A_anchor
      if (substr(anc, 1, 2) == "*.") anc = substr(anc, 3)
      if (anc in exc_dom) { delete exc_dom[anc]; delete exc_text[anc]; exc_n-- }
    }
    bfex_n++
  }

  # ---- b. badfilter 拦截侧 ----
  for (i = 1; i <= n; i++) {
    r = lines[i]
    if (substr(r, 1, 2) == "@@") continue
    if (bf_target(r)) { bf_block[BT] = 1; is_bf[i] = 1; bf_n++ }
  }

  # ---- c. 拦截规则删除判定 ----
  for (i = 1; i <= n; i++) {
    r = lines[i]
    if (substr(r, 1, 2) == "@@") continue
    if (substr(r, 1, 2) == "#@") continue
    if (is_bf[i])        { drop_bf++;    keep[i] = 0; continue }
    if (r in bf_block)   { drop_bft++;   keep[i] = 0; continue }
    if (r in exc_exact)  { drop_exact++; keep[i] = 0; continue }
    if (r in cos_exc)    { drop_cos++;   keep[i] = 0; continue }
    if (substr(r, 1, 2) == "||") {
      parse_net(r)
      anc = A_anchor; tail = A_tail
      if (substr(anc, 1, 2) == "*.") anc = substr(anc, 3)
      rimp = has_mod(tail, "important")
      d = anc; dropped = 0; mnorm = 0
      for (lvl = 0; lvl < 7 && d != ""; lvl++) {
        if (d in exc_dom) {
          if (exc_dom[d] == "important") { dropped = 1; break }
          mnorm = 1
        }
        if (index(d, ".") == 0) break
        d = substr(d, index(d, ".") + 1)
      }
      if (!dropped && mnorm && !rimp) dropped = 1
      if (dropped) { drop_suf++; keep[i] = 0; continue }
      keep[i] = 1
      # 幸存锚点记录
      pure = (r ~ /^\|\|[a-z0-9.-]+\^$/)
      if (pure && valid_domain(substr(r, 3, length(r) - 3))) {
        anch_pure[anc] = 1
        pure_line[anc] = 1
        pure_cand++
      } else {
        anch_mod[anc] = 1
        if (pure) routed_invalid++
      }
      if (rimp) anch_imp[anc] = 1
      if (r ~ /^\|\|[a-z0-9.-]+\^\$important$/) {
        if (valid_domain(substr(r, 3, length(r) - 13))) { anch_pure[anc] = 1; extract_cand[anc] = 1 }
        anch_mod[anc] = 1
        anch_imp[anc] = 1
      } else if (!pure) {
        # 带修饰符规则的 important 标记已在上方 rimp 记录
      }
    } else {
      keep[i] = 1
    }
  }

  # ---- e. 父域包含消减 ----
  for (d in anch_pure) snap[d] = 1
  for (d in snap) {
    dd = d
    for (lvl = 0; lvl < 6; lvl++) {
      if (index(dd, ".") == 0) break
      dd = substr(dd, index(dd, ".") + 1)
      if (dd in snap) { delete anch_pure[d]; subsumed++; break }
    }
  }

  # ---- d. 残余例外检测 ----
  for (e in exc_dom) {
    e_imp = (exc_dom[e] == "important")
    if (!e_imp && (e in anch_imp)) { exc_drop++; continue }
    rw = 0; rm = 0; lost = 0
    d = e
    for (lvl = 0; lvl < 6; lvl++) {
      if (index(d, ".") == 0) break
      d = substr(d, index(d, ".") + 1)
      if (!e_imp && (d in anch_imp)) { lost = 1; break }
      if (d in anch_pure) rw = 1
      if (d in anch_mod)  rm = 1
    }
    if (lost)        { exc_drop++; continue }
    if (rw || rm)    { emit_w[e] = rw; emit_m[e] = rm; residual++ }
    else             { exc_drop++ }
  }

  # ---- 输出（按输入序，天然有序）----
  for (i = 1; i <= n; i++) {
    r = lines[i]
    if (substr(r, 1, 2) == "@@") {
      key = (r in exc_line_key) ? exc_line_key[r] : ""
      if (key != "" && key in emit_w) {
        if (emit_w[key]) { print r > domainf; dom_out++ }
        if (emit_m[key]) print r > modifyf
      }
      continue
    }
    if (substr(r, 1, 2) == "#@") continue
    if (!keep[i]) continue
    if (substr(r, 1, 2) == "||" && r ~ /^\|\|[a-z0-9.-]+\^$/) {
      anc = substr(r, 3, length(r) - 3)
      if (anc in anch_pure) {
        if (anc in pure_line) { print r > domainf; dom_out++; continue }
      }
      # 纯域被消减 -> 丢弃
      if (anc in pure_line) continue
    }
    print r > modifyf; mod_out++
    # $important 双写提取
    if (r ~ /^\|\|[a-z0-9.-]+\^\$important$/) {
      anc = substr(r, 3, length(r) - 13)
      if ((anc in anch_pure) && !(anc in pure_line) && !(anc in extracted)) {
        print "||" anc "^" > domainf
        extracted[anc] = 1
        extract_out++
      }
    }
  }

  printf "[stats] whitelist: exc_domain=%d exc_exact=%d exc_cosmetic=%d bf_exc=%d bf_rule=%d\n", exc_n, exact_n, cos_n, n_bfexc, bf_n > "/dev/stderr"
  printf "[stats] deleted: exact=%d cosmetic=%d suffix=%d badfilter=%d badfilter_target=%d\n", drop_exact, drop_cos, drop_suf, drop_bf, drop_bft > "/dev/stderr"
  printf "[stats] kept: domain=%d modify=%d subsumed=%d extracted_important=%d routed_invalid=%d\n", dom_out, mod_out, subsumed, extract_out, routed_invalid > "/dev/stderr"
  printf "[stats] residual: domain_or_modify=%d exc_dropped=%d\n", residual, exc_drop > "/dev/stderr"
}
' "$WORKDIR/norm.sorted"

#####################
# 5. 校验与输出
#####################
domain_lines=$(wc -l < "$WORKDIR/domain.out")
modify_lines=$(wc -l < "$WORKDIR/modify.out")

if [ "$domain_lines" -lt 50000 ]; then
  log "FAIL: domain.txt 仅 $domain_lines 行 (<50000)，疑似上游剧变，中止"
  exit 1
fi

LC_ALL=C sort -u "$WORKDIR/domain.out" "$WORKDIR/modify.out" > adall.txt.tmp
log "sort 2/2 done"

mv "$WORKDIR/domain.out" domain.txt.tmp
mv "$WORKDIR/modify.out" modify.txt.tmp

mv domain.txt.tmp domain.txt
mv modify.txt.tmp modify.txt
mv adall.txt.tmp adall.txt

rm -f white.txt
log "outputs: domain=$domain_lines modify=$modify_lines adall=$(wc -l < adall.txt)"
