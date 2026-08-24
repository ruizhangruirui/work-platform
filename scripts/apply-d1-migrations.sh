#!/usr/bin/env bash
#
# apply-d1-migrations.sh — 一键将 drizzle/ 下的迁移应用到远程 Cloudflare D1 数据库
#
# 用法:
#   bash scripts/apply-d1-migrations.sh                  # 默认数据库 site-creator-d1
#   bash scripts/apply-d1-migrations.sh <数据库名>        # 指定其他数据库
#   bash scripts/apply-d1-migrations.sh --yes            # 跳过确认提示
#   D1_DATABASE_NAME=xxx D1_DATABASE_ID=xxx bash scripts/apply-d1-migrations.sh
#
# 非交互环境(CI): 设置 CLOUDFLARE_API_TOKEN(需 D1 编辑权限)即可跳过浏览器登录。
#
set -euo pipefail

# ---------- 输出样式 ----------
if [ -t 1 ]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''; C_RESET=''
fi
step() { printf '\n%s[%s/6]%s %s\n' "$C_BLUE" "$1" "$C_RESET" "$2"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
die()  { printf '%s✗ 错误:%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; exit 1; }
info() { printf '%s%s%s\n' "$C_DIM" "$1" "$C_RESET"; }

# ---------- 参数 ----------
ASSUME_YES=0
DB_NAME="${D1_DATABASE_NAME:-}"
for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --help|-h)
      sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    --*) die "未知参数: $arg(用 --help 查看用法)" ;;
    *) [ -z "$DB_NAME" ] && DB_NAME="$arg" || die "只能指定一个数据库名" ;;
  esac
done
DB_NAME="${DB_NAME:-site-creator-d1}"

# ---------- 开场:步骤与所需输入 ----------
cat <<EOF
${C_BLUE}=====================================================${C_RESET}
${C_BLUE} 团队工作台 · D1 远程迁移一键脚本${C_RESET}
${C_BLUE}=====================================================${C_RESET}

本脚本将依次执行:
  1) 检查环境(Node.js 与 wrangler)
  2) 登录 Cloudflare 账号
  3) 定位 D1 数据库(默认: ${DB_NAME})
  4) 查看待执行的迁移(drizzle/ 目录)
  5) 应用迁移到远程数据库(--remote)
  6) 验证 audit_logs.case_id 列与 audit_case_idx 索引已生效

开始前请准备:
  · Cloudflare 账号,且目标 D1 数据库在该账号下
    (没有账号? 到 https://dash.cloudflare.com/sign-up 免费注册)
  · Node.js 18 或以上(首次运行 npx 会自动安装 wrangler,需联网)
  · 登录方式二选一:
      - 交互登录: 脚本会自动打开浏览器完成授权(本地使用,推荐)
      - API Token: 设置 CLOUDFLARE_API_TOKEN 环境变量(CI/服务器适用,
        Token 需具备 D1 编辑权限, 在 dash.cloudflare.com/profile/api-tokens 创建)

EOF

# ---------- 0. 定位仓库根目录 ----------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[ -d drizzle ] || die "未找到 drizzle/ 迁移目录,请在本仓库根目录下运行"
ls drizzle/*.sql >/dev/null 2>&1 || die "drizzle/ 目录下没有迁移文件"
WRANGLER=(npx wrangler)

# ---------- 1. 环境检查 ----------
step 1 "检查环境(Node.js / wrangler)"
command -v node >/dev/null 2>&1 || die "未找到 node,请先安装 Node.js 18+: https://nodejs.org"
command -v npx  >/dev/null 2>&1 || die "未找到 npx,请确认 Node.js 安装完整"
ok "node $(node -v)"
info "wrangler 将通过 npx 调用(优先使用仓库锁定的版本,首次运行会自动下载)"

# ---------- 2. Cloudflare 登录 ----------
step 2 "登录 Cloudflare 账号"
if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
  ok "检测到 CLOUDFLARE_API_TOKEN,跳过浏览器登录"
elif "${WRANGLER[@]}" whoami >/dev/null 2>&1; then
  ok "已登录 Cloudflare"
else
  warn "尚未登录,即将打开浏览器授权(完成后回到终端即可)"
  info "如果你的环境没有浏览器,请按 Ctrl+C 退出,改用 CLOUDFLARE_API_TOKEN 方式"
  "${WRANGLER[@]}" login || die "wrangler 登录失败,请重试或改用 CLOUDFLARE_API_TOKEN"
  "${WRANGLER[@]}" whoami >/dev/null 2>&1 || die "登录状态校验失败,请重试"
  ok "登录成功"
fi

# ---------- 3. 定位 D1 数据库 ----------
step 3 "定位 D1 数据库"
DB_ID="${D1_DATABASE_ID:-}"
LIST_JSON="$("${WRANGLER[@]}" d1 list --json 2>/dev/null || true)"

if [ -z "$DB_ID" ] && [ -n "$LIST_JSON" ]; then
  PARSED="$(printf '%s' "$LIST_JSON" | node -e '
    let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      try{
        const j=JSON.parse(s);
        const rows=(Array.isArray(j)?j:[]).map(x=>({name:x.name,id:x.uuid||x.id}));
        console.log(JSON.stringify(rows));
      }catch(e){ process.exit(1); }
    });' 2>/dev/null || echo '[]')"
  [ "$PARSED" = "[]" ] && warn "未能解析数据库列表,将直接进入手动确认"

  DB_ID="$(printf '%s' "$PARSED" | DB_NAME="$DB_NAME" node -e '
    let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      const rows=JSON.parse(s||"[]");
      const hit=rows.find(r=>r.name===process.env.DB_NAME);
      if(hit) console.log(hit.id);
    });' 2>/dev/null || true)"

  if [ -z "$DB_ID" ]; then
    warn "账号下未找到名为「${DB_NAME}」的数据库。当前账号的 D1 数据库:"
    printf '%s' "$PARSED" | node -e '
      let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
        const rows=JSON.parse(s||"[]");
        if(!rows.length){ console.log("    (空——此账号还没有任何 D1 数据库)"); return; }
        rows.forEach((r,i)=>console.log(`    ${i+1}) ${r.name}  (${r.id})`));
      });'
    echo
    printf '请输入要使用的数据库名(直接回车 = 新建 %s): ' "$DB_NAME"
    read -r PICK </dev/tty || PICK=""
    if [ -z "$PICK" ]; then
      info "正在创建数据库 ${DB_NAME} ..."
      CREATE_OUT="$("${WRANGLER[@]}" d1 create "$DB_NAME" 2>&1)" || die "创建失败: $CREATE_OUT"
      echo "$CREATE_OUT"
      DB_ID="$(printf '%s' "$CREATE_OUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)"
      [ -n "$DB_ID" ] || die "未能从创建输出中解析 database_id,请改用 D1_DATABASE_ID 环境变量重试"
      ok "已创建数据库 ${DB_NAME}(${DB_ID})"
      warn "请把该 database_id 填回你的部署配置(dist/server/wrangler.json 目前是占位符)"
    else
      DB_NAME="$PICK"
      DB_ID="$(printf '%s' "$PARSED" | DB_NAME="$DB_NAME" node -e '
        let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
          const rows=JSON.parse(s||"[]");
          const hit=rows.find(r=>r.name===process.env.DB_NAME);
          if(hit) console.log(hit.id);
        });' 2>/dev/null || true)"
      [ -n "$DB_ID" ] || die "未找到数据库「${DB_NAME}」,请检查名称后重试"
    fi
  fi
fi
[ -n "$DB_ID" ] || die "无法确定 database_id,请用 D1_DATABASE_NAME / D1_DATABASE_ID 环境变量显式指定"
ok "目标数据库: ${DB_NAME}(${DB_ID})"

# ---------- 生成临时 wrangler 配置(告诉 wrangler 迁移在 drizzle/ 目录) ----------
CFG="$ROOT/.wrangler-d1-migrate.toml"
trap 'rm -f "$CFG"' EXIT
cat > "$CFG" <<EOF
name = "team-workbench-migrations"
compatibility_date = "2026-05-15"

[[d1_databases]]
binding = "DB"
database_name = "$DB_NAME"
database_id = "$DB_ID"
migrations_dir = "drizzle"
EOF

# ---------- 4. 查看待执行迁移 ----------
step 4 "查看待执行的迁移"
PENDING="$("${WRANGLER[@]}" d1 migrations list "$DB_NAME" --remote -c "$CFG" 2>&1 || true)"
echo "$PENDING"
if printf '%s' "$PENDING" | grep -q '\.sql'; then
  warn "以上迁移将被应用到远程数据库"
else
  ok "没有待执行的迁移(数据库已是最新),直接进入验证步骤"
fi

# ---------- 5. 应用迁移 ----------
step 5 "应用迁移到远程数据库(--remote)"
if printf '%s' "$PENDING" | grep -q '\.sql'; then
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf '确认将以上迁移应用到远程数据库 %s ? [y/N] ' "$DB_NAME"
    read -r CONFIRM </dev/tty || CONFIRM=""
    case "$CONFIRM" in
      y|Y|yes|YES) ;;
      *) die "已取消,未做任何修改" ;;
    esac
  fi
  # 管道输入 y 用于应答 wrangler 自身的确认提示
  yes | "${WRANGLER[@]}" d1 migrations apply "$DB_NAME" --remote -c "$CFG" \
    || die "迁移执行失败,请查看上方 wrangler 输出"
  ok "迁移已应用"
else
  info "跳过(无待执行迁移)"
fi

# ---------- 6. 验证 ----------
step 6 "验证 audit_logs.case_id 列与 audit_case_idx 索引"
d1_rows() { # $1 = SQL,输出查询结果行数(无法解析输出 -1)
  local out
  out="$("${WRANGLER[@]}" d1 execute "$DB_NAME" --remote -c "$CFG" --json --command "$1" 2>/dev/null || true)"
  printf '%s' "$out" | node -e '
    let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      try{
        const j=JSON.parse(s);
        const r=Array.isArray(j)?(j[0]&&j[0].results)||[]:(j.results||[]);
        console.log(r.length);
      }catch(e){ console.log("-1"); }
    });'
}

FAILED=0
COL_ROWS="$(d1_rows "SELECT name FROM pragma_table_info('audit_logs') WHERE name = 'case_id'")"
if [ "$COL_ROWS" = "1" ]; then
  ok "列存在: audit_logs.case_id"
else
  warn "未确认到 audit_logs.case_id 列(查询返回 ${COL_ROWS} 行)"
  FAILED=1
fi

IDX_ROWS="$(d1_rows "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'audit_case_idx'")"
if [ "$IDX_ROWS" = "1" ]; then
  ok "索引存在: audit_case_idx (case_id, created_at)"
else
  warn "未确认到 audit_case_idx 索引(查询返回 ${IDX_ROWS} 行)"
  FAILED=1
fi

# 回填情况统计(信息项,不影响结果)
info "回填统计(总数 / case_id 为空的行数):"
"${WRANGLER[@]}" d1 execute "$DB_NAME" --remote -c "$CFG" --command \
  "SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE case_id IS NULL) AS null_case_id FROM audit_logs" \
  2>/dev/null || warn "统计查询失败(不影响迁移结果)"

echo
if [ "$FAILED" -eq 0 ]; then
  printf '%s=====================================================%s\n' "$C_GREEN" "$C_RESET"
  printf '%s ✅ 迁移完成并已验证通过%s\n' "$C_GREEN" "$C_RESET"
  printf '%s=====================================================%s\n' "$C_GREEN" "$C_RESET"
  cat <<EOF

后续步骤:
  1. 合并 Pull Request(optimization/p0-p2 → main)
  2. 重新部署应用代码(迁移已先行,顺序正确)
  3. 若 worker 可被直接访问,记得配置 AUTH_PROXY_SECRET(见 README)
EOF
else
  die "验证未通过:迁移可能未成功,请把上方输出贴出来排查"
fi
