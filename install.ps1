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

# ── Step 3b: Image Search (optional) ─────
Write-Host ""
Step "Image search setup (optional - lets bots find and share images)..."
Write-Host ""
Write-Host "  Which image search provider would you like to use?" -ForegroundColor Cyan
Write-Host "    [1] Pexels  - curated stock photos, 1 key    (pexels.com/api)" -ForegroundColor White
Write-Host "    [2] Google  - broader web results, 2 keys    (console.cloud.google.com)" -ForegroundColor White
Write-Host "    [3] None    - disable image search" -ForegroundColor White
Write-Host ""
$imgChoice = Read-Host "    Enter 1, 2, or 3"

# Strip any existing image search keys before writing new ones
$lines = Get-Content $envFile | Where-Object { $_ -notmatch '^(PEXELS_API_KEY|GOOGLE_API_KEY|GOOGLE_CX)=' }
Set-Content -Path $envFile -Value $lines -Encoding utf8

switch ($imgChoice) {
    "1" {
        $pexelsKey = Read-Host "    Enter your Pexels API key"
        if (-not [string]::IsNullOrWhiteSpace($pexelsKey)) {
            Add-Content -Path $envFile -Value "PEXELS_API_KEY=$($pexelsKey.Trim())"
            Step "Pexels API key saved."
        }
    }
    "2" {
        Info "1. Go to programmablesearchengine.google.com and create a search engine"
        Info "2. Enable 'Image search' in its settings and copy the Search Engine ID"
        Info "3. Get an API key from console.cloud.google.com (enable Custom Search API)"
        Write-Host ""
        $googleKey = Read-Host "    Enter your Google API key"
        $googleCx  = Read-Host "    Enter your Search Engine ID (cx)"
        if (-not [string]::IsNullOrWhiteSpace($googleKey) -and -not [string]::IsNullOrWhiteSpace($googleCx)) {
            Add-Content -Path $envFile -Value "GOOGLE_API_KEY=$($googleKey.Trim())"
            Add-Content -Path $envFile -Value "GOOGLE_CX=$($googleCx.Trim())"
            Step "Google Custom Search keys saved."
        }
    }
    default {
        Step "Image search disabled."
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
Info "Opening your browser automatically once the server is ready..."
Info "If it does not open, go to: http://localhost:3000"
Info "Press Ctrl+C to stop."
Write-Host ""

# Poll in background until the server responds, then open the browser
$null = Start-Job -ScriptBlock {
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 500
        try {
            $null = Invoke-WebRequest -Uri "http://localhost:3001/api/bots" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
            Start-Process "http://localhost:3000"
            return
        } catch { }
    }
}

try {
    npm run dev
} finally {
    Write-Host ""
    Step "Shutting down servers..."
    $pids = Get-NetTCPConnection -LocalPort 3000,3001 -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique
    if ($pids) {
        $pids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    }
    Step "Servers stopped. Goodbye!"
}
