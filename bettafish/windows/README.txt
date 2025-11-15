=======================================================================
  PowerShell 脚本 - 适用于 PowerShell (.ps1)
=======================================================================

这个文件夹包含 PowerShell 脚本文件 (.ps1)

使用方法:
  1. 右键点击 .ps1 文件 -> "使用 PowerShell 运行"
  2. 或在 PowerShell 中运行: .\文件名.ps1

首次使用 PowerShell 脚本:
  如果遇到执行策略错误，请以管理员身份打开 PowerShell 运行:
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

推荐使用:
  - 如果您熟悉 PowerShell
  - 如果您需要更强大的功能和更好的错误处理
  - 如果您需要详细的部署日志和进度显示

主要脚本:
  - docker-deploy.ps1       : 一键部署脚本（推荐使用）
  - diagnose.ps1            : 系统诊断脚本
  - download-project.ps1    : 下载项目源码脚本
  - fix-docker-mirrors.ps1  : 修复 Docker 镜像源问题

优势:
  ✅ 更强大的错误处理
  ✅ 更详细的日志输出
  ✅ 更好的用户交互体验
  ✅ 支持更复杂的逻辑

=======================================================================
