---
description: 创建 change（默认不走大模型；可选 THINK=true 生成 tasks/spec/notes 正文）
argument-hint: DESC="" DATE="" THINK="false"  # DESC 可空；THINK=true 时会生成三份正文
---

## 语言要求（强制）
- 无论用户使用何种语言，你的所有自然语言输出必须为中文（简体）。
- 代码/命令/路径可保持原样，但解释说明必须中文。

## 参数来源
- 优先读取环境变量：DESC / DATE / THINK
- 若环境变量为空，再读取位置参数：$1 / $2 / $3
- DESC 最终为空：脚本会自动回退为“项目名”（git root 目录名）

## DESC 规范化（必须做）
当用户提供了 DESC（非空）时：
1) 设 `DESC_RAW` 为用户原始输入（保留中文/原文）
2) 生成 `DESC_SHORT`（用于 meta.json.title 和 change_id 的 slug 来源）：
   - 如果 DESC_RAW 含中文：翻译成英文，并压缩概括为 **2~6 个英文单词**
   - 如果 DESC_RAW 是英文：同样压缩概括为 **2~6 个英文单词**
   - 全小写、空格分隔、不要标点、不要长句
3) 后续把 `DESC_RAW` 和 `DESC_SHORT` 一起传给脚本（脚本会负责 slug 化/截断）

若用户没有提供 DESC（空）：
- 不要生成 DESC_SHORT，也不要传 DESC_RAW，让脚本自动用项目名兜底。

## 执行（尽量少说话；先落盘）
1) 检查脚本是否存在（稳定路径，随 install/update 安装）：
   - `~/.echospec/kit/scripts/new.sh`
   - 若不存在：提示先运行 `echospec install`（或在 EchoSpec 仓库下执行 `./scripts/cli.sh link && echospec install`），然后停止。
2) 执行创建：
   - 若 DESC 非空：
     `DESC_RAW="..." DESC="(DESC_SHORT)" DATE="..." bash ~/.echospec/kit/scripts/new.sh`
   - 若 DESC 为空：
     `DATE="..." bash ~/.echospec/kit/scripts/new.sh`

## THINK=false（默认）：只做创建，不生成正文
输出：
- 打印生成的 change_id
- 打印 change 目录路径（`.echospec/changes/<change_id>/`）
- 说明：new 阶段 tasks/spec/notes 为空文件，等待用户粘贴正文

## THINK=true（一步完成，读取本地模板）
- 在完成创建后，你必须从本机读取 `~/.codex/prompts/echospec-think.md`（通过 shell 命令），并严格按其中规则继续。
- 你必须把“用于人类语义”的描述传递给后续生成阶段：优先使用 `DESC_RAW`；若 `DESC_RAW` 为空才使用 `DESC`（即 DESC_SHORT）。
- 注意：`DESC`/DESC_SHORT 仅用于 change_id 与 meta.json.title 的短英文标题；不得用它替代原始需求描述。

执行命令（必须）：
- `test -f ~/.codex/prompts/echospec-think.md && cat ~/.codex/prompts/echospec-think.md || echo "__THINK_PROMPT_MISSING__"`


> 重要：此处不要直接生成正文。请严格按 `/prompts:echospec-think` 的规则完成“提问或输出三文件正文”。

