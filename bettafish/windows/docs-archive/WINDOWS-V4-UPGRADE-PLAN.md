# Windows 版本 v4.0 升级计划

## 📋 当前状态

**版本**: v3.8.3-windows
**状态**: 基础功能完成，但与 Linux 版本差异较大

## 🎯 升级目标

将 Windows PowerShell 版本完全对齐 Linux Bash 版本的功能和用户体验。

---

## 🔄 主要变更

### 1. API 配置（重大变更）⭐⭐⭐

#### 当前实现
```powershell
- OpenAI API Key (必填)
- Firecrawl API Key (可选)
```

#### 目标实现（参考 Linux）
```powershell
- 主 API 密钥 (必填) - 用于所有 7 个引擎
- Base URL (固定): https://vibecodingapi.ai/v1
- Tavily API 密钥 (必填) - 搜索工具
- Bocha API 密钥 (必填) - 搜索工具
```

**优先级**: P0（必须）
**工作量**: 2小时

---

### 2. 镜像源管理（重大变更）⭐⭐⭐

#### 当前实现
- 硬编码使用 ghcr.io
- PostgreSQL 失败后重试 DaoCloud

#### 目标实现（参考 Linux）
- **镜像源测速**: 自动测试官方源和南京大学镜像速度
- **智能推荐**: 显示最快的镜像源
- **用户选择**: 让用户选择或使用推荐源
- **BettaFish 镜像**: 支持 ghcr.io 和 ghcr.nju.edu.cn
- **PostgreSQL 镜像**: 优先 DaoCloud，备选南京大学

**示例**:
```
ℹ️  测试镜像源网络连接速度...

测试结果:
  [1] 官方源 (ghcr.io) ... 460ms
  [2] 南京大学镜像 (ghcr.nju.edu.cn) ... 108ms

✅ 推荐镜像源: 南京大学镜像 (108ms)

请选择镜像源 [0-2] (回车默认 0):
```

**优先级**: P0（必须）
**工作量**: 3小时

---

### 3. 密钥验证和格式化（中等变更）⭐⭐

#### 当前实现
- 基础非空验证

#### 目标实现
- **格式验证**: 检查 sk-、tvly- 前缀
- **URL 误输入检测**: 防止输入 https://...
- **空格检测**: API Key 不应包含空格
- **长度验证**: 至少 10 个字符
- **格式化显示**: sk-xxx***xxx（隐藏中间部分）

**优先级**: P1（重要）
**工作量**: 1小时

---

### 4. 进度显示（小变更）⭐

#### 当前实现
- 文本步骤提示

#### 目标实现
- 百分比进度条
- 每个步骤显示进度

**示例**:
```
[==============>------------------------------------]  28%%
▶ 步骤 2/7: 检测 BettaFish 项目源码
```

**优先级**: P2（建议）
**工作量**: 30分钟

---

### 5. 环境文件配置（重大变更）⭐⭐⭐

#### 当前实现（.env）
```env
OPENAI_API_KEY=xxx
FIRECRAWL_API_KEY=xxx
POSTGRES_USER=bettafish
POSTGRES_PASSWORD=xxx
```

#### 目标实现（参考 Linux）
```env
# ================== 主 API 配置 ====================
AGENT_API_KEY=xxx
AGENT_API_BASE_URL=https://vibecodingapi.ai/v1

# ================== 7 个引擎配置 ====================
QUERY_ENGINE_API_KEY=${AGENT_API_KEY}
QUERY_ENGINE_BASE_URL=${AGENT_API_BASE_URL}

INSIGHT_ENGINE_API_KEY=${AGENT_API_KEY}
INSIGHT_ENGINE_BASE_URL=${AGENT_API_BASE_URL}

# ... (其他 5 个引擎)

# ================== 网络工具配置 ====================
TAVILY_API_KEY=xxx
BOCHA_BASE_URL=https://api.bochaai.com
BOCHA_WEB_SEARCH_API_KEY=xxx

# ================== 数据库配置 ====================
POSTGRES_USER=bettafish
POSTGRES_PASSWORD=xxx
POSTGRES_DB=bettafish_db
```

**优先级**: P0（必须）
**工作量**: 1小时

---

## 📊 工作量估算

| 任务 | 优先级 | 预计工作量 | 状态 |
|------|-------|-----------|------|
| API 配置更新 | P0 | 2h | ⏳ 待开始 |
| 镜像源管理 | P0 | 3h | ⏳ 待开始 |
| 环境文件配置 | P0 | 1h | ⏳ 待开始 |
| 密钥验证 | P1 | 1h | ⏳ 待开始 |
| 进度显示 | P2 | 0.5h | ⏳ 待开始 |
| 测试验证 | - | 1h | ⏳ 待开始 |
| 文档更新 | - | 0.5h | ⏳ 待开始 |
| **总计** | - | **9h** | |

---

## 🚀 实施计划

### 阶段 1: 核心功能对齐（P0）

**目标**: 让 Windows 版本功能与 Linux 版本完全一致

1. ✅ 更新 API 配置（3 个密钥 + Base URL）
2. ✅ 更新环境文件生成（7 个引擎配置）
3. ✅ 添加镜像源测速和选择
4. ✅ 修复 BettaFish 镜像拉取（多源支持）

**预计完成**: 6小时

---

### 阶段 2: 用户体验优化（P1-P2）

**目标**: 提升用户体验

1. ✅ 添加密钥验证和格式化
2. ✅ 添加进度百分比显示
3. ✅ 优化错误提示信息

**预计完成**: 2小时

---

### 阶段 3: 测试和文档（必需）

**目标**: 确保稳定性

1. ✅ 完整部署测试
2. ✅ 更新 README 文档
3. ✅ 更新测试指南

**预计完成**: 1小时

---

## ⚡ 快速修复方案（临时）

**如果现在就需要让 Windows 版本工作**，最快的方法：

### 方案 A: 手动拉取镜像（5分钟）

```powershell
# 使用镜像加速
docker pull docker.m.daocloud.io/postgres:15
docker tag docker.m.daocloud.io/postgres:15 postgres:15

docker pull ghcr.nju.edu.cn/jasonz93/bettafish:latest
docker tag ghcr.nju.edu.cn/jasonz93/bettafish:latest ghcr.io/jasonz93/bettafish:latest

# 重新运行部署
docker-deploy.bat
```

---

### 方案 B: 修改 .env 文件适配 Linux 版本（10分钟）

手动编辑 `.env` 文件，添加 Linux 版本需要的配置：

```env
# 添加主 API 配置
AGENT_API_KEY=sk-your-key-here
AGENT_API_BASE_URL=https://vibecodingapi.ai/v1

# 添加 7 个引擎配置
QUERY_ENGINE_API_KEY=${AGENT_API_KEY}
QUERY_ENGINE_BASE_URL=${AGENT_API_BASE_URL}
# ... (复制 Linux 版本的完整配置)

# 添加网络工具
TAVILY_API_KEY=tvly-your-key
BOCHA_WEB_SEARCH_API_KEY=sk-bocha-key
BOCHA_BASE_URL=https://api.bochaai.com
```

---

## 🎯 推荐方案

### 选项 1: 立即升级到 v4.0（推荐）

**优点**:
- 功能完整，与 Linux 版本一致
- 长期维护更简单
- 用户体验最佳

**缺点**:
- 需要 9 小时开发时间
- 需要重新测试

**适合**: 有充足时间，追求完美

---

### 选项 2: 快速修复 + 后续升级

**优点**:
- 5 分钟即可解决当前问题
- 不影响后续升级计划

**缺点**:
- 功能不完整
- 需要手动操作

**适合**: 紧急情况，需要立即部署

---

## 📝 决策建议

**建议采用**: **选项 2**（快速修复 + 后续升级）

**理由**:
1. 用户当前急需完成部署
2. 手动拉取镜像 5 分钟即可解决
3. 后续有时间再完整升级到 v4.0

**执行步骤**:
1. **现在**: 指导用户手动拉取镜像，完成部署
2. **今天**: 开始 v4.0 升级开发
3. **明天**: 发布 v4.0，让用户重新部署（可选）

---

## 🔄 兼容性考虑

### 升级路径

**v3.8.3 → v4.0**:
- ⚠️ `.env` 文件格式变化（需要重新配置）
- ⚠️ API Key 数量从 2 个变为 3 个
- ✅ 向后兼容（可以保留旧的 .env）

### 迁移指南

```powershell
# 备份旧配置
Copy-Item .env .env.v3.backup

# 重新运行 v4.0 部署脚本
docker-deploy.bat

# 或手动迁移：
# OpenAI API Key → 主 API 密钥
# 新增 Tavily 和 Bocha 密钥
```

---

## ✅ 验收标准

v4.0 版本需要满足：

1. ✅ 功能与 Linux 版本 100% 对齐
2. ✅ 镜像源测速和选择功能正常
3. ✅ 3 个 API 密钥配置正确
4. ✅ 进度显示清晰
5. ✅ 所有错误提示友好
6. ✅ 通过完整部署测试
7. ✅ 文档更新完整

---

**创建时间**: 2025-11-15
**预计完成**: 2025-11-16
**负责人**: Claude Code
**状态**: 📋 计划中
