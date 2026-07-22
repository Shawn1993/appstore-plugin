#!/bin/bash
# 重抓 ASC 官方帮助全站索引 → references/official/sitemap.md
# 苹果改版目录后跑一次即可。依赖：curl、python3。
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp)"
curl -s --max-time 30 "https://developer.apple.com/help/app-store-connect/" -o "$TMP"
python3 - "$TMP" "$DIR/references/official/sitemap.md" << 'PYEOF'
import re, sys, collections
html = open(sys.argv[1], encoding="utf-8").read()
pairs = re.findall(r'<a[^>]+href="(/help/app-store-connect/[^"#]*)"[^>]*>(.*?)</a>', html, re.S)
seen = {}
for href, text in pairs:
    t = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', text)).strip()
    if href not in seen and t:
        seen[href] = t
assert len(seen) > 100, f"仅抓到 {len(seen)} 条，页面结构可能已变，请人工检查"
groups = collections.OrderedDict()
for href, t in seen.items():
    parts = href.rstrip('/').split('/')
    groups.setdefault(parts[3] if len(parts) > 3 else '_root', []).append((href, t))
out = ["# App Store Connect 官方帮助全站索引（自动抓取）", "",
       "> 来源：developer.apple.com/help/app-store-connect/ 着陆页 TOC 全量抓取。",
       "> 用法：按主题定位到页面后 WebFetch 原文；刷新：scripts/refresh-sitemap.sh。", ""]
for sec, items in groups.items():
    out += [f"## {sec}（{len(items)}）", ""]
    out += [f"- [{t}](https://developer.apple.com{h})" for h, t in sorted(items)]
    out.append("")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(out))
print(f"OK: {len(seen)} pages / {len(groups)} sections -> {sys.argv[2]}")
PYEOF
rm -f "$TMP"
