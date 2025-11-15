# 📝 PowerShell 编码规则说明

## 🎯 核心规则

### UTF-8 BOM vs UTF-8 without BOM

| 文件特征 | 编码格式 | 原因 |
|---------|---------|------|
| **有 `#Requires` 指令** | UTF-8 **without BOM** | PowerShell 要求 #Requires 必须是第一行，BOM 会导致识别失败 |
| **无 `#Requires` 指令** | UTF-8 **with BOM** | Windows PowerShell 5.1 需要 BOM 来正确识别中文字符 |

---

## 📋 文件清单

### Windows-Version 目录中的 PowerShell 文件

| 文件 | #Requires | 编码格式 | 状态 |
|------|-----------|---------|------|
| `docker-deploy.ps1` | ✅ 有 | UTF-8 without BOM | ✅ |
| `diagnose.ps1` | ✅ 有 | UTF-8 without BOM | ✅ |
| `quick-fix.ps1` | ✅ 有 | UTF-8 without BOM | ✅ |
| `docker-deploy-v4.ps1` | ❌ 无 | UTF-8 with BOM | ✅ |
| `fix-encoding.ps1` | ❌ 无 | UTF-8 with BOM | ✅ |
| `download-project.ps1` | ❌ 无 | UTF-8 with BOM | ✅ |

---

## 🔍 如何检查文件编码

### 方法 1: 使用 PowerShell

```powershell
# 检查是否有 BOM
$bytes = [System.IO.File]::ReadAllBytes("script.ps1")
$hasBOM = ($bytes.Length -ge 3) -and
          ($bytes[0] -eq 0xEF) -and
          ($bytes[1] -eq 0xBB) -and
          ($bytes[2] -eq 0xBF)

if ($hasBOM) {
    Write-Host "UTF-8 with BOM"
} else {
    Write-Host "UTF-8 without BOM"
}
```

### 方法 2: 使用 VS Code

1. 打开文件
2. 查看右下角状态栏
3. 会显示 "UTF-8" 或 "UTF-8 with BOM"

---

## ⚠️ 常见问题

### 问题 1: #Requires 指令不被识别

**错误信息**:
```
﻿#Requires : 无法将"﻿#Requires"项识别为 cmdlet
```

**原因**: 文件有 BOM，但包含 `#Requires` 指令

**解决**:
```powershell
# 读取文件并去除 BOM
$content = Get-Content "script.ps1" -Raw -Encoding UTF8
$content | Out-File "script.ps1" -Encoding UTF8 -NoNewline
```

---

### 问题 2: 中文显示为乱码

**表现**:
```
涓�閿�ㄧ讲
鐜娴嬫祴
```

**原因**: 文件没有 BOM，但包含中文字符

**解决**:
```powershell
# 读取文件并添加 BOM
$content = Get-Content "script.ps1" -Raw -Encoding UTF8
$utf8BOM = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText("script.ps1", $content, $utf8BOM)
```

---

## 🛠️ 编辑器配置

### VS Code

**推荐配置** (`.vscode/settings.json`):

```json
{
  "files.encoding": "utf8",
  "[powershell]": {
    "files.encoding": "utf8"
  }
}
```

**手动设置编码**:
1. 点击右下角编码显示（如 "UTF-8"）
2. 选择 "Save with Encoding"
3. 根据文件类型选择:
   - 有 `#Requires` → "UTF-8"
   - 无 `#Requires` → "UTF-8 with BOM"

---

### Notepad++

1. 菜单: Encoding → UTF-8
2. **不要** 选择 "UTF-8-BOM"（对于有 #Requires 的文件）
3. **选择** "UTF-8-BOM"（对于无 #Requires 的文件）

---

## 📚 技术细节

### UTF-8 BOM 是什么？

**BOM (Byte Order Mark)**: 文件开头的 3 个字节标记
- 十六进制: `EF BB BF`
- 作用: 告诉程序这是 UTF-8 编码的文件

### 为什么 #Requires 不能有 BOM？

PowerShell 的 `#Requires` 指令是一个特殊的元数据指令，必须是文件的**第一行**。如果文件有 BOM：

1. BOM 字节 (`EF BB BF`) 在文件开头
2. PowerShell 看到的"第一行"实际上是 BOM + `#Requires`
3. PowerShell 无法识别这个指令
4. 导致错误: "无法将'﻿#Requires'项识别为 cmdlet"

### 为什么中文需要 BOM？

Windows PowerShell 5.1 在没有 BOM 的情况下：
1. 将 UTF-8 文件误认为 ANSI/GBK 编码
2. 中文字符解析错误
3. 显示为乱码

添加 BOM 后：
1. PowerShell 正确识别为 UTF-8
2. 中文字符正常显示

---

## ✅ 验收检查

### 检查清单

运行以下命令验证所有文件编码正确：

```powershell
$files = @(
    "docker-deploy.ps1",
    "diagnose.ps1",
    "quick-fix.ps1",
    "docker-deploy-v4.ps1",
    "fix-encoding.ps1"
)

foreach ($file in $files) {
    $firstLine = Get-Content $file -First 1
    $hasRequires = $firstLine -match "^#Requires"

    $bytes = [System.IO.File]::ReadAllBytes($file)
    $hasBOM = ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)

    $status = if ($hasRequires -and $hasBOM) {
        "❌ ERROR"
    } elseif ($hasRequires -and -not $hasBOM) {
        "✅ OK (no BOM)"
    } elseif (-not $hasRequires -and $hasBOM) {
        "✅ OK (BOM)"
    } else {
        "⚠️  No BOM, no #Requires"
    }

    Write-Host "$file : $status"
}
```

**预期输出**:
```
docker-deploy.ps1 : ✅ OK (no BOM)
diagnose.ps1 : ✅ OK (no BOM)
quick-fix.ps1 : ✅ OK (no BOM)
docker-deploy-v4.ps1 : ✅ OK (BOM)
fix-encoding.ps1 : ✅ OK (BOM)
```

---

## 🔄 自动修复

我们已经创建了 `fix-encoding.ps1` 工具，但它需要更新以处理 `#Requires` 指令。

**当前状态**: 所有文件已手动修复
**未来改进**: 更新 `fix-encoding.ps1` 自动检测 `#Requires` 并相应处理

---

## 📖 参考资料

- [PowerShell about_Requires](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires)
- [UTF-8 BOM 说明](https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8)
- [PowerShell 编码最佳实践](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/understanding-file-encoding)

---

**版本**: v1.0
**创建日期**: 2025-11-15
**状态**: ✅ 所有文件编码已验证
