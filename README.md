# **Adguard Home**
[adguard home过滤规则语法](https://adguard-dns.io/kb/zh-CN/general/dns-filtering-syntax/#adblock-style-syntax)
* ```example.com```:仅限域的语法
* ```||example.org^```：阻止访问 example.org 域及其所有子域，例如 www.example.org 。
* ```@@||example.org^```：取消阻止对 example.org 域及其所有子域的访问。
* ```1.2.3.4 example.org```：（注意，旧的 /etc/hosts 语法）在 AdGuard Home 里用 1.2.3.4 对 example.org 域名的查询，但 没有 其子网域的查询。 在私人 AdGuard DNS 中，阻止对 example.org 的访问。 www.example.org 仍然允许。
* ```0.0.0.0 example.org```
* ```127.0.0.1 example.org```
* ```||example.org^$important``` 将拦截所有对 *.example.org 的请求，即使有例外规则。
* ```@@||example.org^$important```
*``` /example.*/``` 将拦截与 example.* 正则表达式匹配的主机。
* ```@@/example.*/$important``` 将取消拦截和匹配 example.\* 的正则表达式。 请注意，此规则也包含 important 修饰符。
* ```@@||*^$client=127.0.0.1```: 取消拦截本地主机的所有内容。
* ```||example.org^$client='Frank\'s laptop'```：仅对名为 Frank's laptop 的客户端拦截example.org。 请注意，名称中的引号 (') 必须转义。
* ```||example.org^$client=~'Mary\'s\, John\'s\, and Boris\'s laptops'```: 除了名为 Mary's, John's, and Boris's laptops的客户端，为其他所有人拦截 example.org 。 请注意，逗号 (,) 也必须转义。
* ```||example.org^$client=~Mom|~Dad|Kids```：只对 Kids 拦截 example.org ，但不对 Mom 和 Dad 拦截它。 此示例演示如何在一个规则中指定多个客户端。
* ```||example.org^$client=192.168.0.0/24```：为 IP 地址在 192.168.0.0 到 192.168.0.255 范围内的所有客户端拦截 example.org。
* ```*$denyallow=com|net```: 除了 *.com 和 *.net 以外拦截所有内容。
* ```@@*$denyallow=com|net```：除了 *.com 和 *.net 以外取消拦截所有内容
* ```||example.org^$denyallow=sub.example.org```:拦截 example.org 和 *.example.org ，但不拦截 sub.example.org。
* ```||example.org^$dnstype= AAAA```：拦截对 example.org的 IPv6 地址的 DNS 查询。
* ```||example.org^$dnstype=~A|~CNAME```：只允许 A 和 CNAME 对 example.org 进行 DNS 查询 ，拦截其余部分。
* ```||4.3.2.1.in-addr.arpa^$dnsrewrite=NOERROR;PTR;example.net```:为反向 DNS 添加 PTR 记录。 向 DNS 服务器发出的 1.2.3.4 反向 DNS 请求将产生 example.net。
注意： IP 地址必须按反向顺序排列。 请参阅 RFC 1035。
* ```||example.com^$dnsrewrite=NOERROR;A;1.2.3.4``` 添加了一个值为 1.2.3.4 的 A 记录。
* ```||example.com^$dnsrewrite=NOERROR;AAAA;abcd::1234``` 添加了一个值为 abcd::1234 的 AAAA 记录。
* ```||example.com^$dnsrewrite=NOERROR;CNAME;example.org``` 添加一个 CNAME 记录。 见上述解释。
* ```||example.com^$dnsrewrite=NOERROR;HTTPS;32 example.com alpn=h3``` 添加一个 HTTPS 记录。
* ```||example.com^$dnsrewrite=NOERROR;MX;32 example.mail``` 添加一个 MX 记录，优先级值为 32 ，交换值为 example.mail。
* ```||example.com^$dnsrewrite=NOERROR;SVCB;32 example.com alpn=h3``` 添加一个 SVCB 值。 请参阅上面的 HTTPS 示例。
* ```||example.com^$dnsrewrite=NOERROR;TXT;hello_world``` 添加一个 TXT 记录，其值为 hello_world。
* ```||_svctype._tcp.example.com^$dnsrewrite=NOERROR;SRV;10 60 8080 example.com``` 添加一条 SRV 记录，优先级值 10，权重值 60，端口 8080，目标值 example.com。
* ```||example.com^$dnsrewrite=NXDOMAIN```:以 NXDOMAIN 代码进行响应。
* ```$dnstype=AAAA,denyallow=example.org,dnsrewrite=NOERROR```:以空的 NOERROR 响应所有 AAAA 的请求，除了 example.org。
* ```@@||example.com^$dnsrewrite``` 删除所有 DNS 重写规则。
* ```@@||example.com^$dnsrewrite=1.2.3.4``` 删除添加带有 1.2.3.4 值 A 记录的 DNS 重写规则。
* ```||example.com$badfilter``` 禁用 ||example.com.
* ```@@||example.org^$badfilter``` 禁用 @@||example.org^.
* ```||example.org^$ctag=device_pc|device_phone```：为标记为 device_pc 或 device_phone的客户端拦截 example.org 。
* ```||example.org^$ctag=~device_phone```：为除了标记为 device_phone 的客户端以外的所有客户端，拦截 example.org 。

