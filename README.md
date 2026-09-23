# Custom Skills Hub

> 专为 AI Agent（Antigravity、Claude Code、Cursor、Windsurf 等）打造的自定义能力与工作流扩展仓库。

[![Skills Count](https://img.shields.io/badge/Skills-2%20Active-brightgreen.svg)](#-技能全景矩阵-skills-matrix)
[![Shell](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)](#-快速安装与配置-installation)
[![Workflow](https://img.shields.io/badge/Standard-Agent%20Skill%20Spec-orange.svg)](#-开发与贡献新技能-skill-development-guide)

本项目沉淀了面向**日常研发效能工程（DevOps/Git）**与 **AIGC 多模态内容创作（Creative Prompting）**的高价值 Skill 资产。每个 Skill 均严格遵循 Agent 技能标准（规范化 YAML Frontmatter、渐进式披露、带可执行脚本与参考样例），既可由 AI Agent 自动决策唤起，也可作为独立脚本在日常终端中开箱即用。

---

## 目录
- [ 技能全景矩阵 (Skills Matrix)](#-技能全景矩阵-skills-matrix)
- [ 快速安装与配置 (Installation)](#-快速安装与配置-installation)
  - [方式一：软链接至 Agent 全局技能目录（推荐）](#方式一软链接至-agent-全局技能目录推荐)
  - [方式二：注册为全局 Git / 终端别名](#方式二注册为全局-git--终端别名)
- [ 核心技能深度解析 (Featured Skills)](#-核心技能深度解析-featured-skills)
  - [1. Commit & Merge (自动化提交与发布)](#1-commit--merge-自动化提交与流水线部署)
  - [2. Creative Tech Ad (反差科技创意广告提示词)](#2-creative-tech-ad-反差科技创意广告提示词生成器)
- [ 仓库结构 (Repository Structure)](#-仓库结构-repository-structure)
- [ 开发与贡献新技能 (Skill Development Guide)](#-开发与贡献新技能-skill-development-guide)
- [ 许可证 (License)](#-许可证-license)

---

##  技能全景矩阵 (Skills Matrix)

| 技能名称 | 领域分类 | 核心功能 | 触发方式 / 指令 | 包含资源 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [`commit-and-merge`](./commit-and-merge/SKILL.md) | **研发提效 / Git 流水线** | 工作区自动暂存提交、推送远程、合并至部署分支（如 develop/pre）、触发 CI/CD 并安全切回 | `/ship`, `/commit-and-merge`, "发布预发", "提交合并" | Bash 引擎脚本、参数配置指南 | `Stable` |
| [`creative-tech-ad`](./creative-tech-ad/SKILL.md) | **AIGC / 多模态视频提示词** | 顶级科技发布会严肃风格包装日常接地气事物，生成端到端声画一体（海螺/MiniMax H3）分镜脚本与提示词 | "创意广告", "科技风广告", "包装土豆/大蒜", "生成带货脚本" | 15s 标准模板、黑话字典、经典成片样例 | `Stable` |

---

##  快速安装与配置 (Installation)

### 方式一：软链接至 Agent 全局技能目录（推荐）

通过软链接将本仓库的 Skill 接入本地 AI Agent 的全局配置目录（如 Antigravity / Gemini CLI 配置路径 `~/.gemini/config/skills/` 或各 Agent 的技能根目录），即可实现全局自动感知与唤醒：

```bash
# 1. 确保全局技能目录存在
mkdir -p ~/.gemini/config/skills

# 2. 将指定技能软链接到全局配置中
ln -s ~/Projects/custom-skills/commit-and-merge ~/.gemini/config/skills/commit-and-merge
ln -s ~/Projects/custom-skills/creative-tech-ad ~/.gemini/config/skills/creative-tech-ad

# 或者一次性批量软链接所有可用技能：
for skill in ~/Projects/custom-skills/*; do
  if [ -d "$skill" ] && [ -f "$skill/SKILL.md" ]; then
    ln -snf "$skill" ~/.gemini/config/skills/"$(basename "$skill")"
  fi
done
```

> **提示**：链接完成后，在与 Agent 对话时即可直接使用相关指令或自然语言唤起对应 Skill。

---

### 方式二：注册为全局 Git / 终端别名

针对 [`commit-and-merge`](./commit-and-merge/SKILL.md) 这类具备独立通用 Bash 引擎的工程技能，可以直接注册为 Git Global Alias，在任意项目终端中一秒调用：

```bash
# 注册 git ship 别名
git config --global alias.ship "!~/Projects/custom-skills/commit-and-merge/scripts/commit-and-merge.sh"

# 在任意 Git 项目中直接使用：
git ship "feat: 完成用户登录认证模块"
git ship "fix: 修复样式溢出" --skip-build
git ship -t release "release: 发布 v1.0.0"
```

---

##  核心技能深度解析 (Featured Skills)

### 1. Commit & Merge (自动化提交与流水线部署)

> 核心文档：[`commit-and-merge/SKILL.md`](./commit-and-merge/SKILL.md)

解决日常研发中在特性分支（如 `feature/xxx` 或个人开发分支）编码完毕后，需要反复进行“切分支 -> 拉最新 -> 合并代码 -> 推送触发构建流水线 -> 切回开发分支”的机械痛点，实现**一键闭环全流程发布**。

```mermaid
flowchart TD
    A[当前开发分支 (如 feat/login)] --> B{工作区是否有未提交修改?}
    B -- 有修改 --> C[自动执行 git add -A 并生成语义化 Commit]
    B -- 干净无修改 --> D[跳过 Commit 步骤]
    C --> E[本地快速编译 / 构建门禁检测]
    D --> E
    E --> F[推送当前分支到远程 origin]
    F --> G[拉取并 rebase 目标分支最新代码]
    G --> H[合并开发分支到目标发布分支]
    H --> I[推送目标分支到 origin 触发 CI/CD]
    I --> J[安全切回原工作分支恢复原状]
```

#### 核心亮点与安全防护
- **智能语义提交**：自动结合 Conventional Commits 规范与代码变更内容生成清晰的 Commit Message。
- **项目定制优先**：若项目根目录存在 `./scripts/ship-pre.sh` 或 `./scripts/ship.sh`，优先调用定制脚本；无定制脚本时由通用引擎托底。
- **构建门禁保护**：支持自动探测语言环境（Maven / pnpm / npm 等）进行本地预编译校验，避免将坏代码推入集成分支。
- **冲突自愈与回滚**：合并冲突时自动中断并提示冲突文件，支持 `git merge --abort` 优雅回滚，绝不破坏用户现场。

详细命令参数及高级配置请参阅：[commit-and-merge/references/usage_guide.md](./commit-and-merge/references/usage_guide.md)。

---

### 2. Creative Tech Ad (反差科技创意广告提示词生成器)

> 核心文档：[`creative-tech-ad/SKILL.md`](./creative-tech-ad/SKILL.md)

专门用于生成**“用苹果/特斯拉/英伟达顶级旗舰产品发布会的手法，包装大蒜、土豆、生姜、螺丝钉等日常接地气事物”**的高反差多模态视频提示词与视听分镜脚本。深度适配海螺视频（MiniMax H3）、Wan 2.1、CogVideoX 等先进声画一体视频生成大模型。

#### 核心设计法则（The Golden Rules）
1. **绝对严肃（Deadpan Dignity）**：通篇保持顶级旗舰发布的肃穆、纯粹与从容，绝不嬉皮笑脸，反差感越强越具冲击力。
2. **形态递进（Anti-Fatigue Progression）**：遵守经典演变线：`单体神秘悬浮外观 ➔ 内部硬核解构/全系矩阵 ➔ 终极热能相变`。
3. **声画文四位一体（Multimodal Alignment）**：画面动作、全息科技文字（HUD）、环境音效（SFX）、旁白（VO）严格按时间轴卡点对齐。
4. **冷幽默留白（Silent Punchline）**：旁白播音绝口不提俗气价格，仅在最后一刻将极接地气的真实零售价（如“¥1.50 起”）静默定帧浮现于角落。

#### 15秒经典三段式结构标准
- **00-05s【外观悬念】**：纯黑深邃背景、反重力悬浮、全息激光扫描、冷金双色边缘光。
- **05-10s【内核解构/家族矩阵】**：轴向爆炸解构、半透明微晶切片悬浮、全息 HUD 标注。
- **10-15s【热态相变与定帧】**：高温相变金黄炸裂、微米级白色蒸汽逆光喷发、大字高冷定帧、角落静默浮现真实价格。

#### 预置音色档案库
- **01号·科技发布会专属男声（默认推荐）**：35岁低沉磁性、胸腔共鸣、克制从容（0.85倍速）。
- **02号·极简高奢冷淡风女声**：28岁清冷知性、微语调、克制内敛（适用生活潮流物件包装）。
- **03号·硬核工业澎湃男声**：40岁厚重沙哑力量感、超级工程片质感（适用五金工具/重装物件）。

配套资源：
- [黑话映射字典 (Jargon Dictionary)](./creative-tech-ad/references/jargon_dictionary.md)：快速将外皮、内部结构、烹饪使用翻译为硬核黑话。
- [15秒标准提示词模板](./creative-tech-ad/references/prompt_templates.md)：开箱即用的声画分镜结构化代码块。
- [经典成片案例 - 土豆 Pro 15s](./creative-tech-ad/examples/potato_pro_15s.md)
- [经典成片案例 - 大蒜 Pro 15s](./creative-tech-ad/examples/garlic_pro_15s.md)

---

##  仓库结构 (Repository Structure)

```text
custom-skills/
├── README.md                           # 本仓库主说明文档
├── commit-and-merge/                   # [Skill] 自动化提交与发布工作流
│   ├── SKILL.md                        # Skill 核心定义与 Agent 触发规范
│   ├── scripts/                        # 可执行脚本目录
│   │   └── commit-and-merge.sh         # 通用跨分支合并与部署执行引擎
│   └── references/                     # 详细配置与使用指南
│       └── usage_guide.md              # 参数手册与 Git Alias 配置
└── creative-tech-ad/                   # [Skill] 反差科技创意广告生成器
    ├── SKILL.md                        # Skill 核心定义与工作流规范
    ├── references/                     # 参考手册与生成字典
    │   ├── jargon_dictionary.md        # 科技黑话映射字典
    │   └── prompt_templates.md         # 15s 端到端声画一体标准模板
    └── examples/                       # 经典实战案例库
        ├── potato_pro_15s.md           # 土豆 Pro 案例
        └── garlic_pro_15s.md           # 大蒜 Pro 案例
```

---

##  开发与贡献新技能 (Skill Development Guide)

本仓库欢迎扩展更多高频、通用的技能。创建新 Skill 时，请遵循以下规范：

### 1. 目录规范
每个 Skill 应当是一个独立的子文件夹，遵循如下标准布局：
```text
my-awesome-skill/
├── SKILL.md              # 必须：技能核心指令，包含 YAML Frontmatter 元数据
├── scripts/              # 可选：自动化脚本（Bash, Python, Node 等）
├── references/           # 可选：大型参考手册、规则字典、API 说明
└── examples/             # 可选：使用范例、测试输入与预期输出
```

### 2. `SKILL.md` 规范与模板
`SKILL.md` 必须包含规范的 YAML 头信息，明确技能名与触发意图：

```markdown
---
name: my-awesome-skill
description: >-
  清晰简要地描述该技能的核心功能与适用触发场景。当用户提到某些特定关键词或执行特定意图时唤起。
---

# My Awesome Skill 标题

简要描述本技能的目标与设计哲学。

## 适用场景与触发方式
- 触发关键词 / 命令
- 匹配的用户意图

## 标准执行工作流
1. 步骤一：前置检查
2. 步骤二：核心逻辑
3. 步骤三：验证与汇报

## 异常与边界处理
- 边界条件与容错机制
```

---

##  许可证 (License)

本项目采用 [MIT License](LICENSE) 授权许可。
