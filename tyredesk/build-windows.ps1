[CmdletBinding()]
param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $missing = @()
    foreach ($tool in 'cargo', 'rustc', 'flutter', 'python', 'cmake', 'clang') {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { $missing += $tool }
    }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $hasMsvc = $false
    if (Test-Path -LiteralPath $vswhere) {
        $hasMsvc = [bool](& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
    }
    if (-not $hasMsvc) { $missing += 'Visual Studio C++ (MSVC e Windows SDK)' }
    if (-not $env:VCPKG_ROOT -or -not (Test-Path -LiteralPath "$env:VCPKG_ROOT\installed\x64-windows-static")) {
        $missing += 'vcpkg com dependencias x64-windows-static'
    }
    if ($missing.Count) { throw "Ambiente incompleto: $($missing -join ', '). Consulte tyredesk/README.md ou use o workflow TyreDesk Windows." }
    if ($CheckOnly) { Write-Output 'Compiladores encontrados.'; return }

    $settingsFile = Join-Path $PSScriptRoot 'build.env.json'
    if (Test-Path -LiteralPath $settingsFile) {
        $settings = Get-Content -Raw -LiteralPath $settingsFile | ConvertFrom-Json
        $env:TYREDESK_SERVER = $settings.TYREDESK_SERVER
        $env:TYREDESK_SERVER_KEY = $settings.TYREDESK_SERVER_KEY
    }
    & python tyredesk/configure.py --check
    if ($LASTEXITCODE -ne 0) { throw 'Configuracao de servidor invalida.' }
    if (-not (Test-Path -LiteralPath 'flutter/lib/generated_bridge.dart')) {
        throw 'Gere o bridge com as instrucoes upstream ou execute o workflow TyreDesk Windows.'
    }
    & python build.py --portable --flutter --skip-portable-pack
    if ($LASTEXITCODE -ne 0) { throw 'Falha na compilacao.' }
    & "$PSScriptRoot\package-windows.ps1"
} finally {
    Pop-Location
}
