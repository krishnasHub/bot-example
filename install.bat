@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Bot Group Chat - Setup Script
echo ========================================
echo.

:: ── Step 1: Check / Install Node.js ──────
echo [+] Checking for Node.js...

node --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f %%v in ('node --version') do echo [+] Node.js already installed: %%v
    goto :install_deps
)

echo [!] Node.js not found. Attempting to install automatically...
echo.

:: Try winget (available on Windows 10/11)
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Installing Node.js LTS via winget...
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 goto :manual_node

    :: Try refreshing PATH
    set "PATH=%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm"

    node --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo [!] Node.js was installed but this window needs to be restarted.
        echo     Please close this window, open a new Command Prompt, and run install.bat again.
        echo.
        pause
        exit /b 1
    )
    for /f %%v in ('node --version') do echo [+] Node.js installed: %%v
    goto :install_deps
)

:manual_node
echo [!] Could not install Node.js automatically.
echo.
echo     Please do the following:
echo       1. Open this link in your browser: https://nodejs.org
echo       2. Click the green "LTS" download button
echo       3. Run the downloaded installer (keep all default settings)
echo       4. Once installed, close this window, open a new Command Prompt,
echo          and run install.bat again.
echo.
pause
exit /b 1

:: ── Step 2: Install Dependencies ─────────
:install_deps
echo.
echo [+] Installing dependencies (this may take a minute)...

call npm install
if %errorlevel% neq 0 (
    echo [x] Failed to install root dependencies. See errors above.
    pause & exit /b 1
)

call npm install --prefix server
if %errorlevel% neq 0 (
    echo [x] Failed to install server dependencies. See errors above.
    pause & exit /b 1
)

call npm install --prefix client
if %errorlevel% neq 0 (
    echo [x] Failed to install client dependencies. See errors above.
    pause & exit /b 1
)

echo [+] All dependencies installed.

:: ── Step 3: API Key ───────────────────────
echo.
echo [+] Checking API key setup...

set NEEDS_KEY=1
if exist "server\.env" (
    findstr /c:"your_api_key_here" "server\.env" >nul 2>&1
    if %errorlevel% neq 0 (
        echo [+] API key already configured.
        set NEEDS_KEY=0
    )
)

if "!NEEDS_KEY!"=="1" (
    echo [!] An Anthropic API key is required to run the bots.
    echo     Get your free key at: https://console.anthropic.com
    echo.
    set /p API_KEY=    Enter your Anthropic API key:

    if "!API_KEY!"=="" (
        echo [!] No key entered. You can add it later by editing server\.env
        copy server\.env.example server\.env >nul
    ) else (
        (echo ANTHROPIC_API_KEY=!API_KEY!) > server\.env
        echo [+] API key saved to server\.env
    )
)

:: ── Step 3b: Pexels API Key (optional) ───
echo.
echo [+] Checking Pexels API key (optional - enables image search for bots)...

echo.
echo   Which image search provider would you like to use?
echo     1^) Pexels  - curated stock photos, 1 key    ^(pexels.com/api^)
echo     2^) Google  - broader web results, 2 keys    ^(console.cloud.google.com^)
echo     3^) None    - disable image search
echo.
set /p IMG_CHOICE=    Enter 1, 2, or 3:

:: Strip any existing image search keys before writing new ones
findstr /v /r /c:"^PEXELS_API_KEY=" /c:"^GOOGLE_API_KEY=" /c:"^GOOGLE_CX=" "server\.env" > "server\.env.tmp" 2>nul
if exist "server\.env.tmp" move /y "server\.env.tmp" "server\.env" >nul

if "!IMG_CHOICE!"=="1" (
    echo     Create a free API key at: https://www.pexels.com/api/
    echo.
    set /p PEXELS_KEY=    Enter your Pexels API key:
    if not "!PEXELS_KEY!"=="" (
        (echo PEXELS_API_KEY=!PEXELS_KEY!) >> server\.env
        echo [+] Pexels API key saved.
    )
) else if "!IMG_CHOICE!"=="2" (
    echo     1. Go to programmablesearchengine.google.com and create a search engine
    echo     2. Enable "Image search" in its settings and copy the Search Engine ID
    echo     3. Get an API key from console.cloud.google.com ^(enable Custom Search API^)
    echo.
    set /p GOOGLE_KEY=    Enter your Google API key:
    set /p GOOGLE_CX_VAL=    Enter your Search Engine ID ^(cx^):
    if not "!GOOGLE_KEY!"=="" if not "!GOOGLE_CX_VAL!"=="" (
        (echo GOOGLE_API_KEY=!GOOGLE_KEY!) >> server\.env
        (echo GOOGLE_CX=!GOOGLE_CX_VAL!) >> server\.env
        echo [+] Google Custom Search keys saved.
    )
) else (
    echo [+] Image search disabled.
)

:: ── Step 4: Free ports ───────────────────
echo.
echo [+] Checking for processes on ports 3000 and 3001...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 \|:3001 "') do (
    taskkill /PID %%p /F >nul 2>&1
)
echo [+] Ports cleared.

:: ── Step 5: Launch ────────────────────────
echo.
echo ========================================
echo   Setup complete! Launching...
echo ========================================
echo.
echo [+] Starting server...  http://localhost:3001
echo [+] Starting client...  http://localhost:3000
echo.
echo     Opening your browser automatically in a few seconds...
echo     If it does not open, go to: http://localhost:3000
echo     Press Ctrl+C to stop.
echo.

:: Open browser after a short delay (runs in background while npm starts)
start "" cmd /c "timeout /t 5 /nobreak > nul && start http://localhost:3000"

call npm run dev

:: Runs when npm exits normally, or if user answers N to "Terminate batch job?"
echo.
echo [+] Shutting down servers...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 \|:3001 "') do (
    taskkill /PID %%p /F >nul 2>&1
)
echo [+] Servers stopped. Goodbye!
