# OpenClaw + NVIDIA NIM API — Windows Setup Script
# Run in PowerShell as normal user (no admin needed)

$ErrorActionPreference = "Stop"

Write-Host "=== OpenClaw Setup (Windows) ===" -ForegroundColor Cyan

# Check Node.js
$nodePath = "C:\Program Files\nodejs\node.exe"
if (-not (Test-Path $nodePath)) {
    Write-Host "ERROR: Node.js not found at $nodePath" -ForegroundColor Red
    Write-Host "Download and install from: https://nodejs.org" -ForegroundColor Yellow
    exit 1
}
$nodeVersion = & $nodePath --version
Write-Host "Node.js: $nodeVersion" -ForegroundColor Green

# Install openclaw globally
Write-Host "`nInstalling openclaw..." -ForegroundColor Cyan
& "C:\Program Files\nodejs\npm.cmd" install -g openclaw

$ocPath = "$env:APPDATA\npm\node_modules\openclaw\dist\index.js"
if (-not (Test-Path $ocPath)) {
    Write-Host "ERROR: openclaw install failed" -ForegroundColor Red
    exit 1
}
Write-Host "openclaw installed." -ForegroundColor Green

# Create config directory
$configDir = "$env:USERPROFILE\.openclaw"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

# Copy config template
$configPath = "$configDir\openclaw.json"
if (Test-Path $configPath) {
    Write-Host "`nConfig already exists at $configPath — skipping." -ForegroundColor Yellow
} else {
    Copy-Item "config-template.json" $configPath
    Write-Host "`nConfig template copied to $configPath" -ForegroundColor Green
    Write-Host "IMPORTANT: Edit that file and replace all YOUR_* placeholders before starting." -ForegroundColor Yellow
}

# Fix telegram plugin runtime deps (known issue on first install)
Write-Host "`nFixing telegram plugin runtime deps..." -ForegroundColor Cyan
& $nodePath fix-telegram-plugin.js

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit $configPath and fill in your API keys"
Write-Host "  2. Run: & '$nodePath' '$ocPath' gateway start"
Write-Host "  3. Run: & '$nodePath' '$ocPath' gateway status"
