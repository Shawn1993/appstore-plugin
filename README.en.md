# ship-appstore

[中文](README.md) | **English**

A full-lifecycle App Store management skill for any AI coding agent (Claude Code / Codex / Gemini CLI / OpenClaw…) — from "just give me your website URL" all the way to an approved release.

## Features

| Stage | Capability |
|---|---|
| Smart intake | Give it just a product website or repo path — it auto-extracts app name, features, legal-page URLs, brand colors, and privacy-questionnaire answers; asks you at most 5 questions |
| Asset production | Full metadata copywriting (promo text / description / keywords / subtitle, with character-budget and dedup rules), three screenshot production pipelines with size compliance |
| Build & upload | xcodebuild + ASC API Key command-line direct upload, no Xcode UI; asc CLI metadata pull/push automation |
| ASC walkthrough | Page-by-page checklist for App Information / Privacy / Pricing / Version page / Review Information, with correct answers for common traps (no-login apps, export compliance, …) |
| Pre-submission audit | Built-in rejection-rule library (per-app-type checklists + metadata/privacy/design/subscription/entitlements rules, each with guideline number and real rejection cases) + China-storefront quick checks |
| Rejection recovery | Locate the rule behind a rejection notice's guideline number, Resolution Center reply templates, appeal decision guidance |
| Post-launch ASO | Keyword research (free data stack), rating-prompt strategy, review management, editorial-featuring pitches, In-App Events, A/B testing |

## Full official-docs index

We **crawled the entire App Store Connect Help site (263 pages) and built an index** (`references/official/sitemap.md`), plus a quick-reference of high-frequency official pages (`references/official/index.md`). Hard specs in this skill — screenshot dimensions, character limits, etc. — trace back to official pages instead of model memory. `scripts/refresh-sitemap.sh` re-crawls the index in one command whenever Apple updates the docs.

Three knowledge systems, each with an explicit trust level: ASC Help (official, the sole authority for how-to operations) → App Review Guidelines (official, the sole source of guideline clauses) → the preflight rejection-rule library (third-party field experience, vendored under MIT). Official sources win on conflict.

## Install

**Universal one-liner** (auto-installs into every agent on your machine that supports the Agent Skills standard — Claude Code / Codex / Gemini CLI / OpenClaw / Hermes…):

```bash
curl -fsSL https://raw.githubusercontent.com/Shawn1993/ship-appstore/main/install.sh | sh
```

Updating is the same command. Custom location: `SKILLS_DIR=<dir> sh install.sh`

<details>
<summary>Manual install per agent</summary>

This skill follows the open Agent Skills standard (SKILL.md + references/) and works in any agent that reads a skills directory:

| Agent | How |
|---|---|
| Claude Code (as plugin) | `/plugin marketplace add Shawn1993/ship-appstore` → `/plugin install appstore@ship-appstore` |
| Claude Code (as skill) | Copy `skills/appstore` → `~/.claude/skills/` |
| Codex | Copy `skills/appstore` → `~/.codex/skills/` |
| Gemini CLI | Copy `skills/appstore` → `~/.gemini/skills/` |
| OpenClaw | Copy `skills/appstore` → `~/.openclaw/skills/` |
| Any other SKILL.md-compatible agent | Copy `skills/appstore` → that agent's skills directory |
| Agents without skills support | Merge `skills/appstore/SKILL.md` into its system prompt / AGENTS.md and place `references/` alongside your project |

> The SKILL.md body is written in Chinese, but users of any language can use it directly — the agent reads the Chinese knowledge and responds in your language. The China-storefront compliance knowledge (ICP filing, advertising law, review-mode switch pattern for hybrid apps) is exactly the part that's scarce in the English-speaking world.

</details>

## Usage

No commands to memorize — just talk to your agent:

- "I want to ship this to the App Store, here's my site https://…" → full pipeline
- "Audit this — will it get rejected?" → rule-library scan producing a Rejections / Warnings / Passed report
- "We got rejected" + paste the notice → guideline lookup + reply template
- "Make my store screenshots" / "help with keywords" → the corresponding asset stage

## Structure

```
skills/appstore/
├── SKILL.md                    # Main router: dispatch table + 6-stage SOP + gotchas + guardrails
├── assets/
│   ├── metadata-template.md    # Full-field submission metadata template
│   └── UploadOptions.plist     # xcodebuild direct-upload config
├── scripts/
│   └── refresh-sitemap.sh      # Re-crawl the official help-site index
└── references/
    ├── guides/                 # First-party methodology
    │   ├── asc-cli.md          #   asc CLI field manual
    │   ├── aso-playbook.md     #   ASO & post-launch ops (zero external API deps)
    │   ├── screenshots.md      #   Screenshot sizes & production pipelines
    │   ├── regions.md          #   Global regional compliance matrix
    │   └── derived-app-audit.md#   Special audit for template/shell-derived apps
    ├── official/               # Official docs index
    │   ├── index.md            #   High-frequency official pages + trust levels
    │   └── sitemap.md          #   Full ASC Help site, 263 pages
    └── preflight/              # Rejection-rule library (third-party, MIT)
```

## Prerequisites

- App Store Connect API Key (`.p8` in `~/.appstoreconnect/private_keys/`) — required for direct upload and asc CLI
- Optional: `brew install asc` (metadata automation), codex CLI (image-to-image screenshot design)

## Acknowledgments

This skill stands on the shoulders of these open-source projects:

- [truongduy2611/app-store-preflight-skills](https://github.com/truongduy2611/app-store-preflight-skills) (MIT) — source of the built-in rejection-rule library; excellent per-app-type checklists and rule organization
- [rudrankriyam/App-Store-Connect-CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI) and [rorkai/app-store-connect-cli-skills](https://github.com/rorkai/app-store-connect-cli-skills) — the asc CLI and its usage patterns; much of this skill's metadata/submission automation knowledge is distilled from them
- [Eronred/aso-skills](https://github.com/Eronred/aso-skills) — key reference for ASO methodology (keyword frameworks, rating-prompt strategy, editorial-featuring tips)
- [trunghaiy/appshot](https://github.com/trunghaiy/appshot) and [NaufalRusada/claude-skill-appstore-screenshots](https://github.com/NaufalRusada/claude-skill-appstore-screenshots) — references for the store-screenshot production pipeline
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills), [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) — discovery hubs for great skills

## License

MIT. The `references/preflight/` rule library is vendored from [truongduy2611/app-store-preflight-skills](https://github.com/truongduy2611/app-store-preflight-skills) (MIT); see ATTRIBUTION.md.
