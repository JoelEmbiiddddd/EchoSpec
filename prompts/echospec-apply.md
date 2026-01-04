---
description: 执行 change（tasks-only），并追加 status 事件（in_progress / done）
argument-hint: [CHANGE_ID 可选]
---

参数：
- $1 = CHANGE_ID（可选）
若未提供，从 .echospec/current 读取（必须非空）。

目标：
- 严格按 tasks.md 执行
- 只在 tasks 要求时参考 spec.md
- 默认不读 notes.md（除非 tasks 要求）
- 在 .echospec/index.jsonl 追加 status 事件（append-only，schema 固定）：
  - 开始：* -> in_progress
  - 完成：in_progress -> done

事件字段要求：
- at：ISO(+08:00)，优先 python3
- title：从 meta.json 读取（优先 jq，否则 python3；读不到则 ""）
- status：顶层 status = data.to
- paths：固定拼接

执行步骤：
1) 确定 change_id（参数优先，否则读 .echospec/current；为空则停止并提示先 echospec-new）
2) 设定路径：
change_dir=".echospec/changes/<id>"
meta="$change_dir/meta.json"
tasks="$change_dir/tasks.md"
spec="$change_dir/spec.md"
notes="$change_dir/notes.md"

3) 读取 title：
- 若有 jq：jq -r .title "$meta"
- 否则：python3 -c 'import json;print(json.load(open("'"$meta"'")).get("title",""))'

4) 生成 at（ISO +08:00），优先 python3：
python3 - <<'PY'
import datetime
tz = datetime.timezone(datetime.timedelta(hours=8))
print(datetime.datetime.now(tz).isoformat(timespec="seconds"))
PY

5) 追加 status 事件（to=in_progress）到 .echospec/index.jsonl：
{
  "schema":"echospec.index.v1",
  "type":"status",
  "at":"<at>",
  "change_id":"<id>",
  "title":"<title>",
  "status":"in_progress",
  "paths":{"change_dir":"<change_dir>","tasks":"<tasks>","spec":"<spec>","notes":"<notes>","meta":"<meta>"},
  "refs":{"issue":null,"pr":null},
  "tags":[],
  "data":{"from":null,"to":"in_progress"}
}

6) 严格按 tasks.md 顺序执行。每完成一步：列出改动文件 + 如何验证（命令/测试/手动验证）。
7) 若需求不清：写入 notes.md 的“待确认”，停止继续并向用户提问。
8) 当 tasks 全部完成、测试/构建通过后：
- 再生成新的 at（不要复用旧 at）
- 追加 status 事件（to=done）：
{
  "schema":"echospec.index.v1",
  "type":"status",
  "at":"<at>",
  "change_id":"<id>",
  "title":"<title>",
  "status":"done",
  "paths":{"change_dir":"<change_dir>"},
  "refs":{"issue":null,"pr":null},
  "tags":[],
  "data":{"from":"in_progress","to":"done"}
}
