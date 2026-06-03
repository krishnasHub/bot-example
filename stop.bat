@echo off
setlocal enabledelayedexpansion

echo.
echo [+] Stopping Bot Group Chat servers...

set STOPPED=0
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 \|:3001 "') do (
    taskkill /PID %%p /F >nul 2>&1
    set STOPPED=1
)

if "!STOPPED!"=="1" (
    echo [+] Servers stopped.
) else (
    echo [!] No servers running on ports 3000 or 3001.
)
echo.
