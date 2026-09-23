# Commit and Merge 指南与最佳实践

本指南提供了 `commit-and-merge` 技能的高级配置、命令行参数详解以及常见场景排查手册。

---

## 1. 核心流程图解

```mermaid
flowchart TD
    A[当前开发分支 (如 czg_dev)] --> B{工作区是否有未暂存修改?}
    B -- 是 --> C[执行 git add -A 并基于 Commit Message 提交]
    B -- 否 --> D[跳过 Commit]
    C --> E[本地快速编译/构建检查]
    D --> E
    E --> F[推送当前分支到 origin]
    F --> G[拉取并 rebase 目标分支 develop]
    G --> H[合并开发分支到目标分支]
    H --> I[推送目标分支到 origin (触发 CI/CD)]
    I --> J[安全切回原开发分支 czg_dev]
```

---

## 2. 脚本命令参数详解

通用脚本路径：`scripts/commit-and-merge.sh`

| 参数 / 选项 | 别名 | 默认值 | 作用说明 |
|---|---|---|---|
| `[commit message]` | `-m` | `""` | 提交说明信息。若工作区有改动则必须提供（或由 Agent 智能生成） |
| `--target <branch>` | `-t` | `develop` | 目标发布分支。支持 `develop`, `main`, `master`, `pre`, `release` 等 |
| `--remote <remote>` | `-r` | `origin` | 远程 Git 仓库名 |
| `--skip-build` | `-s` | `false` | 跳过本地构建/编译门禁（加速发布） |
| `--build-cmd <cmd>` | `-b` | 自动探测 | 自定义本地校验命令（如 `mvn compile` 或 `pnpm check`） |
| `--help` | `-h` | - | 查看脚本帮助信息 |

---

## 3. Git 全局别名配置推荐

你可以将通用脚本注册为全局 Git 命令，在任何项目中直接使用：

```bash
# 注册 git ship 全局别名
git config --global alias.ship "!~/Projects/custom-skills/commit-and-merge/scripts/commit-and-merge.sh"

# 在任意 Git 项目中直接使用：
git ship "feat: 新增用户登录鉴权功能"
git ship "fix: 修复样式问题" --skip-build
git ship -t release "release: 发布 v1.2.0"
```

---

## 4. 常见异常与恢复策略

### 4.1 目标分支合并冲突 (`git merge conflict`)
- **现象**：在第 4 步合并时提示 `Automatic merge failed; fix conflicts and then commit the result`。
- **恢复方案 1（放弃合并回滚）**：
  ```bash
  git merge --abort
  git checkout <你的开发分支>
  ```
- **方案 2（在目标分支解决冲突）**：
  解决冲突文件后，执行：
  ```bash
  git add <冲突文件>
  git commit --no-edit
  git push origin <目标分支>
  git checkout <你的开发分支>
  ```

### 4.2 远程目标分支 rebase 冲突
- **现象**：在同步最新目标分支执行 `git pull --rebase` 时冲突。
- **恢复方案**：
  ```bash
  git rebase --abort
  git checkout <你的开发分支>
  ```
