#!/usr/bin/env bash
set -euo pipefail

# 用法：
#   DESC="xxx" DATE="YYYY-MM-DD" bash scripts/new.sh
#   或：bash scripts/new.sh "xxx" "YYYY-MM-DD"

desc_raw="${DESC_RAW:-${1:-}}"
desc="${DESC:-${desc_raw}}"   # 期望是短英文（2~6词）；为空则回退
date_in="${DATE:-${2:-}}"

# 项目根目录（优先 git root）
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
project_name="$(basename "$project_root")"

# DESC 为空则回退项目名（同时保证 desc_raw 也有值）
if [[ -z "${desc//[[:space:]]/}" ]]; then
  desc="$project_name"
fi
if [[ -z "${desc_raw//[[:space:]]/}" ]]; then
  desc_raw="$desc"
fi

cd "$project_root"

mkdir -p .echospec/changes .echospec/records .echospec/spec
[[ -f .echospec/current ]] || : > .echospec/current
[[ -f .echospec/index.jsonl ]] || : > .echospec/index.jsonl

python3 - <<'PY' "$desc" "$desc_raw" "$date_in"
import datetime, hashlib, json, os, re, sys
from pathlib import Path

desc = sys.argv[1]
desc_raw = sys.argv[2]
date_in = sys.argv[3].strip() if len(sys.argv) > 3 else ""

tz = datetime.timezone(datetime.timedelta(hours=8))
now = datetime.datetime.now(tz)
at = now.isoformat(timespec="seconds")
date = date_in or now.date().isoformat()

# slug：仅 [a-z0-9-]，纯中文则短哈希兜底
s = desc.lower()
slug = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
if not slug:
    slug = "c" + hashlib.sha1(desc.encode("utf-8")).hexdigest()[:6]
slug = (slug[:20].strip("-") or ("c" + hashlib.sha1(desc.encode("utf-8")).hexdigest()[:6]))

# seq：当天递增（扫描 changes + records）
def max_seq_under(base: Path) -> int:
    m = 0
    if not base.exists():
        return 0
    pat = re.compile(rf"^{re.escape(date)}_(\d{{3}})_")
    for p in base.iterdir():
        if not p.is_dir():
            continue
        mm = pat.match(p.name)
        if mm:
            try:
                m = max(m, int(mm.group(1)))
            except:
                pass
    return m

changes = Path(".echospec/changes")
records = Path(".echospec/records")
seq = max(max_seq_under(changes), max_seq_under(records)) + 1
change_id = f"{date}_{seq:03d}_{slug}"

change_dir = changes / change_id
if change_dir.exists():
    raise SystemExit(f"[echospec-new] ERROR: change 已存在：{change_dir}")

change_dir.mkdir(parents=True, exist_ok=False)

# new 阶段：只创建空文件
(tasks, spec, notes, meta) = (
    change_dir / "tasks.md",
    change_dir / "spec.md",
    change_dir / "notes.md",
    change_dir / "meta.json",
)
tasks.write_text("", encoding="utf-8")
spec.write_text("", encoding="utf-8")
notes.write_text("", encoding="utf-8")

meta_obj = {
    "title": desc,          # short EN（2~6词，new prompt 里生成）
    "title_raw": desc_raw,  # 原始输入（可中文）
    "date": date,
    "status": "new",
    "change_id": change_id,
}
meta.write_text(json.dumps(meta_obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

Path(".echospec/current").write_text(change_id + "\n", encoding="utf-8")

# 事件账本：append-only（两条）
index = Path(".echospec/index.jsonl")
paths = {
    "change_dir": str(change_dir),
    "tasks": str(tasks),
    "spec": str(spec),
    "notes": str(notes),
    "meta": str(meta),
    "current": ".echospec/current",
    "index": ".echospec/index.jsonl",
}

events = [
    {
        "schema": "echospec.index.v1",
        "type": "change_created",
        "at": at,
        "change_id": change_id,
        "title": desc,
        "status": "new",
        "paths": paths,
        "refs": {"issue": None, "pr": None},
        "tags": [],
        "data": {"desc": desc, "desc_raw": desc_raw, "date": date},
    },
    {
        "schema": "echospec.index.v1",
        "type": "set_current",
        "at": at,
        "change_id": change_id,
        "title": desc,
        "status": "new",
        "paths": {"current": ".echospec/current"},
        "refs": {"issue": None, "pr": None},
        "tags": [],
        "data": {"to": change_id},
    },
]

with index.open("a", encoding="utf-8") as f:
    for e in events:
        f.write(json.dumps(e, ensure_ascii=False) + "\n")

print(f"[echospec-new] change_id: {change_id}")
print(f"[echospec-new] dir: .echospec/changes/{change_id}/")
PY
