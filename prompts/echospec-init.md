---
description: 初始化 EchoSpec（仅创建 .echospec 结构；可选写入 AGENTS 规则块）
argument-hint: "[--no-agents]"
---

参数：
- $1（可选）：--no-agents（不写/不更新仓库根目录 AGENTS.md）

你要做什么（幂等）：
1) 定位目标仓库根目录：
- 若在 git 仓库内：用 `git rev-parse --show-toplevel`
- 否则：用当前目录

2) 创建/补齐以下路径（存在则跳过，不覆盖、不清空）：
- `.echospec/changes/`
- `.echospec/records/`
- `.echospec/spec/`
- `.echospec/current`（空文件即可）
- `.echospec/index.jsonl`（空文件即可）

3) 默认写入/追加 AGENTS.md 规则块（不覆盖用户已有内容）：
- 若传入 `--no-agents`：跳过。
- 若 `AGENTS.md` 不存在：创建并写入规则块。
- 若存在且已包含 `<!-- ECHOSPEC_RULES_BEGIN -->`：跳过。
- 若存在但没有该标记：追加规则块到文件末尾。

限制：
- 只做初始化与规则块写入，不创建 change，不生成 tasks/spec/notes 正文。

输出：
- 用简短列表报告：创建了哪些目录/文件，哪些已存在，AGENTS 是否写入。
