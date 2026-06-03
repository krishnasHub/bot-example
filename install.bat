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

:: ── Step 4: Launch ────────────────────────
echo.
echo ========================================
echo   Setup complete! Launching...
echo ========================================
echo.
echo [+] Starting server...  http://localhost:3001
echo [+] Starting client...  http://localhost:3000
echo.
echo     Open http://localhost:3000 in your browser to use the app.
echo     Press Ctrl+C to stop.
echo.

call npm run dev
