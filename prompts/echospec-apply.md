---
description: 执行 change（严格 tasks-only），并追加 status 事件（in_progress / done）
argument-hint: [CHANGE_ID 可选]
---

## 语言要求（强制）
- 所有自然语言输出必须为中文（简体）。

## 参数
- $1 = CHANGE_ID（可选）；未提供则读 `.echospec/current`（必须非空）

## 规则（极重要）
- 只按 `.echospec/changes/<id>/tasks.md` 逐条执行（禁止范围外重构/顺手优化）
- `spec.md` 仅用于验收口径对齐；默认不读 `notes.md`（除非 tasks 要求）
- 需求不清：把问题写进 notes.md 的“待确认”，并立刻停下向用户提问

## 事件账本（append-only）
- 在开始时追加 1 条 status 事件：to=in_progress
- 全部完成并验证通过后追加 1 条 status 事件：to=done
- schema 固定：`echospec.index.v1`
- at 使用 +08:00 当前时间（优先 python3）

## 执行流程
1) 确定 change_id；校验目录与 tasks/spec/meta 存在
2) 追加 in_progress 事件到 `.echospec/index.jsonl`
3) 严格按 tasks.md 顺序执行；每步完成都要给出：
   - 改了哪些文件（列表）
   - 如何验证（命令/测试/手动步骤）
4) 全部完成后，确保构建/测试/验收通过
5) 追加 done 事件到 `.echospec/index.jsonl`
