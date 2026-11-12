<#
.SYNOPSIS
  Sincronizza il fork aziendale ProbatPdfCraft con il repository ufficiale upstream (storytold/pdfcraft)
  preservando le modifiche aziendali (isolamento offline, rimozione brand terzi, branding ProbatPdfCraft).

.PARAMETER Ref
  Il tag o branch upstream a cui aggiornare (es. "v0.19.0" o "upstream/main").

.PARAMETER Strategy
  Strategia di integrazione: "rebase" (default, mantiene i commit aziendali puliti in cima) oppure "merge".

.PARAMETER AttachBaseTag
  Usato solo al primo collegamento se la repository locale è stata inizializzata senza la storia upstream:
  aggancia la storia al tag base (default "v0.18.1") prima di procedere.

.EXAMPLE
  # Primo aggancio alla storia upstream (da eseguire su macchina con accesso a github.com):
  .\scripts\sync-upstream.ps1 -AttachBaseTag v0.18.1

.EXAMPLE
  # Aggiornamento a una nuova versione ufficiale (es. v0.19.0):
  .\scripts\sync-upstream.ps1 -Ref v0.19.0
#>
param(
    [string] $Ref = '',
    [ValidateSet('rebase', 'merge')]
    [string] $Strategy = 'rebase',
    [string] $AttachBaseTag = ''
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $Root

$UpstreamUrl = 'https://github.com/storytold/pdfcraft.git'
$CorporateBranch = 'probat-main'

Write-Host "==> Configurazione repository Git in $Root" -ForegroundColor Cyan

if (-not (Test-Path (Join-Path $Root '.git'))) {
    throw "Directory .git non trovata. Esegui prima 'git init'."
}

# Verifica/configura il remote 'upstream' (SOLO LETTURA: push bloccato)
$remotes = @(git remote)
if ($remotes -notcontains 'upstream') {
    Write-Host "  Aggiunta remote 'upstream' -> $UpstreamUrl (solo fetch)" -ForegroundColor Yellow
    git remote add upstream $UpstreamUrl
} else {
    $currentUrl = (git remote get-url upstream).Trim()
    if ($currentUrl -ne $UpstreamUrl) {
        git remote set-url upstream $UpstreamUrl
    }
}
# Blocca qualsiasi git push verso il repository pubblico ufficiale
git remote set-url --push upstream DISABLED_READ_ONLY_UPSTREAM
git config remote.pushDefault origin
git config "branch.$CorporateBranch.pushRemote" origin

Write-Host "==> Scaricamento aggiornamenti da upstream ($UpstreamUrl)..." -ForegroundColor Cyan
git fetch upstream --tags
if ($LASTEXITCODE -ne 0) {
    throw "Impossibile contattare $UpstreamUrl. Assicurati di eseguire questo script da una postazione che può raggiungere GitHub."
}

# Caso 1: Ri-aggancio iniziale della storia al tag v0.18.1
if ($AttachBaseTag) {
    Write-Host "==> Aggancio della storia locale al tag ufficiale '$AttachBaseTag'..." -ForegroundColor Cyan
    # Spostiamo il puntatore del branch sul tag base mantenendo intatti i file della working tree
    git checkout -B $CorporateBranch
    git reset --mixed $AttachBaseTag
    if ($LASTEXITCODE -ne 0) {
        throw "Tag '$AttachBaseTag' non trovato su upstream."
    }

    # Rimuovi eventuale docs/brand
    if (Test-Path (Join-Path $Root 'docs\brand')) {
        Remove-Item -Recurse -Force (Join-Path $Root 'docs\brand')
    }

    git add -A
    $status = git status --porcelain
    if ($status) {
        git commit -m "chore(probat): corporate offline fork ProbatPdfCraft on top of $AttachBaseTag"
        Write-Host "  [OK] Modifiche ProbatPdfCraft salvate come commit sopra $AttachBaseTag." -ForegroundColor Green
    } else {
        Write-Host "  Nessuna differenza rispetto a $AttachBaseTag." -ForegroundColor Yellow
    }
}

# Caso 2: Sincronizzazione con una nuova release o ref upstream
if ($Ref) {
    Write-Host "==> Integrazione di '$Ref' sul branch '$CorporateBranch' (strategia: $Strategy)..." -ForegroundColor Cyan
    git checkout $CorporateBranch

    if ($Strategy -eq 'rebase') {
        git rebase $Ref
    } else {
        git merge --no-edit $Ref
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ATTENZIONE] Sono presenti conflitti da risolvere manualmente." -ForegroundColor Yellow
        Write-Host "Dopo aver risolto i conflitti nei file segnalati da 'git status':" -ForegroundColor Yellow
        Write-Host "  1. Assicurati che 'docs/brand' sia rimosso" -ForegroundColor Yellow
        Write-Host "  2. Esegui 'git rebase --continue' (o 'git commit' se in merge)" -ForegroundColor Yellow
        Write-Host "  3. Esegui '.\scripts\verify-corporate-policy.ps1' per verificare la conformità" -ForegroundColor Yellow
        exit 1
    }

    # Sicurezza post-aggiornamento: se l'upstream ha aggiunto nuovi file in docs/brand, rimuovili subito
    $brandDir = Join-Path $Root 'docs\brand'
    if (Test-Path $brandDir) {
        Write-Host "  Rimozione automatica di docs/brand introdotto da upstream..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $brandDir
        git add -A docs/brand
        git commit -m "chore(probat): remove upstream docs/brand assets"
    }
}

# Esegui la verifica automatica della policy aziendale
Write-Host "`n==> Esecuzione verifica di conformità aziendale..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'verify-corporate-policy.ps1') -SkipBinaryCheck
if ($LASTEXITCODE -ne 0) {
    throw "La verifica della policy aziendale ha rilevato problemi dopo la sincronizzazione."
}

Write-Host "`n==> Sincronizzazione completata con successo sul branch '$CorporateBranch'!" -ForegroundColor Green
