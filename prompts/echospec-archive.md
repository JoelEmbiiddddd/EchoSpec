---
description: 归档 change（records 为 SSOT），生成 summary + changelog，并追加 archived 事件（schema 固定）
argument-hint: [CHANGE_ID 可选]
---

## 语言要求（强制）
- 所有自然语言输出必须为中文（简体）。

## 参数
- $1 = CHANGE_ID（可选）；未提供则读 `.echospec/current`（必须非空）

## 目标（SSOT）
- `.echospec/changes/<id>/` -> `.echospec/records/<id>/`
- 生成 `.echospec/records/<id>/summary.md`（冻结总结，唯一事实源）
- 派生 `.echospec/spec/<YYYY-MM-DD>-<id>.md`（changelog 视图，与 summary 一致）
- 追加 index.jsonl 的 archived 事件（append-only）
- 清空 `.echospec/current`

## 短英文摘要规则（必须做）
在生成 `summary.md` 与 changelog 时，必须包含一个**短英文摘要**，用于列表/检索/slug 辅助：
- 字段名：`Short EN`
- 格式：`Short EN: <2~6 个英文单词>`
- 全小写、空格分隔、不要标点、不要长句
- 优先来源：
  1) `meta.json` 里的 `title`（通常就是你 new 时生成的英文短语）
  2) 若 `title` 不存在：根据变更内容自己概括生成（同规则）

同时保留中文标题（若 `meta.json` 有 `title_raw`，则使用它作为中文标题来源）。

## 规则
- 若 `.echospec/records/<id>/` 已存在：停止（避免覆盖历史）
- summary 不要长篇复述：3~7 条“改了什么” + 验收结论 + 风险/回滚
- summary/changelog 内容必须与仓库事实一致，不要凭空编造

## summary.md 推荐结构（强约束）
- 第一段包含：
  - `标题（中文）`：优先 `title_raw`，否则用 `title` 的中文解释
  - `Short EN: ...`
  - `change_id: ...`
  - `date: ...`
  - `status: archived`
- 后续段落：
  - 改动概述（3~7 条）
  - 验收与验证（命令/步骤）
  - 风险与回滚（短）

## 步骤
1) 确定 change_id；校验 change 目录存在
2) 移动目录到 records
3) 写 summary.md（中文为主 + Short EN 一行）
4) 写 changelog：`.echospec/spec/<date>-<id>.md`（可直接复制 summary 内容；同样包含 Short EN）
5) 追加 archived 事件到 `.echospec/index.jsonl`
6) 清空 `.echospec/current`（写空文件），输出所有产物路径
