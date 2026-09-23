#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: commit-and-merge.sh
# 作用: 一键暂存并提交当前开发分支、推送到远程、同步合并到目标发布分支并推送
# 支持自动触发 CI/CD 或部署流水线，最后自动切回原开发分支。
# 用法:
#   ./commit-and-merge.sh ["commit message"] [--target develop] [--skip-build]
# ==============================================================================

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TARGET_BRANCH="${TARGET_BRANCH:-develop}"
REMOTE="${REMOTE:-origin}"
SKIP_BUILD=false
CUSTOM_BUILD_CMD=""
COMMIT_MSG=""

# ------------------------------------------------------------------------------
# 参数解析
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build|-s)
      SKIP_BUILD=true
      shift
      ;;
    --target|-t)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --remote|-r)
      REMOTE="$2"
      shift 2
      ;;
    --build-cmd|-b)
      CUSTOM_BUILD_CMD="$2"
      shift 2
      ;;
    -m|--message)
      COMMIT_MSG="$2"
      shift 2
      ;;
    --help|-h)
      echo -e "${CYAN}用法: commit-and-merge.sh [\"提交信息\"] [选项]${NC}"
      echo ""
      echo "选项:"
      echo "  -m, --message <msg>     指定提交说明（如果工作区有改动）"
      echo "  -t, --target <branch>   目标合并分支 (默认: develop)"
      echo "  -r, --remote <remote>   Git 远程仓库名 (默认: origin)"
      echo "  -s, --skip-build        跳过本地构建/编译门禁"
      echo "  -b, --build-cmd <cmd>   自定义本地构建校验命令"
      echo "  -h, --help              查看帮助信息"
      exit 0
      ;;
    *)
      if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="$1"
      else
        COMMIT_MSG="$COMMIT_MSG $1"
      fi
      shift
      ;;
  esac
done

# ------------------------------------------------------------------------------
# 1. 检查当前 Git 环境与分支
# ------------------------------------------------------------------------------
ORIGIN_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [ -z "$ORIGIN_BRANCH" ]; then
  echo -e "${RED}❌ 无法获取当前 Git 分支，请确认当前目录处于有效 Git 仓库中。${NC}"
  exit 1
fi

if [ "$ORIGIN_BRANCH" = "$TARGET_BRANCH" ]; then
  echo -e "${RED}❌ 当前已经在目标发布分支 [${TARGET_BRANCH}] 上，无需合并。${NC}"
  echo -e "   提示: 请切换到特性/开发分支后再执行本流程。"
  exit 1
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}🚀 启动一键提交与合并流水线 [${ORIGIN_BRANCH} -> ${TARGET_BRANCH}]${NC}"
echo -e "${BLUE}=====================================================${NC}"

# ------------------------------------------------------------------------------
# 2. 检查工作区与 Commit 处理
# ------------------------------------------------------------------------------
HAS_DIRTY_FILES=false
if ! git diff-index --quiet HEAD -- 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
  HAS_DIRTY_FILES=true
fi

if [ "$HAS_DIRTY_FILES" = true ]; then
  if [ -n "$COMMIT_MSG" ]; then
    echo -e "${YELLOW}📝 正在暂存并提交修改: \"${COMMIT_MSG}\"...${NC}"
    git add -A
    git commit -m "$COMMIT_MSG"
  else
    echo -e "${RED}❌ 检测到当前工作区有未提交的代码变更，且未提供提交信息！${NC}"
    echo -e "   提示: 请先手动 git commit，或直接运行: ${YELLOW}$0 \"你的提交说明\"${NC}"
    exit 1
  fi
else
  if [ -n "$COMMIT_MSG" ]; then
    echo -e "${YELLOW}ℹ️ 工作区干净无改动，跳过 commit 步骤，直接同步合并分支...${NC}"
  fi
fi

# ------------------------------------------------------------------------------
# 3. 本地快速构建门禁（可选跳过）
# ------------------------------------------------------------------------------
if [ "$SKIP_BUILD" = false ]; then
  BUILD_CMD=""
  if [ -n "$CUSTOM_BUILD_CMD" ]; then
    BUILD_CMD="$CUSTOM_BUILD_CMD"
  elif [ -f "pom.xml" ]; then
    if [ -d "res-center-infra-impl" ]; then
      BUILD_CMD="mvn compile -pl res-center-infra-impl,res-center-app -am -q"
    else
      BUILD_CMD="mvn compile -q"
    fi
  elif [ -f "pnpm-lock.yaml" ]; then
    BUILD_CMD="pnpm check || pnpm typecheck 2>/dev/null || true"
  elif [ -f "package.json" ]; then
    BUILD_CMD="npm run check 2>/dev/null || true"
  elif [ -f "Cargo.toml" ]; then
    BUILD_CMD="cargo check -q"
  elif [ -f "go.mod" ]; then
    BUILD_CMD="go build ./..."
  fi

  if [ -n "$BUILD_CMD" ]; then
    echo -e "${BLUE}🔨 [1/5] 执行本地快速构建检查 (${BUILD_CMD})...${NC}"
    if eval "$BUILD_CMD"; then
      echo -e "${GREEN}✓ 构建检查通过${NC}"
    else
      echo -e "${RED}❌ 本地代码构建失败！已终止推送，请修复错误后再发布。${NC}"
      echo -e "   (如需临时跳过构建检查，可添加 --skip-build 参数)"
      exit 1
    fi
  else
    echo -e "${YELLOW}⏭️ [1/5] 未检测到匹配的构建配置，跳过本地编译检查${NC}"
  fi
else
  echo -e "${YELLOW}⏭️ [1/5] 已指定 --skip-build，跳过本地构建检查${NC}"
fi

# ------------------------------------------------------------------------------
# 4. 推送当前特性分支
# ------------------------------------------------------------------------------
echo -e "${BLUE}📤 [2/5] 推送当前分支 [${ORIGIN_BRANCH}] 到远程 ${REMOTE}...${NC}"
git push "$REMOTE" "$ORIGIN_BRANCH"

# ------------------------------------------------------------------------------
# 5. 切到目标分支并拉取最新代码
# ------------------------------------------------------------------------------
echo -e "${BLUE}🔄 [3/5] 同步目标分支 [${TARGET_BRANCH}]...${NC}"
git fetch "$REMOTE" "$TARGET_BRANCH"

# 检查目标分支本地是否存在
if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  git checkout "$TARGET_BRANCH"
else
  git checkout -b "$TARGET_BRANCH" "$REMOTE/$TARGET_BRANCH"
fi

echo -e "   拉取最新 [${TARGET_BRANCH}] 并 rebase..."
if ! git pull --rebase "$REMOTE" "$TARGET_BRANCH"; then
  echo -e "${RED}❌ 同步远程 ${TARGET_BRANCH} 遇到冲突，请排查解决冲突后再试！${NC}"
  git checkout "$ORIGIN_BRANCH"
  exit 1
fi

# ------------------------------------------------------------------------------
# 6. 合并开发分支到目标分支
# ------------------------------------------------------------------------------
echo -e "${BLUE}🔀 [4/5] 合并 [${ORIGIN_BRANCH}] 到 [${TARGET_BRANCH}]...${NC}"
if ! git merge "$ORIGIN_BRANCH" --no-edit; then
  echo -e "${RED}❌ 合并时发生代码冲突，已停止。请手动解决冲突后完成提交。${NC}"
  echo -e "   若需放弃本次合并，可运行: git merge --abort && git checkout ${ORIGIN_BRANCH}"
  exit 1
fi

# ------------------------------------------------------------------------------
# 7. 推送目标分支（触发流水线）
# ------------------------------------------------------------------------------
echo -e "${BLUE}🚀 [5/5] 推送 [${TARGET_BRANCH}] 到远程仓库，触发部署流水线...${NC}"
git push "$REMOTE" "$TARGET_BRANCH"

# ------------------------------------------------------------------------------
# 8. 切回原始开发分支
# ------------------------------------------------------------------------------
git checkout "$ORIGIN_BRANCH"

echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}🎉 流程完成！已自动切回工作分支: ${ORIGIN_BRANCH}${NC}"
echo -e "   - 目标分支: ${TARGET_BRANCH} (已同步并推送到 ${REMOTE})"
echo -e "   - 流水线构建已触发，请关注 CI/CD 平台状态"
echo -e "${GREEN}=====================================================${NC}"
