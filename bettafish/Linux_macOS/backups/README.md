# 备份目录

## 用途

此目录用于存放 BettaFish 数据库和配置文件的备份。

## 推荐备份内容

### 1. 数据库备份
```bash
# 备份 PostgreSQL 数据库
docker exec bettafish-db pg_dump -U bettafish bettafish > backups/db_backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2. 配置文件备份
```bash
# 备份 .env 配置
cp BettaFish-main/.env backups/env_backup_$(date +%Y%m%d_%H%M%S).txt

# 备份 docker-compose.yml
cp BettaFish-main/docker-compose.yml backups/docker-compose_backup_$(date +%Y%m%d_%H%M%S).yml
```

### 3. 数据目录备份
```bash
# 备份数据库数据目录（停止容器后）
tar -czf backups/db_data_$(date +%Y%m%d_%H%M%S).tar.gz BettaFish-main/db_data/
```

## 自动备份脚本（推荐）

创建定时任务，每天自动备份：

```bash
# 创建备份脚本
cat > backup-daily.sh << 'EOF'
#!/bin/bash
cd /path/to/Linux_macOS
DATE=$(date +%Y%m%d)
docker exec bettafish-db pg_dump -U bettafish bettafish > backups/db_${DATE}.sql
gzip backups/db_${DATE}.sql
# 删除30天前的备份
find backups/ -name "db_*.sql.gz" -mtime +30 -delete
EOF

chmod +x backup-daily.sh

# 添加到 crontab (每天凌晨2点执行)
# crontab -e
# 0 2 * * * /path/to/Linux_macOS/backup-daily.sh
```

## 备份文件命名规范

建议使用以下命名格式：
- 数据库: `db_backup_YYYYMMDD_HHMMSS.sql`
- 配置: `env_backup_YYYYMMDD_HHMMSS.txt`
- 完整备份: `full_backup_YYYYMMDD.tar.gz`

## 恢复数据

### 恢复数据库
```bash
# 从备份恢复
docker exec -i bettafish-db psql -U bettafish bettafish < backups/db_backup_20241116.sql
```

### 恢复配置
```bash
cp backups/env_backup_20241116.txt BettaFish-main/.env
```

## 注意事项

- 🔒 备份文件可能包含敏感信息（API密钥、数据库密码等）
- 📦 定期清理旧备份，避免占用过多磁盘空间
- ☁️  建议将重要备份上传到云存储或外部存储设备
- ✅ 定期测试备份恢复流程，确保备份可用

## 快速备份命令

```bash
# 一键完整备份
tar -czf backups/full_backup_$(date +%Y%m%d).tar.gz \
  BettaFish-main/.env \
  BettaFish-main/docker-compose.yml \
  BettaFish-main/db_data/
```
