# 广告规则合并列表

每日由 GitHub Actions 自动合并多个广告规则源，产出面向 **sing-box** 与 **uBlock Origin** 的规则文件。任一规则源下载失败或输出异常缩水时，脚本会中止并**不会覆盖提交**，保证仓库内列表始终可用。

**分支约定**：`main` 只保留维护文件（`mod.sh`、CI、`extra/add.txt`、本 README），自 `1f78aed` 起恢复常规提交历史；生成的规则文件全部在 **`data` 分支**（CI 每次以无历史单提交强推），订阅请使用 `data` 分支地址。

**white.txt**：本仓库不再单独产出；白名单/残余例外相关处理见 [ANOONIMASXP/MOD](https://github.com/ANOONIMASXP/MOD) 的 `mod.sh`。

## 订阅地址（data 分支）

| 文件 | raw 地址 |
|---|---|
| `domain.txt` | `https://raw.githubusercontent.com/Mujinniao/list/data/domain.txt` |
| `modify.txt` | `https://raw.githubusercontent.com/Mujinniao/list/data/modify.txt` |
| `adall.txt` | `https://raw.githubusercontent.com/Mujinniao/list/data/adall.txt` |

## 输出文件

| 文件 | 用途 | 格式 | 消费端 |
|---|---|---|---|
| `domain.txt` | 域名类规则：`||domain^` 拦截 + 残余 `@@` 域名例外（并入 domain） | `\|\|domain^` / `@@\|\|domain^` | **sing-box** rule-set（`domain_suffix`，转换时跳过 `@@` 行） |
| `modify.txt` | 其余规则：化妆品 `##`/`###`、带修饰符网络规则、正则、非域名类残余 `@@` 例外 | ABP/uBO 语法 | **uBlock Origin** |
| `adall.txt` | 上述两者合并的全量存档 | 混合 | 存档/自定义加工 |

## 生成流程（mod.sh）

1. **下载校验**：5 个源全部带 `-f`、重试、超时；非空且 ≥100 行才通过，任一失败即中止；
2. **归一化**：去 BOM/`\r`/首尾空白，删注释与 `[Adblock Plus 2.0]` 类头行；hosts 行多域名转换（含行内注释、`::1`）；`\|\|http(s)://` 前缀剥离；锚点小写；裸 `\|\|domain` 补 `^`；纯域去尾点；空修饰符清理；尾随 ` # 注释` 剥离；
3. **白名单处理**：`@@` 例外**从黑名单中直接删除**对应拦截规则——域名后缀匹配（`\|\|a.com^` 级别逐级上溯）+ `$important`/作用域修饰符感知；`#@#` 化妆例外精确对消；`$badfilter` 双向移除；
4. **无法兑现的残余例外**：如拦截 `\|\|example.com^` 与例外 `\|\|mail.example.com^` 并存（删父规则会放行整个域），保留为 `@@`：域名类并入 `domain.txt`，其余写入 `modify.txt`；
5. **瘦身与校验**：父域包含消减（父域在则删冗余子域，拦截覆盖完全等价）；`\|\|domain^$important` 额外向 `domain.txt` 提取裸域（硬拦截不丢域名）；非法域（单标签、超长标签、IPv4 字面量等）路由至 `modify.txt`；
6. **sanity check**：`domain.txt < 5 万行` 即中止，不覆盖输出。

## sing-box 接线

sing-box 配置文件为 JSON 格式，示例（`config.json` 片段）：

```json
{
  "route": {
    "rule_set": [
      {
        "type": "remote",
        "tag": "block",
        "format": "source",
        "url": "<domain.txt 转换后的 rule-set 地址>"
      }
    ],
    "rules": [
      {
        "rule_set": ["block"],
        "outbound": "block"
      }
    ]
  }
}
```

注意事项：
- 转换 `domain.txt` 为 `domain_suffix` 时**跳过 `@@` 开头的残余例外行**；`||domain^` 是 `example.com` 及其**全部子域**的拦截，与 sing-box `domain_suffix` 语义一致；
- 转换时须保证点边界（勿用裸 `HasSuffix`，否则 `nota.com` 会被 `a.com` 误匹配）；
- 白名单/`@@` 消费端处理见 [ANOONIMASXP/MOD](https://github.com/ANOONIMASXP/MOD)。

## uBlock Origin

直接订阅 `modify.txt`（或 `adall.txt`）。化妆品规则、`#@#` 例外、正则与带修饰符规则均为 uBO 原生语法；`$important` 类规则保留原样。

## 白名单语义说明

- 白名单（`@@`）**不进 `domain.txt` 的拦截部分**，一律转换为"从黑名单删除"；
- 仅删除法无法无损兑现的域名类例外并入 `domain.txt`（`@@` 行），非域名类进 `modify.txt`；
- 本仓库不单独产出 `white.txt`；需要独立白名单文件的场景使用 [ANOONIMASXP/MOD](https://github.com/ANOONIMASXP/MOD)；
- 普通例外可取消不带 `$important` 的拦截规则（含带其他修饰符的）；`$important` 拦截规则只有 `$important` 例外能取消；`$client`/`$dnstype` 等作用域例外只做精确文本匹配。

## 规则语法参考

常用 AdGuard/uBO 语法速查：

- `example.com`：仅限域的语法
- `||example.org^`：阻止 example.org 域及其所有子域
- `@@||example.org^`：取消阻止
- `0.0.0.0 example.org` / `127.0.0.1 example.org`：hosts 格式
- `||example.org^$important`：即使有例外规则也拦截
- `@@||example.org^$important`
- `/example.*/`：正则拦截
- `||example.org^$denyallow=sub.example.org`：拦截但排除子域
- `||example.org^$client=192.168.0.0/24`：按客户端拦截
- `||example.com$badfilter`：禁用同名规则

完整语法见 [AdGuard Home 过滤规则语法](https://adguard-dns.io/kb/zh-CN/general/dns-filtering-syntax/#adblock-style-syntax)。
