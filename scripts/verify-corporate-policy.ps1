<#
.SYNOPSIS
  Verifica che il fork aziendale ProbatPdfCraft rispetti tutte le policy di isolamento offline e pulizia del brand.

.DESCRIPTION
  Controlla:
  1. Assenza della cartella docs/brand/
  2. Assenza di URL esterni vietati (discord.gg, getartcraft.com) nel codice sorgente e nei file di packaging
  3. Assenza del marchio "artcraft" (eccetto nei test negativi di non-regressione)
  4. Isolamento delle costanti in crates/engine/src/links.rs e disattivazione update in updates.rs
  5. Presenza del branding ProbatPdfCraft e dichiarazione di fork da PdfCraft v0.18.1
  6. Scansione binaria (se gli eseguibili release sono presenti)
#>
param(
    [switch] $SkipBinaryCheck
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Failures = [System.Collections.Generic.List[string]]::new()

Write-Host "==> Verifica Policy Aziendale ProbatPdfCraft in $Root" -ForegroundColor Cyan

# 1. docs/brand non deve esistere
$brandDir = Join-Path $Root 'docs\brand'
if (Test-Path $brandDir) {
    $Failures.Add("VIOLAZIONE: La directory 'docs/brand' esiste ancora ($brandDir).")
} else {
    Write-Host "  [OK] Directory docs/brand assente." -ForegroundColor Green
}

# 2. Ricerca riferimenti vietati nei file sorgente, doc e packaging
$searchPaths = @(
    'apps', 'crates', 'docs', 'packaging', 'xtask',
    'ATTRIBUTION.toml', 'ATTRIBUTION.md', 'README.md', 'NOTICE', 'LICENSE-MIT', 'ROADMAP.md', 'AGENTS.md'
) | ForEach-Object { Join-Path $Root $_ } | Where-Object { Test-Path $_ }

$files = foreach ($p in $searchPaths) {
    if ((Get-Item $p).PSIsContainer) {
        Get-ChildItem -Path $p -Recurse -File -Exclude *.png,*.ico,*.icns,*.ttf,*.otf,*.woff2,*.pdf,*.onnx,*.brotli
    } else {
        Get-Item $p
    }
}

$allowedTestFiles = @(
    [IO.Path]::GetFullPath((Join-Path $Root 'crates\engine\src\links\tests.rs')),
    [IO.Path]::GetFullPath((Join-Path $Root 'crates\ui-egui\tests\it\links.rs'))
)

foreach ($file in $files) {
    $full = [IO.Path]::GetFullPath($file.FullName)
    $content = [System.IO.File]::ReadAllText($full)

    if ($content -match 'discord\.gg' -or $content -match 'getartcraft\.com') {
        $Failures.Add("VIOLAZIONE URL ESTERNO in $($file.FullName)")
    }

    if ($allowedTestFiles -notcontains $full) {
        if ($content -match '(?i)artcraft') {
            $Failures.Add("VIOLAZIONE BRAND 'artcraft' in $($file.FullName)")
        }
    }
}

if ($Failures.Count -eq 0) {
    Write-Host "  [OK] Nessun riferimento ad 'artcraft', 'discord.gg' o 'getartcraft.com' nei sorgenti." -ForegroundColor Green
}

# 3. Verifica links.rs
$linksRs = [System.IO.File]::ReadAllText((Join-Path $Root 'crates\engine\src\links.rs'))
$hasEmptyLinks = ($linksRs -match 'pub const DISCORD: &str = "";') -and
                 ($linksRs -match 'pub const WEBSITE: &str = "";') -and
                 ($linksRs -match 'pub const APP_PAGE: &str = "";') -and
                 ($linksRs -match 'pub const GITHUB: &str = "";') -and
                 ($linksRs -match 'pub const LINKS: &\[Link\] = &\[\];')
if (-not $hasEmptyLinks) {
    $Failures.Add("VIOLAZIONE RETE: crates/engine/src/links.rs contiene costanti URL o LINKS non vuote.")
} else {
    Write-Host "  [OK] crates/engine/src/links.rs ha tutti i link esterni disabilitati." -ForegroundColor Green
}

# 4. Verifica updates.rs
$updatesRs = [System.IO.File]::ReadAllText((Join-Path $Root 'crates\ui-egui\src\platform\updates.rs'))
if ($updatesRs -match '\.check_at_start\(' -or $updatesRs -match '\.check_now\(') {
    $Failures.Add("VIOLAZIONE RETE: crates/ui-egui/src/platform/updates.rs invoca ancora il client di update remoto.")
} else {
    Write-Host "  [OK] Controllo aggiornamenti remoti disattivato in updates.rs." -ForegroundColor Green
}

# 5. Verifica presenza nome ProbatPdfCraft e dichiarazione fork di PdfCraft v0.18.1
$requiredDeclarations = @(
    @{ Path = 'README.md'; Pattern = 'ProbatPdfCraft' },
    @{ Path = 'README.md'; Pattern = 'PdfCraft v0\.18\.1' },
    @{ Path = 'NOTICE'; Pattern = 'ProbatPdfCraft' },
    @{ Path = 'NOTICE'; Pattern = 'PdfCraft v0\.18\.1' },
    @{ Path = 'crates\ui-egui\src\dialogs.rs'; Pattern = 'ProbatPdfCraft' },
    @{ Path = 'crates\ui-egui\src\dialogs.rs'; Pattern = 'PdfCraft v0\.18\.1' },
    @{ Path = 'apps\pdfcraft\src\main.rs'; Pattern = 'ProbatPdfCraft' },
    @{ Path = 'apps\pdfcraft-cli\src\main.rs'; Pattern = 'fork of PdfCraft v0\.18\.1' }
)

foreach ($req in $requiredDeclarations) {
    $p = Join-Path $Root $req.Path
    $txt = [System.IO.File]::ReadAllText($p)
    if ($txt -notmatch $req.Pattern) {
        $Failures.Add("MANCANTE: '$($req.Pattern)' non trovato in $($req.Path)")
    }
}
Write-Host "  [OK] Branding ProbatPdfCraft e dichiarazione fork PdfCraft v0.18.1 presenti." -ForegroundColor Green

# 6. Scansione binari se presenti
if (-not $SkipBinaryCheck) {
    $binCandidates = @(
        (Join-Path $Root 'target\x86_64-pc-windows-msvc\release\pdfcraft.exe'),
        (Join-Path $Root 'target\x86_64-pc-windows-msvc\release\pdfcraft-cli.exe')
    )
    foreach ($bin in $binCandidates) {
        if (Test-Path $bin) {
            $bytes = [System.IO.File]::ReadAllBytes($bin)
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
            $binOk = $true
            foreach ($forbidden in @('discord\.gg', 'getartcraft\.com')) {
                $m = [regex]::Matches($ascii, $forbidden, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
                if ($m -gt 0) {
                    $Failures.Add("VIOLAZIONE BINARIA: $bin contiene $m occorrenze di '$forbidden'")
                    $binOk = $false
                }
            }
            if ($binOk) {
                Write-Host "  [OK] Binario verificato (0 URL vietati): $(Split-Path -Leaf $bin)" -ForegroundColor Green
            }
        }
    }
}

if ($Failures.Count -gt 0) {
    Write-Host "`nESITO: FALLITO ($($Failures.Count) problemi rilevati):" -ForegroundColor Red
    foreach ($f in $Failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`nESITO: TUTTI I CONTROLLI DI POLICY AZIENDALE SUPERATI CON SUCCESSO." -ForegroundColor Green
exit 0
