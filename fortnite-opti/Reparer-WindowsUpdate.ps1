<#
.SYNOPSIS
    Répare Windows Update quand une mise à jour échoue (ex. erreur 0x800736b3),
    avec un point de restauration OBLIGATOIRE et sans supprimer aucun fichier.

.DESCRIPTION
    Réparer (par défaut) :
      1. point de restauration Windows « Avant réparation Windows Update » :
         créé et VÉRIFIÉ, sinon le script s'arrête sans rien toucher ;
      2. services Windows Update remis en marche s'ils ont été désactivés ;
      3. DISM /RestoreHealth : répare la réserve de composants de Windows ;
      4. SFC /scannow : répare les fichiers système ;
      5. remise à zéro de Windows Update : ses dossiers SoftwareDistribution et
         catroot2 sont RENOMMÉS (gardés intacts), jamais supprimés ;
      6. redémarrage, puis Windows Update s'ouvre tout seul pour réessayer.

    Annuler :
      remet les dossiers d'origine de Windows Update (les nouveaux sont gardés,
      renommés) et ouvre la Restauration du système pour revenir au point
      « Avant réparation Windows Update ».

    Aucun fichier personnel n'est touché. Un journal est écrit dans
    %USERPROFILE%\FortniteOpti-Sauvegarde.

.PARAMETER Action
    Reparer (par défaut) ou Annuler.
#>
[CmdletBinding()]
param(
    [ValidateSet('Reparer', 'Annuler')]
    [string]$Action = 'Reparer'
)

$ErrorActionPreference = 'Stop'

$script:Dossier = Join-Path $env:USERPROFILE 'FortniteOpti-Sauvegarde'
$script:NomPoint = 'Avant réparation Windows Update'
$script:Erreurs = 0

function Write-Titre([string]$Texte)     { Write-Host ''; Write-Host "[*] $Texte" -ForegroundColor Cyan }
function Write-Ok([string]$Texte)        { Write-Host "    [OK] $Texte" -ForegroundColor Green }
function Write-Info([string]$Texte)      { Write-Host "         $Texte" -ForegroundColor Gray }
function Write-Attention([string]$Texte) { Write-Host "    [!]  $Texte" -ForegroundColor Yellow }

function Read-Oui([string]$Question) {
    $reponse = "$(Read-Host "  $Question (O/N)")"
    return ($reponse -match '^\s*[oOyY]')
}

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Etape([string]$Titre, [scriptblock]$Bloc) {
    Write-Titre $Titre
    try { & $Bloc }
    catch { $script:Erreurs++; Write-Attention "Étape non terminée : $($_.Exception.Message)" }
}

function Show-CommentRevenir {
    Write-Info 'Pour revenir EXACTEMENT comme avant : double-clic sur ANNULER-REPARATION.bat.'
    Write-Info '(Ou : Démarrer > tape « Créer un point de restauration » > « Restauration du système… »'
    Write-Info " > choisis « $($script:NomPoint) » > Suivant > Terminer.)"
}

# ---------------------------------------------------------------------------
# Vérifications
# ---------------------------------------------------------------------------
function Get-InfosWindows {
    $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $insider = $null
    $cleInsider = 'HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability'
    if (Test-Path -LiteralPath $cleInsider) {
        $app = Get-ItemProperty -LiteralPath $cleInsider -ErrorAction SilentlyContinue
        if ($app -and $app.BranchName) { $insider = [string]$app.BranchName }
    }
    return [pscustomobject]@{
        Version = [string]$cv.DisplayVersion
        Build   = '{0}.{1}' -f $cv.CurrentBuild, $cv.UBR
        Insider = $insider
    }
}

function Test-RedemarrageEnAttente {
    return (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
           (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Auto Update\RebootRequired')
}

function Get-EspaceLibreGo {
    $disque = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
    return [math]::Round($disque.FreeSpace / 1GB, 1)
}

function Test-ModePartieActif {
    $etat = Join-Path $script:Dossier 'mode-partie.json'
    if (-not (Test-Path -LiteralPath $etat)) { return $false }
    try {
        $pidPartie = [int]((Get-Content -LiteralPath $etat -Raw -Encoding UTF8 | ConvertFrom-Json).Pid)
        $p = Get-Process -Id $pidPartie -ErrorAction SilentlyContinue
        return [bool]($p -and $p.ProcessName -match 'powershell|pwsh')
    } catch { return $false }
}

# ---------------------------------------------------------------------------
# Point de restauration GARANTI
# ---------------------------------------------------------------------------
function Get-DernierNumeroPoint {
    $points = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue)
    if ($points.Count -eq 0) { return 0 }
    return [int](($points | Measure-Object -Property SequenceNumber -Maximum).Maximum)
}

function New-PointRestaurationGaranti {
    # Active la protection du système sur le disque Windows si elle était coupée.
    try { Enable-ComputerRestore -Drive "$($env:SystemDrive)\" } catch { }

    # Windows ne crée qu'un point par 24 h : on lève cette limite le temps de créer
    # le nôtre, puis on remet la valeur d'origine.
    $cle = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $nom = 'SystemRestorePointCreationFrequency'
    $existait = $false; $ancienne = $null
    if (Test-Path -LiteralPath $cle) {
        $k = Get-Item -LiteralPath $cle
        if (@($k.GetValueNames()) -contains $nom) { $existait = $true; $ancienne = $k.GetValue($nom) }
    }
    $avant = Get-DernierNumeroPoint
    try {
        New-ItemProperty -LiteralPath $cle -Name $nom -Value 0 -PropertyType DWord -Force | Out-Null
        Checkpoint-Computer -Description $script:NomPoint -RestorePointType 'MODIFY_SETTINGS'
    } finally {
        if ($existait) { New-ItemProperty -LiteralPath $cle -Name $nom -Value $ancienne -PropertyType DWord -Force | Out-Null }
        else { Remove-ItemProperty -LiteralPath $cle -Name $nom -ErrorAction SilentlyContinue }
    }

    # Vérification : le point doit vraiment exister.
    $nouveau = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
        Where-Object { [int]$_.SequenceNumber -gt $avant -and $_.Description -eq $script:NomPoint })
    if ($nouveau.Count -eq 0) { throw 'Windows n''a pas créé le point de restauration.' }
    Write-Ok "Point de restauration « $($script:NomPoint) » créé et vérifié."
}

# ---------------------------------------------------------------------------
# Réparation
# ---------------------------------------------------------------------------
# Services nécessaires à Windows Update, et le démarrage à remettre s'ils ont été désactivés.
$script:Services = [ordered]@{
    'wuauserv'         = 'Manual'      # Windows Update
    'BITS'             = 'Manual'      # Service de transfert intelligent en arrière-plan
    'CryptSvc'         = 'Automatic'   # Services de chiffrement (signatures des mises à jour)
    'msiserver'        = 'Manual'      # Windows Installer
    'TrustedInstaller' = 'Manual'      # Programme d'installation pour les modules Windows
    'UsoSvc'           = 'Automatic'   # Orchestrateur de mise à jour
    'DoSvc'            = 'Manual'      # Optimisation de la distribution
}

function Repair-Services {
    foreach ($nom in $script:Services.Keys) {
        $s = Get-Service -Name $nom -ErrorAction SilentlyContinue
        if (-not $s) { continue }
        if ([string]$s.StartType -eq 'Disabled') {
            Set-Service -Name $nom -StartupType $script:Services[$nom]
            Write-Ok "$($s.DisplayName) : était DÉSACTIVÉ, remis en marche."
        }
    }
    Write-Ok 'Services de Windows Update vérifiés.'
}

function Stop-ServicesMaj {
    foreach ($nom in @('UsoSvc', 'wuauserv', 'DoSvc', 'BITS', 'CryptSvc', 'msiserver')) {
        try { Stop-Service -Name $nom -Force -ErrorAction Stop } catch { }
    }
}

function Start-ServicesMaj {
    foreach ($nom in @('CryptSvc', 'BITS', 'wuauserv', 'UsoSvc')) {
        try { Start-Service -Name $nom -ErrorAction Stop } catch { }
    }
}

# Renomme un dossier (jamais de suppression), en réessayant si Windows l'utilise encore.
function Rename-DossierSur([string]$Chemin, [string]$NouveauNom) {
    for ($essai = 1; $essai -le 3; $essai++) {
        try {
            Rename-Item -LiteralPath $Chemin -NewName $NouveauNom -ErrorAction Stop
            return $true
        } catch {
            Stop-ServicesMaj
            Start-Sleep -Seconds 3
        }
    }
    return $false
}

function Get-DossiersWindowsUpdate {
    return @(
        (Join-Path $env:SystemRoot 'SoftwareDistribution'),
        (Join-Path $env:SystemRoot 'System32\catroot2')
    )
}

function Invoke-Dism {
    Write-Info 'Ça peut rester bloqué à 62 % ou 84 % pendant plusieurs minutes : c''est normal, ne ferme pas.'
    & dism.exe /Online /Cleanup-Image /RestoreHealth
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        Write-Ok 'Réserve de composants de Windows réparée (DISM).'
    } else {
        $script:Erreurs++
        Write-Attention ("DISM a échoué (code {0} / 0x{0:X8})." -f $code)
        Write-Info 'Si ça se reproduit, il faudra le « plan B » proposé à la fin (réinstallation en gardant tout).'
    }
}

function Invoke-Sfc {
    & sfc.exe /scannow
    Write-Ok 'Vérification des fichiers système terminée (SFC).'
}

function Reset-WindowsUpdate {
    $horodatage = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
    Stop-ServicesMaj
    foreach ($d in Get-DossiersWindowsUpdate) {
        if (-not (Test-Path -LiteralPath $d)) { continue }
        $feuille = Split-Path -Path $d -Leaf
        if (Rename-DossierSur $d "$feuille.ancien-$horodatage") {
            Write-Ok "$feuille mis de côté INTACT sous le nom $feuille.ancien-$horodatage (rien n'est supprimé)."
        } else {
            $script:Erreurs++
            Write-Attention "$feuille est utilisé par Windows : pas pu le mettre de côté (le redémarrage aidera)."
        }
    }
    Start-ServicesMaj
    Write-Info 'Windows Update recrée des dossiers neufs. L''historique affiché repart à zéro : c''est normal.'
}

function Register-OuvertureWindowsUpdate {
    $cle = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    if (-not (Test-Path -LiteralPath $cle)) { New-Item -Path $cle -Force | Out-Null }
    New-ItemProperty -LiteralPath $cle -Name 'OuvrirWindowsUpdate' -Value 'explorer.exe ms-settings:windowsupdate' -PropertyType String -Force | Out-Null
    Write-Ok 'Windows Update s''ouvrira tout seul après le redémarrage (une seule fois).'
}

function Show-Suite {
    Write-Host ''
    Write-Host '  ===================== SUITE =====================' -ForegroundColor Green
    Write-Info '1. Après le redémarrage, Windows Update s''ouvre : clique sur « Rechercher des mises à jour »'
    Write-Info '   (ou « Réessayer » / « Tout recommencer »), puis laisse-le installer. Ne joue pas pendant.'
    Write-Info '2. Si l''erreur revient quand même (PLAN B, garde tes fichiers et tes applis) :'
    Write-Info '   Paramètres > Système > Récupération > « Résoudre les problèmes à l''aide de Windows Update »'
    Write-Info '   > « Réinstaller maintenant ». Ça réinstalle Windows par-dessus, sans rien effacer.'
    Write-Info '3. Cette mise à jour est une « préversion » (optionnelle). Si tu ne veux plus en recevoir :'
    Write-Info '   Windows Update > désactive « Recevez les dernières mises à jour dès qu''elles sont disponibles ».'
    Write-Info '   Les mêmes correctifs arrivent de toute façon dans la mise à jour normale du mois suivant.'
    Write-Host ''
    Show-CommentRevenir
}

function Invoke-Reparation {
    Write-Host ''
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host '     RÉPARATION DE WINDOWS UPDATE' -ForegroundColor Magenta
    Write-Host '  ==================================================' -ForegroundColor Magenta

    Write-Titre 'Ton Windows'
    $infos = Get-InfosWindows
    Write-Info "Windows 11 version $($infos.Version) (build $($infos.Build))"
    if ($infos.Insider) {
        Write-Attention "Ton PC est inscrit au programme Windows Insider (canal « $($infos.Insider) ») : versions de TEST."
        Write-Info 'Elles ont plus de bugs (y compris des échecs d''installation) et peuvent causer des ralentissements.'
        Write-Info 'Pour les quitter : Paramètres > Windows Update > Programme Windows Insider.'
    }
    $libre = Get-EspaceLibreGo
    Write-Info "Espace libre sur $($env:SystemDrive) : $libre Go"
    if ($libre -lt 20) {
        Write-Attention 'Moins de 20 Go libres : une mise à jour peut échouer faute de place.'
    }
    if (Test-ModePartieActif) {
        Write-Attention 'Le MODE PARTIE est actif : il bloque Windows Update. Termine-le (Entrée dans sa fenêtre) avant.'
        return
    }
    if (Test-RedemarrageEnAttente) {
        Write-Attention 'Un redémarrage est EN ATTENTE : Windows doit d''abord finir ce qu''il a commencé.'
        Write-Info 'Redémarre le PC, puis relance REPARER-WINDOWS-UPDATE.bat.'
        if (Read-Oui 'Redémarrer maintenant ?') { Restart-Computer -Force }
        return
    }

    Write-Titre 'Ce qui va être fait (20 à 60 minutes, ne joue pas pendant)'
    Write-Info '1. Point de restauration Windows créé et vérifié (sinon on s''arrête, sans rien toucher)'
    Write-Info '2. Services de Windows Update remis en marche s''ils étaient désactivés'
    Write-Info '3. DISM : répare la réserve de composants (retélécharge les fichiers abîmés)'
    Write-Info '4. SFC : répare les fichiers système'
    Write-Info '5. Dossiers de Windows Update mis de côté (renommés, JAMAIS supprimés)'
    Write-Info '6. Redémarrage, puis Windows Update s''ouvre pour réessayer'
    Write-Info 'Aucun fichier n''est supprimé, aucun fichier personnel n''est touché. Garde Internet branché.'
    Write-Host ''
    if (-not (Read-Oui 'Lancer la réparation ?')) { Write-Info 'Annulé, rien n''a été modifié.'; return }

    # Sans point de restauration, on ne touche à RIEN.
    Write-Titre 'Point de restauration Windows (filet de sécurité)'
    try {
        New-PointRestaurationGaranti
    } catch {
        Write-Attention "Impossible de créer le point de restauration : $($_.Exception.Message)"
        Write-Attention 'Par sécurité, la réparation s''arrête ICI : rien n''a été modifié.'
        Write-Info 'Vérifie : Démarrer > « Créer un point de restauration » > disque C: > Configurer > « Activer ».'
        return
    }

    Invoke-Etape 'Services de Windows Update' { Repair-Services }
    Invoke-Etape 'DISM : réparation de la réserve de composants (10 à 30 min)' { Invoke-Dism }
    Invoke-Etape 'SFC : réparation des fichiers système (10 à 20 min)' { Invoke-Sfc }
    Invoke-Etape 'Remise à zéro de Windows Update (dossiers renommés, pas supprimés)' { Reset-WindowsUpdate }
    Invoke-Etape 'Après le redémarrage' { Register-OuvertureWindowsUpdate }

    Write-Host ''
    if ($script:Erreurs -eq 0) {
        Write-Host '  ============ RÉPARATION TERMINÉE ============' -ForegroundColor Green
    } else {
        Write-Attention "$($script:Erreurs) étape(s) ne se sont pas terminées correctement (détails au-dessus)."
    }
    Show-Suite
    Write-Host ''
    Write-Attention 'Le REDÉMARRAGE est indispensable avant de réessayer la mise à jour.'
    if (Read-Oui 'Redémarrer le PC maintenant ?') { Restart-Computer -Force }
}

# ---------------------------------------------------------------------------
# Annulation
# ---------------------------------------------------------------------------
function Invoke-Annulation {
    Write-Host ''
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host '     ANNULER LA RÉPARATION DE WINDOWS UPDATE' -ForegroundColor Magenta
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Titre 'Ce qui va être fait'
    Write-Info '1. Les dossiers d''origine de Windows Update sont remis en place'
    Write-Info '   (les dossiers actuels sont gardés, renommés « .apres-reparation », rien n''est supprimé)'
    Write-Info "2. La Restauration du système s'ouvre : choisis « $($script:NomPoint) »"
    Write-Info '   pour remettre tout le reste exactement comme avant.'
    Write-Host ''
    if (-not (Read-Oui 'Annuler la réparation ?')) { Write-Info 'Rien n''a été modifié.'; return }

    Write-Titre 'Dossiers de Windows Update'
    $horodatage = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
    Stop-ServicesMaj
    foreach ($d in Get-DossiersWindowsUpdate) {
        $parent = Split-Path -Path $d -Parent
        $feuille = Split-Path -Path $d -Leaf
        $origine = @(Get-ChildItem -LiteralPath $parent -Directory -Filter "$feuille.ancien-*" -ErrorAction SilentlyContinue |
            Sort-Object -Property Name -Descending) | Select-Object -First 1
        if (-not $origine) { Write-Info "$feuille : aucune copie d'origine trouvée, rien à remettre."; continue }
        if ((Test-Path -LiteralPath $d) -and -not (Rename-DossierSur $d "$feuille.apres-reparation-$horodatage")) {
            $script:Erreurs++; Write-Attention "$feuille est utilisé par Windows : redémarre puis relance ANNULER-REPARATION.bat."; continue
        }
        if (Rename-DossierSur $origine.FullName $feuille) { Write-Ok "$feuille d'origine remis en place." }
        else { $script:Erreurs++; Write-Attention "Impossible de remettre $feuille (redémarre puis relance)." }
    }
    Start-ServicesMaj
    try { Remove-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'OuvrirWindowsUpdate' -ErrorAction Stop } catch { }

    Write-Titre 'Restauration du système'
    $point = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object { $_.Description -eq $script:NomPoint })
    if ($point.Count -eq 0) {
        Write-Attention "Aucun point « $($script:NomPoint) » trouvé : la réparation n'a peut-être jamais été lancée."
        return
    }
    Write-Info "Dans la fenêtre qui s'ouvre : « Choisir un autre point de restauration » si proposé > Suivant,"
    Write-Info "sélectionne « $($script:NomPoint) » > Suivant > Terminer. Le PC redémarre tout seul."
    Write-Info 'Tes fichiers personnels ne sont pas touchés.'
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\rstrui.exe')
}

# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------
if ($env:OS -ne 'Windows_NT') {
    Write-Host 'Ce script est fait pour Windows uniquement.' -ForegroundColor Red
    exit 1
}

if (-not (Test-Admin)) {
    Write-Host 'Demande des droits administrateur...' -ForegroundColor Yellow
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action"
    } catch {
        Write-Host 'Droits administrateur refusés : impossible de continuer.' -ForegroundColor Red
        Read-Host 'Appuie sur Entrée pour fermer' | Out-Null
    }
    exit
}

try { $Host.UI.RawUI.WindowTitle = 'Réparation de Windows Update' } catch { }
if (-not (Test-Path -LiteralPath $script:Dossier)) { New-Item -ItemType Directory -Path $script:Dossier -Force | Out-Null }
$journal = Join-Path $script:Dossier ('reparation-windows-update-{0}-{1:yyyyMMdd-HHmmss}.log' -f $Action.ToLower(), (Get-Date))
try { Start-Transcript -LiteralPath $journal | Out-Null } catch { }
try {
    if ($Action -eq 'Annuler') { Invoke-Annulation } else { Invoke-Reparation }
} catch {
    Write-Host "Erreur inattendue : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    try { Stop-Transcript | Out-Null } catch { }
    Write-Host ''
    Write-Info "Journal : $journal"
    Read-Host '  Appuie sur Entrée pour fermer' | Out-Null
}
