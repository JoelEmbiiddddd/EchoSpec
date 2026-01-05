# EchoSpec

EchoSpec 是一套面向 Codex 的轻量变更工作流：用「用户自填的 tasks/spec/notes」+「事件账本 index.jsonl」实现可反思、可思考、可回放、可归档、可自动化。

> 设计原则：**只使用你本地 clone 的 EchoSpec 仓库作为来源**。  
> EchoSpec 不会在安装/更新时额外从 GitHub clone/pull，也不会维护任何 “kit” 目录。  
> 你想升级 EchoSpec：自己在这份仓库里 `git pull`，然后在项目里跑 `echospec update`。  

---

## 核心概念

- `tasks.md`：唯一执行入口（按步骤执行）
- `spec.md`：验收口径与范围（短）
- `notes.md`：人类存档（可选）
- `meta.json`：机器可读索引
- `.echospec/index.jsonl`：append-only 事件账本（便于 UI/回放/审计）

**约束：**
- `new` 阶段只创建空文件（`tasks/spec/notes`），正文由用户自行粘贴/维护
- 执行只以 `tasks.md` 为准（按顺序逐条完成）

---

## 与 OpenSpec / SpecKit 的区别（简述）

- EchoSpec 不强调 proposal / 持续推演，避免重复思考造成 token 浪费
- EchoSpec 更强调：用户内容 + 事件账本，便于产品化与可回放

---

## 安装（全局 CLI）

### 1) Clone EchoSpec（只需一次）

```bash
git clone https://github.com/JoelEmbiiddddd/EchoSpec.git
cd EchoSpec
````

### 2) 生成全局命令 `echospec`

```bash
# 只使用你本地 clone 的仓库，不会从 GitHub 额外 clone/pull
./scripts/cli.sh link
```

默认会把命令写到：`~/.local/bin/echospec`（一个很小的 stub，指向你当前这份 EchoSpec 仓库路径）。

### 3) 确保 `~/.local/bin` 在 PATH 中

仅对**当前终端**生效：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

建议做成**永久生效**（二选一）：

* bash（Ubuntu/Debian 常见）：

  ```bash
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  ```

* zsh：

  ```bash
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  ```

验证：

```bash
which echospec
echospec --version
```

> 小提示：如果 `echospec --version` 输出后面紧贴着 shell 提示符，说明 `VERSION` 文件末尾缺少换行符，补一个 `\n` 即可。

---

## 在任意项目启用 / 更新 / 卸载

在你的目标项目仓库根目录（或任意子目录）执行：

```bash
# 初始化项目 .echospec，并安装 prompts 到 ~/.codex/prompts
echospec install [--force-prompts] [--no-agents]

# 用当前 EchoSpec 仓库的 prompts 覆盖 ~/.codex/prompts（会自动备份旧文件）
echospec update [--agents] [--force-prompts]

# 删除 ~/.codex/prompts 的 echospec-*.md，并移除 AGENTS.md 规则块（可选清理 .echospec）
echospec uninstall [--yes] [--purge-echospec]
```

### install 做了什么

* 创建/补齐项目内的 `.echospec/` 结构（幂等，不覆盖已有内容）
* 把 EchoSpec prompts 安装到 `~/.codex/prompts/`
* 默认会在项目根目录创建/追加 `AGENTS.md` 的 EchoSpec 规则块（可用 `--no-agents` 禁用）

### update 做了什么

* 用当前 EchoSpec 仓库中的 prompts 覆盖 `~/.codex/prompts/` 的同名文件
* 会自动备份被替换的旧文件（备份位置由脚本输出提示）
* 可选 `--agents`：同步更新项目根目录 `AGENTS.md` 的 EchoSpec 规则块

### uninstall 做了什么

* 删除 `~/.codex/prompts/echospec-*.md`
* 移除项目根目录 `AGENTS.md` 里的 EchoSpec 规则块（仅移除插入块，不动用户其它内容）
* 可选 `--purge-echospec`：删除项目内 `.echospec/`（会清历史，谨慎）

---

## 更新 EchoSpec 本身

EchoSpec **不会自动拉新代码**。请在你 clone 的 EchoSpec 仓库里手动执行：

```bash
cd /path/to/EchoSpec
git pull
```

然后在目标项目里执行：

```bash
cd /path/to/your/project
echospec update
```

---

## 常见问题（FAQ）

### Q1: 我执行 `./scripts/cli.sh link` 后，`echospec: command not found`

A: 绝大多数是 `~/.local/bin` 不在 PATH。按上面的 PATH 配置做一次即可。

### Q2: 为什么 EchoSpec 不从 GitHub clone / pull？

A: 这是刻意设计：**只认用户本地仓库**，版本更新由用户自己 `git pull` 控制，行为稳定可预期。

### Q3: 我移动/删除了 EchoSpec 仓库目录会怎样？

A: 因为 `echospec` stub 固定指向这份仓库路径，移动/删除后命令会失效。
解决：到新的 EchoSpec 目录重新执行一次 `./scripts/cli.sh link` 生成新的 stub。


