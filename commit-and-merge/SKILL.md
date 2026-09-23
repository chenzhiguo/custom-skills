---
name: commit-and-merge
description: >-
  Automates committing current branch changes, pushing to remote, merging into a target deployment branch (e.g., develop, main, pre), pushing to trigger CI/CD pipelines, and safely switching back to the working branch. Use when the user asks to ship, commit and merge, deploy changes, or sync work to integration/pre-release branches.
---

# Commit & Merge (一键提交、合并与流水线发布)

本 Skill 专用于将本地当前特性/开发分支（如 `czg_dev`、`feature/*`）的代码**一键自动化暂存提交、推送到远程仓库、同步并合并至目标集成/发布分支（如 `develop`、`main`、`pre`），触发远程 CI/CD 部署流水线，并在完成后安全自动切回原工作分支**。

---

## 适用场景与触发方式

当用户出现以下意图时激活本 Skill：
- 用户输入 `/ship` 或 `/commit-and-merge` 指令。
- 用户要求：“一键发布预发”、“提交并合并到 develop/main 分支”、“把当前代码推到预发”、“ship this” 等。
- 用户在完成某个功能或 Bug 修复后，希望将当前分支快速合并并触发流水线部署。

---

## 核心执行工作流

Agent 在响应此请求时，应按以下严格步骤执行：

### 步骤 1：工作区状态与变更自检
执行工作区状态检查：
```bash
git status -s
```
- **若工作区存在未暂存/未提交的代码改动**：
  - 若用户在输入中已提供明确的提交说明（例如 `/ship "feat: 增加对账导出"`），直接采用该说明。
  - 若用户未提供提交说明：
    - 执行 `git diff --stat` 或 `git diff --cached --stat` 查阅变更摘要。
    - 由 Agent 依据 Conventional Commits 规范，自动提炼一条精准、语义明确的提交信息（例如 `feat(reconciliation): ...`、`fix(billing): ...`）。
- **若工作区干净无未提交修改**：
  - 无需额外生成 Commit，直接进行后续的分支合并与推送流程。

### 步骤 2：选择并执行发布脚本
遵循“**项目定制脚本优先，通用引擎托底**”原则：

1. **项目定制优先**：检查当前项目根目录下是否存在定制的发布脚本（例如 `./scripts/ship-pre.sh` 或 `./scripts/ship.sh`）。若存在且具备执行权限，优先执行该脚本：
   ```bash
   ./scripts/ship-pre.sh "<Commit Message 或留空>" [--skip-build] [--target <目标分支>]
   ```
2. **通用引擎托底**：若项目无自带发布脚本，则调用本 Skill 提供的通用脚本：
   ```bash
   ~/Projects/custom-skills/commit-and-merge/scripts/commit-and-merge.sh "<Commit Message 或留空>" [--skip-build] [--target <目标分支>]
   ```
   *(注：若用户明确提到快速发布或无需本地构建，可附加 `--skip-build`)*

### 步骤 3：验证执行结果并结构化汇报
1. **退出状态校验**：确认命令执行退出码为 `0`；
2. **分支与工作区验证**：
   - 验证目标分支（如 `develop`）与特性分支（如 `czg_dev`）是否均已成功推送至远程 `origin`；
   - 确认当前工作分支已自动切回用户最初所在的开发分支；
3. **输出汇总报告**：
   - **提交信息与哈希**：展示最终采用的 Commit Message 及 Git Commit ID；
   - **分支同步详情**：明确展示从 `[当前分支]` ➔ 合并至 ➔ `[目标分支]`；
   - **CI/CD / 预发环境提示**：
     - 若当前项目为预发环境项目（如 `maas-realtime-monitor-bill`），明确提示预发服务域名（如 `http://maas-monitor-bill-pre.jd.com`）；
     - 提示流水线已由 Git Push 触发，预计 1~3 分钟内生效；
     - 提示当前已停留在原开发分支，工作区已恢复干净，可随时继续后续编码。

---

## 异常与冲突处理指引

如果在执行过程中发生异常，Agent 应按以下规范处理：
1. **构建/编译门禁失败**：
   - 立即停止推送，保留当前工作区分支与代码；
   - 向用户清晰报告编译失败原因与报错日志，并提示可选择修复代码或追加 `--skip-build` 强制发布。
2. **目标分支合并冲突 (`Merge Conflict`)**：
   - 脚本会自动中断；Agent 提示冲突文件列表；
   - 若用户要求放弃合并，执行 `git merge --abort && git checkout <原开发分支>` 恢复原状；
   - 若用户要求协助解决冲突，在目标分支解决并提交后再推送。

---

## 参考文档与扩展资源
- 详细参数手册与 Git Alias 配置：[usage_guide.md](./references/usage_guide.md)
- 通用执行引擎源码：[commit-and-merge.sh](./scripts/commit-and-merge.sh)
