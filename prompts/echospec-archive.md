---
description: 归档 change（records 为 SSOT），生成 summary + changelog，并追加 archived 事件（schema 固定）
argument-hint: [CHANGE_ID 可选]
---

参数：
- $1 = CHANGE_ID（可选）
若未提供，从 .echospec/current 读取（必须非空）。

目标（SSOT）：
- .echospec/changes/<id>/ -> .echospec/records/<id>/
- 生成 .echospec/records/<id>/summary.md（冻结总结，唯一事实源）
- 派生 .echospec/spec/<YYYY-MM-DD>-<id>.md（changelog 视图；与 summary 一致）
- 追加 index.jsonl archived 事件（append-only，schema 固定）
- 清空 .echospec/current

步骤：
1) 确定 change_id（参数优先，否则读 current；为空则停止）
2) 校验 .echospec/changes/<id>/ 存在；且至少有 tasks.md/spec.md/meta.json（notes.md 可选）
3) 读取 title（meta.json；读不到则 ""）
4) 获取 date=YYYY-MM-DD 与 at=ISO(+08:00)（优先 python3）
5) 若 .echospec/records/<id>/ 已存在则停止（避免覆盖历史）
6) 移动目录：.echospec/changes/<id>/ -> .echospec/records/<id>/

7) 写 summary（短、可读、可审计；不要长篇复述）：
- 标题：# <change_id>
- 日期：<date>
- 标题：<title>
- 修改了什么（3-7条）
- 更新内容（简要）
- 最终成效（验收：测试/构建/手动验证结论；缺少写“未提供”）
- 关键文件列表：优先 git diff --name-only（若可用）；否则列出主要文件
- 风险与回滚（1-3条）
信息来源：records/<id>/spec.md + tasks.md + meta.json + git diff（若可用）

8) 写 changelog：.echospec/spec/<date>-<id>.md（内容与 summary 一致；可复制 summary）

9) 追加 archived 事件：
{
  "schema":"echospec.index.v1",
  "type":"archived",
  "at":"<at>",
  "change_id":"<id>",
  "title":"<title>",
  "status":"archived",
  "paths":{
    "record_dir":".echospec/records/<id>",
    "summary":".echospec/records/<id>/summary.md",
    "changelog":".echospec/spec/<date>-<id>.md",
    "current":".echospec/current"
  },
  "refs":{"issue":null,"pr":null},
  "tags":[],
  "data":{ }
}

10) 清空 .echospec/current（写成空文件），输出所有产物路径。
