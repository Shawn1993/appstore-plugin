#!/usr/bin/env python3
"""交付页组装（opendesign viewer 模式）：固定壳 report-viewer.html + LLM 产出的 report-data.json → 单文件 HTML。

用法：
  python3 build-report.py <report-data.json> <output.html> [--viewer <report-viewer.html>]

- viewer 默认取本脚本同级 ../assets/report-viewer.html（随 skill 分发的固定资产，LLM 不生成不修改）
- data.json 是 LLM 的唯一产出：扁平纯数据，schema 见 ../assets/report-data-template.json
- 本脚本校验必填结构后，把 JSON 注入壳内 __REPORT_DATA__ 占位，输出可双击直开的单文件
  （不用 fetch 读 JSON：file:// 下会被同源策略拦）

字符计数/超限标红由壳内 JS 现算，LLM 与本脚本都不用算。
"""
import json, os, sys

REQUIRED = {
    'app': ['name', 'version', 'build'],
    'status': ['badge', 'headline', 'steps'],
    'audit': ['status', 'next', 'issues', 'passed'],
}
TOP = ['app', 'status', 'meta', 'key_info', 'version_fields',
       'appinfo_fields', 'privacy_fields', 'pricing_fields', 'audit']

def die(msg):
    sys.exit(f'schema 校验失败: {msg}')

def main():
    argv = sys.argv[1:]
    viewer = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'report-viewer.html')
    if '--viewer' in argv:
        i = argv.index('--viewer'); viewer = argv[i + 1]; del argv[i:i + 2]
    if len(argv) != 2:
        print(__doc__); sys.exit(1)
    data_path, out_path = argv

    data = json.load(open(data_path, encoding='utf-8'))
    for k in TOP:
        if k not in data: die(f'缺顶层键 {k}')
    for parent, keys in REQUIRED.items():
        for k in keys:
            if k not in data[parent]: die(f'缺 {parent}.{k}')
    for i, it in enumerate(data['audit']['issues']):
        for k in ('severity', 'title', 'desc', 'source', 'state'):
            if k not in it: die(f'audit.issues[{i}] 缺 {k}')
        if it['severity'] not in ('crit', 'warn'): die(f'audit.issues[{i}].severity 必须是 crit/warn')
    for g in data.get('screenshots', []):
        for it in g.get('items', []):
            p = os.path.join(os.path.dirname(os.path.abspath(out_path)), it['src'])
            if not os.path.exists(p):
                print(f'警告: 截图不存在 {it["src"]}', file=sys.stderr)

    shell = open(viewer, encoding='utf-8').read()
    if '__REPORT_DATA__' not in shell:
        sys.exit('viewer 里找不到 __REPORT_DATA__ 占位——文件损坏或版本不符')
    payload = json.dumps(data, ensure_ascii=False).replace('</', '<\\/')
    open(out_path, 'w', encoding='utf-8').write(shell.replace('__REPORT_DATA__', payload))
    print(f'ok: {out_path} (shell {len(shell)}B + data {len(payload)}B)')

if __name__ == '__main__':
    main()
