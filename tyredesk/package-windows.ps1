$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $bundle = Join-Path $repoRoot 'flutter\build\windows\x64\runner\Release'
    if (-not (Test-Path -LiteralPath "$bundle\rustdesk.exe")) { throw 'Executavel compilado nao encontrado.' }
    # Internal DLL names remain upstream; only the executable distributed to users changes.
    Move-Item -LiteralPath "$bundle\rustdesk.exe" -Destination "$bundle\TyreDesk.exe" -Force
    Copy-Item -LiteralPath 'LICENCE' -Destination "$bundle\LICENCE"
    Copy-Item -LiteralPath 'tyredesk\LEIA-ME.txt' -Destination "$bundle\LEIA-ME.txt"
    Copy-Item -LiteralPath 'tyredesk\SOURCE-NOTICE.txt' -Destination "$bundle\SOURCE-NOTICE.txt"
    New-Item -ItemType Directory -Path 'dist' -Force | Out-Null
    Compress-Archive -Path "$bundle\*" -DestinationPath 'dist\TyreDesk-windows-x64.zip' -Force
    Push-Location libs/portable
    try {
        & python -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar empacotador.' }
        & python generate.py -f ../../flutter/build/windows/x64/runner/Release -o . -e TyreDesk.exe
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar executavel portatil.' }
    } finally { Pop-Location }
    Copy-Item -LiteralPath 'target\release\rustdesk-portable-packer.exe' -Destination 'dist\TyreDesk.exe' -Force
    Get-FileHash -Algorithm SHA256 -LiteralPath 'dist\TyreDesk.exe', 'dist\TyreDesk-windows-x64.zip' |
        ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } |
        Set-Content -Encoding ascii -LiteralPath 'dist\SHA256SUMS.txt'
} finally { Pop-Location }
