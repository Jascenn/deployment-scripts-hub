# 配置备份目录

本目录用于存储 BettaFish 的配置文件备份。

## 📁 目录用途

部署脚本会自动备份重要的配置文件到此目录，确保配置安全。

## 🔄 自动备份

在以下情况会自动创建备份：

1. **重新部署时** - 备份现有配置
2. **配置更新时** - 保留旧版本配置
3. **重要操作前** - 预防性备份

## 📄 备份文件格式

```
docker-compose_backup_20250116_143022.yml
.env_backup_20250116_143022.env
```

- 文件名包含时间戳
- 便于识别备份时间
- 按时间顺序排列

## 🔧 恢复配置

如果需要恢复备份的配置：

```powershell
# 1. 找到需要恢复的备份文件
# 2. 复制到 BettaFish-main 目录
Copy-Item "docker-compose_backup_YYYYMMDD_HHMMSS.yml" "..\BettaFish-main\docker-compose.yml"

# 3. 重启服务
cd ..\BettaFish-main
docker-compose restart
```

## 🗑️ 清理备份

定期清理旧备份，释放磁盘空间：

```powershell
# 删除 30 天前的备份
Get-ChildItem -Path . -Recurse | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item
```

## ⚠️ 注意事项

- ✅ 定期检查备份文件
- ✅ 重要操作前确认有备份
- ✅ 不要手动删除最近的备份
- ⚠️ 备份文件可能包含敏感信息（API 密钥等）
- ⚠️ 不要将备份文件分享给他人

---

**最佳实践**：每周检查一次备份，保留最近 10 个备份文件。
