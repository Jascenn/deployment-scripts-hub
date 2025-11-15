# Enhanced UTF-8 BOM Encoding Fix Tool
# Version 3.0 - Support for v4.0 files and quick-fix scripts

param(
    [switch]$Verbose,
    [switch]$All  # Fix all .ps1 files (including v4.0 and quick-fix)
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BettaFish Encoding Fix Tool v3.0" -ForegroundColor Cyan
Write-Host "  Converting to UTF-8 with BOM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define file sets
$coreFiles = @(
    "docker-deploy.ps1",
    "diagnose.ps1"
)

$v4Files = @(
    "docker-deploy-v4.ps1",
    "quick-fix.ps1"
)

$allFiles = $coreFiles + $v4Files

# Determine which files to process
if ($All) {
    Write-Host "Mode: Processing ALL PowerShell scripts" -ForegroundColor Yellow
    Write-Host "  - Core files (v3.8.3)" -ForegroundColor Gray
    Write-Host "  - v4.0 deployment script" -ForegroundColor Gray
    Write-Host "  - Quick-fix script" -ForegroundColor Gray
    Write-Host ""
    $filesToFix = $allFiles
} else {
    Write-Host "Mode: Processing CORE files only" -ForegroundColor Yellow
    Write-Host "  - docker-deploy.ps1" -ForegroundColor Gray
    Write-Host "  - diagnose.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Tip: Use -All parameter to fix v4.0 files too" -ForegroundColor Cyan
    Write-Host "     Example: .\fix-encoding-v3.ps1 -All" -ForegroundColor Cyan
    Write-Host ""
    $filesToFix = $coreFiles
}

$successCount = 0
$failCount = 0
$skipCount = 0

foreach ($fileName in $filesToFix) {
    $filePath = Join-Path $scriptDir $fileName

    if (-not (Test-Path $filePath)) {
        Write-Host "[SKIP] $fileName - File not found" -ForegroundColor Yellow
        $skipCount++
        continue
    }

    try {
        Write-Host "Processing: $fileName" -ForegroundColor Yellow

        # Read file content as raw bytes first
        $bytes = [System.IO.File]::ReadAllBytes($filePath)

        # Check if already has BOM
        $hasBOM = ($bytes.Length -ge 3) -and
                  ($bytes[0] -eq 0xEF) -and
                  ($bytes[1] -eq 0xBB) -and
                  ($bytes[2] -eq 0xBF)

        if ($hasBOM) {
            Write-Host "  [OK] Already has UTF-8 BOM" -ForegroundColor Green
            $successCount++
            Write-Host ""
            continue
        }

        # Read content as UTF-8 without BOM
        $content = [System.IO.File]::ReadAllText($filePath, [System.Text.UTF8Encoding]::new($false))

        if ($Verbose) {
            $preview = $content.Substring(0, [Math]::Min(100, $content.Length))
            Write-Host "  Content preview:" -ForegroundColor Gray
            Write-Host "  $preview..." -ForegroundColor DarkGray
        }

        # Create backup with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$filePath.backup_$timestamp"
        Copy-Item -Path $filePath -Destination $backupPath -Force
        Write-Host "  [BACKUP] Created: $fileName.backup_$timestamp" -ForegroundColor Gray

        # Write with UTF-8 BOM
        $utf8BOM = [System.Text.UTF8Encoding]::new($true)
        [System.IO.File]::WriteAllText($filePath, $content, $utf8BOM)

        # Verify BOM was added
        $newBytes = [System.IO.File]::ReadAllBytes($filePath)
        $verifyBOM = ($newBytes.Length -ge 3) -and
                     ($newBytes[0] -eq 0xEF) -and
                     ($newBytes[1] -eq 0xBB) -and
                     ($newBytes[2] -eq 0xBF)

        if ($verifyBOM) {
            Write-Host "  [SUCCESS] Converted to UTF-8 with BOM" -ForegroundColor Green

            # Verify Chinese characters render correctly
            $testContent = [System.IO.File]::ReadAllText($filePath, [System.Text.UTF8Encoding]::new($true))
            if ($testContent -match '[\u4e00-\u9fff]') {
                Write-Host "  [VERIFY] Chinese characters detected and readable" -ForegroundColor Green
            }

            $successCount++
        } else {
            Write-Host "  [WARN] BOM verification failed" -ForegroundColor Yellow
            # Restore from backup
            Copy-Item -Path $backupPath -Destination $filePath -Force
            Write-Host "  [RESTORE] File restored from backup" -ForegroundColor Yellow
            $failCount++
        }

    } catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }

    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total files checked: $($filesToFix.Count)" -ForegroundColor White
Write-Host "  Successfully converted/verified: $successCount" -ForegroundColor Green
Write-Host "  Skipped (not found): $skipCount" -ForegroundColor Gray
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "Encoding fix completed successfully!" -ForegroundColor Green
    Write-Host ""

    if ($All) {
        Write-Host "You can now run:" -ForegroundColor Cyan
        Write-Host "  - docker-deploy.bat (v3.8.3)" -ForegroundColor White
        Write-Host "  - docker-deploy-v4.bat (v4.0)" -ForegroundColor White
        Write-Host "  - quick-fix.bat (Image fix)" -ForegroundColor White
        Write-Host "  - diagnose.bat (Diagnostics)" -ForegroundColor White
    } else {
        Write-Host "You can now run:" -ForegroundColor Cyan
        Write-Host "  - docker-deploy.bat" -ForegroundColor White
        Write-Host "  - diagnose.bat" -ForegroundColor White
        Write-Host ""
        Write-Host "To fix v4.0 files, run:" -ForegroundColor Yellow
        Write-Host "  .\fix-encoding-v3.ps1 -All" -ForegroundColor White
    }
} else {
    Write-Host "No files were converted." -ForegroundColor Yellow
    if ($skipCount -eq $filesToFix.Count) {
        Write-Host "All specified files were not found." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Note: Backup files (.backup_*) have been created." -ForegroundColor Gray
Write-Host "You can delete them after verifying the scripts work correctly." -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host
