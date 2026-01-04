---
description: 创建 change（自动生成 change_id；tasks/spec/notes 为空；仅 meta.json 写最小内容；写 current；追加 index 事件）
argument-hint: "一句话描述（约10字）"
---

参数：
- $1 = DESC（必填，例如：新增登录接口）

目标：
- 自动生成 change_id = YYYY-MM-DD_###_<slug>
- 创建 .echospec/changes/<change_id>/
  - tasks.md（空文件）
  - spec.md（空文件）
  - notes.md（空文件）
  - meta.json（写最小 JSON，约 10 行）
- 写入 .echospec/current = <change_id>
- 追加 .echospec/index.jsonl 两个事件（append-only，schema 固定）：
  1) change_created
  2) set_current

硬规则：
- new 阶段只建空文件；不要生成 tasks/spec/notes 正文内容。
- 若生成的目录已存在：不要覆盖任何文件，停止并提示。

实现要求（必须按命令生成，不要脑补）：

0) 确保 EchoSpec 结构存在（幂等）：
- .echospec/changes
- .echospec/records
- .echospec/spec
- .echospec/current（不存在则创建空文件）
- .echospec/index.jsonl（不存在则创建空文件）

1) 校验 DESC 非空，否则提示用法并停止。

2) 生成 at（ISO +08:00）与 date（YYYY-MM-DD），优先 python3：
python3 - <<'PY'
import datetime
tz = datetime.timezone(datetime.timedelta(hours=8))
now = datetime.datetime.now(tz)
print(now.isoformat(timespec="seconds"))
print(now.date().isoformat())
PY
得到两行输出：第一行 at，第二行 date。

3) 生成 slug（短、稳定、仅 [a-z0-9-]）：
- 从 DESC 中提取英文/数字并 slugify；若为空（纯中文常见），用短哈希兜底：c + sha1(desc)[:6]
用 python3：
python3 - <<'PY'
import re, hashlib, sys
desc = sys.argv[1]
s = desc.lower()
s2 = re.sub(r'[^a-z0-9]+', '-', s).strip('-')
if not s2:
    s2 = "c" + hashlib.sha1(desc.encode("utf-8")).hexdigest()[:6]
s2 = s2[:20].strip('-') or ("c" + hashlib.sha1(desc.encode("utf-8")).hexdigest()[:6])
print(s2)
PY "$DESC"

4) 生成 seq（当天递增 3 位）：
扫描两个目录里以 "<date>_" 开头的目录名，取最大序号 +1：
- .echospec/changes
- .echospec/records
用 python3：
python3 - <<'PY'
import os, re, sys
date = sys.argv[1]
roots = [".echospec/changes", ".echospec/records"]
pat = re.compile(rf"^{re.escape(date)}_(\d{{3}})_")
mx = 0
for r in roots:
    if not os.path.isdir(r):
        continue
    for name in os.listdir(r):
        m = pat.match(name)
        if m:
            mx = max(mx, int(m.group(1)))
print(f"{mx+1:03d}")
PY "$DATE"

5) 组装 change_id：
change_id = f"{date}_{seq}_{slug}"

6) 创建目录与文件（tasks/spec/notes 必须为空文件）：
change_dir=".echospec/changes/<change_id>"
- mkdir -p "$change_dir"
- : > "$change_dir/tasks.md"
- : > "$change_dir/spec.md"
- : > "$change_dir/notes.md"

7) 写 meta.json（最小内容，字段固定，约 10 行）：
{
  "change_id": "<change_id>",
  "title": "<DESC>",
  "created_date": "<date>",
  "created_at": "<at>",
  "status": "draft",
  "tags": [],
  "refs": { "issue": null, "pr": null }
}

8) 写入 .echospec/current（覆盖为 change_id）。

9) 追加 index.jsonl 两行事件（每行一个 JSON，字段名固定，不省略顶层字段）：

事件 1：change_created
{
  "schema":"echospec.index.v1",
  "type":"change_created",
  "at":"<at>",
  "change_id":"<change_id>",
  "title":"<DESC>",
  "status":"draft",
  "paths":{
    "change_dir":"<change_dir>",
    "tasks":"<change_dir>/tasks.md",
    "spec":"<change_dir>/spec.md",
    "notes":"<change_dir>/notes.md",
    "meta":"<change_dir>/meta.json",
    "current":".echospec/current"
  },
  "refs":{"issue":null,"pr":null},
  "tags":[],
  "data":{"desc":"<DESC>"}
}

事件 2：set_current
{
  "schema":"echospec.index.v1",
  "type":"set_current",
  "at":"<at>",
  "change_id":"<change_id>",
  "title":"<DESC>",
  "status":"draft",
  "paths":{"current":".echospec/current"},
  "refs":{"issue":null,"pr":null},
  "tags":[],
  "data":{"current":"<change_id>"}
}

10) 输出：
- 生成的 change_id
- change_dir 路径
- 提醒用户：将 tasks/spec/notes 的内容自行粘贴/维护到这三个空文件中；meta.json 可按需更新标题/标签/refs。
