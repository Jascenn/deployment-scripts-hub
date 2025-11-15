# 🚨 紧急修复：PowerShell 脚本语法错误

## 问题现象

运行 `docker-deploy.bat` 时看到：

```
Unexpected token '}' in expression or statement.
Unexpected token '绉?" -ForegroundColor Gray...'
The string is missing the terminator: ".
```

## 根本原因

PowerShell 脚本文件缺少 **UTF-8 BOM**（字节序标记），导致中文字符被错误解析。

## ✅ 解决方案（3 选 1）

### 方案 1: 使用增强版修复工具（推荐）

**步骤**:
```cmd
cd C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit\Windows-Version

fix-encoding-v2.bat
```

**预期输出**:
```
========================================
  BettaFish Encoding Fix Tool v2.0
  Enhanced UTF-8 BOM Conversion
========================================

Processing: docker-deploy.ps1
  [BACKUP] Created: docker-deploy.ps1.backup
  [SUCCESS] Converted to UTF-8 with BOM

Processing: diagnose.ps1
  [BACKUP] Created: diagnose.ps1.backup
  [SUCCESS] Converted to UTF-8 with BOM

========================================
  Summary
========================================

  Total files processed: 2
  Successfully converted: 2
  Failed: 0

Encoding fix completed successfully!
You can now run docker-deploy.bat or diagnose.bat
```

---

### 方案 2: 使用 Notepad++ 手动转换（最可靠）

如果你有 Notepad++：

**步骤**:
1. 用 Notepad++ 打开 `docker-deploy.ps1`
2. 菜单: **编码** → **转为 UTF-8-BOM 编码**
3. 保存文件（Ctrl+S）
4. 重复步骤 1-3 处理 `diagnose.ps1`
5. 完成！

**下载 Notepad++**:
https://notepad-plus-plus.org/downloads/

---

### 方案 3: 使用 PowerShell 命令手动转换

如果其他方法都失败，使用这个命令：

```powershell
# 转换 docker-deploy.ps1
$content = Get-Content "docker-deploy.ps1" -Raw -Encoding UTF8
$utf8BOM = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText("$PWD\docker-deploy.ps1", $content, $utf8BOM)

# 转换 diagnose.ps1
$content = Get-Content "diagnose.ps1" -Raw -Encoding UTF8
[System.IO.File]::WriteAllText("$PWD\diagnose.ps1", $content, $utf8BOM)

Write-Host "Conversion completed!" -ForegroundColor Green
```

---

## 🔍 验证修复成功

### 方法 1: 运行诊断工具

```cmd
diagnose.bat
```

**成功标志**: 看到中文正常显示，没有乱码：
```
BettaFish 诊断工具 v1.0.0-windows
自动检测部署环境和运行状态

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 1. 环境检查
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[✓] PowerShell 5.1
```

### 方法 2: 检查文件编码

```powershell
# 读取文件前 3 个字节
$bytes = [System.IO.File]::ReadAllBytes("docker-deploy.ps1")
$bytes[0..2]
```

**预期输出**: `239 187 191` (即 UTF-8 BOM: EF BB BF)

如果看到其他数字，说明转换失败。

---

## 🎯 完整部署流程

修复编码后，按以下步骤部署：

### 步骤 1: 修复编码
```cmd
fix-encoding-v2.bat
```

### 步骤 2: 验证修复
```cmd
diagnose.bat
```

看到中文正常显示 = 修复成功 ✅

### 步骤 3: 确保 Docker 运行

检查右下角 Docker 图标：
- ✅ 绿色 = 已启动
- 🔄 动画 = 启动中（等待）
- ❌ 灰色 = 未启动（手动启动）

### 步骤 4: 下载项目源码

如果还没下载 BettaFish-main：

```
访问: https://github.com/JasonZ93/BettaFish
下载: Code → Download ZIP
解压到: Windows-Version/BettaFish-main/
```

详细说明：[SETUP-PROJECT.md](SETUP-PROJECT.md)

### 步骤 5: 开始部署

```cmd
docker-deploy.bat
```

当询问 Docker 状态时：
```
请选择操作:
  1. 我已经手动启动了 Docker Desktop，继续检测
  2. 让脚本自动启动 Docker Desktop
  3. 退出脚本，稍后重试

请输入选项 (1/2/3): 1  ← 输入 1
```

---

## ❓ 常见问题

### Q1: fix-encoding-v2.bat 也报错？

**现象**: 运行 fix-encoding-v2.bat 也出现编码错误

**原因**: fix-encoding-v2.ps1 本身也需要转换

**解决**: 使用方案 2（Notepad++）或方案 3（PowerShell 命令）

---

### Q2: 转换后仍然报错？

**可能原因**:
1. 文件在 OneDrive 同步中被锁定
2. 文件被其他程序打开
3. 权限不足

**解决步骤**:

**步骤 1**: 关闭所有可能打开这些文件的程序
- Visual Studio Code
- Notepad++
- PowerShell ISE
- 等

**步骤 2**: 复制到本地磁盘
```cmd
xcopy /E /I "C:\Users\12863\OneDrive\Downloads\BettaFish-Deployment-Kit" "C:\BettaFish-Deployment-Kit"

cd C:\BettaFish-Deployment-Kit\Windows-Version

fix-encoding-v2.bat
```

**步骤 3**: 重新尝试转换

---

### Q3: 为什么会有这个问题？

**技术原因**:

1. **跨平台开发**
   - 脚本在 macOS/Linux 环境开发
   - 默认使用 UTF-8 without BOM
   - Windows PowerShell 5.1 需要 BOM

2. **编码差异**
   ```
   UTF-8 without BOM: [文件内容...]
   UTF-8 with BOM:    [EF BB BF][文件内容...]
                      ^^^^^^^^^ 前 3 个字节是 BOM
   ```

3. **PowerShell 行为**
   - PowerShell 5.1: 需要 BOM 识别 UTF-8
   - PowerShell 7+: 不需要 BOM（自动识别）

**长期解决方案**: 升级到 PowerShell 7，但考虑兼容性，我们仍支持 5.1

---

## 📞 需要帮助？

如果以上方法都失败：

### 选项 1: 提供详细错误信息

```powershell
# 运行诊断并保存输出
diagnose.bat > diagnosis.txt 2>&1

# 查看 diagnosis.txt 并提交问题
```

### 选项 2: 使用备用脚本

创建一个临时测试脚本 `test.ps1`：

```powershell
Write-Host "如果你能看到这行中文，说明你的 PowerShell 编码正常" -ForegroundColor Green
Write-Host "PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "当前编码: $([Console]::OutputEncoding.EncodingName)" -ForegroundColor Yellow
Read-Host "按回车退出"
```

保存为 UTF-8 with BOM，然后运行：
```cmd
powershell -ExecutionPolicy Bypass -File test.ps1
```

如果这个能正常显示中文，说明问题在于主脚本文件的编码。

---

## ✅ 成功标志

修复成功后，你应该看到：

```
  _      ___ ___  _   _  ____ ____       _    ___
 | |    |_ _/ _ \| \ | |/ ___/ ___|     / \  |_ _|
 | |     | | | | |  \| | |  | |        / _ \  | |
 | |___  | | |_| | |\  | |__| |___  _ / ___ \ | |
 |_____||___\___/|_| \_|\____\____|(_)_/   \_\___|

       🐟 BettaFish Docker 一键部署
        Windows 版本 v3.8.3-windows
        Powered by LIONCC.AI - 2025

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ 步骤 1/7: 环境检测与依赖检查
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  PowerShell 版本: 5.1
ℹ️  检测 Docker Desktop...
✅ Docker 已安装: Docker version 28.5.1
```

**所有中文正常显示，没有乱码** = 成功！ 🎉

---

**版本**: v3.8.4
**更新**: 2025-11-15
**优先级**: 🚨 高（必须先解决编码问题才能继续部署）
