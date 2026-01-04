<!-- ECHOSPEC_RULES_BEGIN -->

## EchoSpec 工作流（强制）
- 执行入口：只执行 `.echospec/changes/<change-id>/tasks.md`（按顺序逐条完成）
- `tasks.md / spec.md / notes.md` 的内容由用户自行维护与粘贴；`echospec-new` 阶段不生成正文
- **new 阶段只建空文件；任何正文变更必须来自用户粘贴或用户明确指令生成**
- `spec.md` 仅用于验收口径对齐；不要扩写成长文
- `notes.md` 仅作人类存档；除非 tasks 明确要求，否则不要读取
- 禁止范围外重构、禁止“顺手优化”

## 事件账本（面向产品化/可回放）
- `.echospec/index.jsonl` 是 append-only 事件账本（每行一个 JSON，schema=`echospec.index.v1`）
- UI/脚本：按 `change_id` 聚合，按 `at` 排序即可回放
- 归档后以 `.echospec/records/<change-id>/summary.md` 作为冻结总结（SSOT）
- `.echospec/spec/` 仅为 changelog 视图（由 summary 派生保持一致）

<!-- ECHOSPEC_RULES_END -->
