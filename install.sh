#!/bin/sh
# appstore skill 万能安装器 —— 自动装进本机所有支持 Agent Skills 标准的 agent
#   curl -fsSL https://raw.githubusercontent.com/Shawn1993/ship-appstore/main/install.sh | sh
# 可选：SKILLS_DIR=/path/to/skills sh install.sh   # 只装到指定目录
set -eu

REPO="Shawn1993/ship-appstore"
SKILL="appstore"
TMP=""

say() { printf '%s\n' "$*"; }

# 1) 拿到 skill 源（本地仓库内直接用；否则拉最新）
if [ -d "$(dirname "$0")/skills/$SKILL" ] 2>/dev/null; then
  SRC="$(cd "$(dirname "$0")/skills/$SKILL" && pwd)"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --quiet "https://github.com/$REPO" "$TMP/repo"
  else
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" | tar -xz -C "$TMP"
    mv "$TMP"/*-main "$TMP/repo"
  fi
  SRC="$TMP/repo/skills/$SKILL"
fi
[ -f "$SRC/SKILL.md" ] || { say "✗ 未找到 skill 源，安装失败"; exit 1; }

install_to() {
  dest="$1/$SKILL"
  mkdir -p "$dest"
  # 覆盖式同步（更新即重跑本脚本）
  rm -rf "$dest"
  cp -R "$SRC" "$dest"
  say "  ✓ $dest"
}

say "appstore skill 安装器"

# 2) 指定目录模式
if [ "${SKILLS_DIR:-}" != "" ]; then
  install_to "$SKILLS_DIR"
  exit 0
fi

# 3) 自动探测各 agent 的 skills 目录（存在 agent 配置目录才装）
FOUND=0
for agent in claude codex gemini openclaw hermes pi antigravity; do
  base="$HOME/.$agent"
  [ -d "$base" ] || continue
  mkdir -p "$base/skills"
  install_to "$base/skills"
  FOUND=1
done

if [ "$FOUND" = "0" ]; then
  say "  未检测到已知 agent（~/.claude ~/.codex ~/.gemini ~/.openclaw ~/.hermes …）"
  say "  手动安装：SKILLS_DIR=<你的 agent 的 skills 目录> sh install.sh"
  exit 1
fi

say "完成。对你的 agent 说「我要上架 App」即可触发；更新重跑本命令即可。"
