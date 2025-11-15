#Requires -Version 5.1

<#
.SYNOPSIS
    BettaFish Quick Fix - Manual Image Pull
.DESCRIPTION
    Manually pull Docker images using mirror sources to bypass network issues
#>

$ErrorActionPreference = "Stop"

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "  BettaFish Quick Fix Tool" "Cyan"
Write-ColorText "  Manual Docker Image Pull" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

# Check Docker
Write-ColorText "Checking Docker Desktop..." "Yellow"
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not running"
    }
    Write-ColorText "Docker is running: $dockerVersion" "Green"
} catch {
    Write-ColorText "Error: Docker Desktop is not running" "Red"
    Write-Host ""
    Write-ColorText "Please start Docker Desktop first, then run this script again." "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "  Step 1/2: Pull PostgreSQL Image" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

# Check if PostgreSQL image already exists
$postgresExists = docker images postgres:15 --format "{{.Repository}}" 2>$null | Select-Object -First 1

if ($postgresExists -eq "postgres") {
    Write-ColorText "PostgreSQL image already exists, skipping..." "Green"
} else {
    Write-ColorText "Pulling PostgreSQL from DaoCloud mirror..." "Yellow"
    Write-Host ""

    docker pull docker.m.daocloud.io/postgres:15

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorText "Tagging image as postgres:15..." "Yellow"
        docker tag docker.m.daocloud.io/postgres:15 postgres:15

        Write-ColorText "Removing temporary image..." "Gray"
        docker rmi docker.m.daocloud.io/postgres:15 2>$null | Out-Null

        Write-Host ""
        Write-ColorText "PostgreSQL image ready!" "Green"
    } else {
        Write-ColorText "Failed to pull PostgreSQL from DaoCloud" "Red"
        Write-Host ""
        Write-ColorText "Trying NJU mirror..." "Yellow"

        docker pull docker.nju.edu.cn/postgres:15

        if ($LASTEXITCODE -eq 0) {
            docker tag docker.nju.edu.cn/postgres:15 postgres:15
            docker rmi docker.nju.edu.cn/postgres:15 2>$null | Out-Null
            Write-ColorText "PostgreSQL image ready (NJU mirror)!" "Green"
        } else {
            Write-ColorText "Failed to pull PostgreSQL from all sources" "Red"
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
}

Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "  Step 2/2: Pull BettaFish Image" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

# Check if BettaFish image already exists
$bettafishExists = docker images ghcr.io/jasonz93/bettafish:latest --format "{{.Repository}}" 2>$null | Select-Object -First 1

if ($bettafishExists -eq "ghcr.io/jasonz93/bettafish") {
    Write-ColorText "BettaFish image already exists, skipping..." "Green"
} else {
    Write-ColorText "Pulling BettaFish from NJU mirror..." "Yellow"
    Write-Host ""

    docker pull ghcr.nju.edu.cn/666ghj/bettafish:latest

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorText "Tagging image as ghcr.io/jasonz93/bettafish:latest..." "Yellow"
        docker tag ghcr.nju.edu.cn/666ghj/bettafish:latest ghcr.io/jasonz93/bettafish:latest

        Write-Host ""
        Write-ColorText "BettaFish image ready!" "Green"
    } else {
        Write-ColorText "Failed to pull BettaFish from NJU mirror" "Red"
        Write-Host ""
        Write-ColorText "Trying official source (may be slow)..." "Yellow"

        docker pull ghcr.io/jasonz93/bettafish:latest

        if ($LASTEXITCODE -eq 0) {
            Write-ColorText "BettaFish image ready (official source)!" "Green"
        } else {
            Write-ColorText "Failed to pull BettaFish from all sources" "Red"
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
}

Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "  Verification" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

Write-ColorText "Checking downloaded images..." "Yellow"
Write-Host ""

docker images | Select-String -Pattern "postgres|bettafish"

Write-Host ""
Write-ColorText "========================================" "Green"
Write-ColorText "  Quick Fix Completed!" "Green"
Write-ColorText "========================================" "Green"
Write-Host ""

Write-ColorText "Next steps:" "Cyan"
Write-ColorText "  1. Run docker-deploy.bat to continue deployment" "White"
Write-ColorText "  2. The script will detect existing images and skip pulling" "Gray"
Write-Host ""

Read-Host "Press Enter to exit"
