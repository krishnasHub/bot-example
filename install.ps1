# Bot Group Chat - Setup Script (Windows PowerShell)

$ErrorActionPreference = "Stop"

function Step($msg)  { Write-Host "[+] $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Err($msg)   { Write-Host "[x] $msg" -ForegroundColor Red }
function Info($msg)  { Write-Host "    $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Bot Group Chat - Setup Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Node.js ───────────────────────
Step "Checking for Node.js..."

$nodeInstalled = $null -ne (Get-Command node -ErrorAction SilentlyContinue)

if ($nodeInstalled) {
    Step "Node.js already installed: $(node --version)"
} else {
    Warn "Node.js not found. Installing now..."

    $wingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

    if ($wingetAvailable) {
        Step "Installing Node.js LTS via winget..."
        winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements

        # Refresh PATH so node is available in this session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")

        Step "Node.js installed: $(node --version)"
    } else {
        Err "Could not install Node.js automatically."
        Err "Please download and install it from: https://nodejs.org"
        Err "Then re-run this script."
        exit 1
    }
}

# ── Step 2: Dependencies ──────────────────
Write-Host ""
Step "Installing root dependencies..."
npm install --silent

Step "Installing server dependencies..."
npm install --prefix server --silent

Step "Installing client dependencies..."
npm install --prefix client --silent

Step "All dependencies installed."

# ── Step 3: API Key ───────────────────────
Write-Host ""
Step "Checking API key setup..."

$envFile = "server\.env"
$envExample = "server\.env.example"
$needsKey = $true

if (Test-Path $envFile) {
    $content = Get-Content $envFile -Raw -ErrorAction SilentlyContinue
    if ($content -and -not $content.Contains("your_api_key_here")) {
        Step "API key already configured."
        $needsKey = $false
    }
}

if ($needsKey) {
    Warn "An Anthropic API key is required to run the bots."
    Info "Get your free key at: https://console.anthropic.com"
    Write-Host ""
    $apiKey = Read-Host "    Enter your Anthropic API key"

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Warn "No key entered. You can add it later by editing server\.env"
        Copy-Item $envExample $envFile
    } else {
        $content = Get-Content $envExample -Raw
        $content = $content -replace "your_api_key_here", $apiKey.Trim()
        Set-Content -Path $envFile -Value $content -Encoding utf8
        Step "API key saved to server\.env"
    }
}

# ── Step 4: Free ports ───────────────────
Write-Host ""
Step "Checking for processes on ports 3000 and 3001..."
$pids = Get-NetTCPConnection -LocalPort 3000,3001 -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique
if ($pids) {
    $pids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    Step "Cleared existing processes on ports 3000/3001."
}

# ── Step 5: Launch ────────────────────────
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Setup complete! Launching..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Step "Starting server...  http://localhost:3001"
Step "Starting client...  http://localhost:3000"
Write-Host ""
Info "Open http://localhost:3000 in your browser to use the app."
Info "Press Ctrl+C to stop."
Write-Host ""

npm run dev
