# 🔧 编码修复 - 快速参考

## ⚡ 一句话解决

如果看到**中文乱码**，运行：

```cmd
fix-all.bat
```

就这么简单！

---

## 📋 工具清单

| 工具 | 用途 | 何时使用 |
|------|------|---------|
| **fix-all.bat** | 一键修复所有文件 | ⭐ **推荐首选** |
| fix-encoding.bat | 交互式选择修复 | 只想修复部分文件 |

---

## 🎯 常见场景

### 场景 1: 首次使用，看到乱码

```cmd
fix-all.bat
```

### 场景 2: 编辑了脚本后

```cmd
fix-all.bat
```

### 场景 3: 升级到 v4.0

```cmd
fix-all.bat
```

### 场景 4: 不确定有没有问题

```cmd
fix-all.bat
```

**结论**: 任何时候不确定，就运行 `fix-all.bat`！

---

## ✅ 修复成功的标志

运行后看到：

```
  Total files checked: 4
  Successfully converted/verified: 4
  Failed: 0

✅ Encoding fix completed successfully!
```

---

## ❌ 乱码的表现

### 表现 1: 方块或问号
```
配置 API �钥
请输入 OpenAI API Key: (���)
```

### 表现 2: 奇怪的字符
```
涓�閿�ㄧ讲
鐜娴嬫祴
```

### 表现 3: 脚本报错
```
The string is missing the terminator: ".
```

**解决方法**: `fix-all.bat`

---

## 📚 详细文档

需要更多信息？查看:

- **[ENCODING-FIX-GUIDE.md](ENCODING-FIX-GUIDE.md)** - 完整使用指南
- **[ENCODING-FIX-UPGRADED.md](ENCODING-FIX-UPGRADED.md)** - 升级说明

---

## 💡 小提示

1. ✅ 可以多次运行 `fix-all.bat`，安全无副作用
2. ✅ 自动创建备份，不用担心文件损坏
3. ✅ 修复成功后可以删除 `.backup_*` 文件
4. ✅ 编辑脚本后记得重新运行

---

**版本**: v3.0 | **最后更新**: 2025-11-15
