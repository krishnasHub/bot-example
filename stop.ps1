# Bot Group Chat - Stop Script (Windows PowerShell)

Write-Host ""
Write-Host "[+] Stopping Bot Group Chat servers..." -ForegroundColor Green

$pids = Get-NetTCPConnection -LocalPort 3000,3001 -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique

if ($pids) {
    $pids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    Write-Host "[+] Servers stopped." -ForegroundColor Green
} else {
    Write-Host "[!] No servers running on ports 3000 or 3001." -ForegroundColor Yellow
}
Write-Host ""
