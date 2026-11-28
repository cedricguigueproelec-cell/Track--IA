<#
.SYNOPSIS
    Analyseur de latence Fortnite : MESURE ton vrai délai clic -> écran et trouve
    ce qui ajoute du délai ou des saccades sur TON PC.

.DESCRIPTION
    1. Mesurer : pendant 60 s de jeu, enregistre chaque image et chaque clic avec
       PresentMon (outil gratuit et open source d'Intel, signé, téléchargé depuis
       GitHub puis vérifié). Donne : délai entrée -> écran, FPS, saccades et le
       programme responsable, V-Sync, mode d'affichage, limite CPU/GPU, conseils.
    2. Bilan : vérifie (en LECTURE SEULE) les réglages Windows et Fortnite qui
       ajoutent du délai. Ne modifie rien.
    3. Historique : compare tes mesures (avant / après un changement).

    Ce programme ne modifie AUCUN réglage, ni de Windows ni de Fortnite.
    PresentMon lit les événements d'affichage de Windows (ETW) : il ne touche
    pas au jeu, aucun risque avec l'anti-cheat.

.PARAMETER Action
    Menu (défaut), Mesurer, Bilan, Historique.

.PARAMETER Secondes
    Durée de la mesure (défaut 60).
#>
[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Mesurer', 'Bilan', 'Historique')]
    [string]$Action = 'Menu',
    [ValidateRange(15, 300)]
    [int]$Secondes = 60
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------
$script:DossierMesures    = Join-Path $env:USERPROFILE 'FortniteOpti-Sauvegarde\mesures'
$script:FichierHistorique = Join-Path $script:DossierMesures 'historique.json'
$script:DossierOutils     = Join-Path $env:LOCALAPPDATA 'FortniteOpti\outils'
$script:ProcessusJeu      = 'FortniteClient-Win64-Shipping'
$script:PresentMon = @{
    Version = '2.6.0'
    Fichier = 'PresentMon-2.6.0-x64.exe'
    Url     = 'https://github.com/GameTechDev/PresentMon/releases/download/v2.6.0/PresentMon-2.6.0-x64.exe'
    Sha256  = 'B2A706BC6AD475749E3B7E3409263AA1E6906D45BDCF993F6DBC0F660188F1AF'
}
$script:Inv = [Globalization.CultureInfo]::InvariantCulture
$script:NomPoint = 'Avant Analyseur de latence Fortnite'

# Programmes connus pour voler des ressources pendant une partie : nom affiché + conseil.
$script:Coupables = @{
    'TiWorker'           = @('Windows Update (installation d''une mise à jour)', 'Suspends les mises à jour (Paramètres > Windows Update) ou lance MODE-PARTIE.bat avant de jouer.')
    'MoUsoCoreWorker'    = @('Windows Update (recherche de mises à jour)', 'Suspends les mises à jour ou lance MODE-PARTIE.bat avant de jouer.')
    'TrustedInstaller'   = @('Windows Update (installation)', 'Suspends les mises à jour ou lance MODE-PARTIE.bat avant de jouer.')
    'MsMpEng'            = @('Antivirus Microsoft Defender (analyse en cours)', 'Laisse l''analyse finir avant de jouer (elle ne dure pas).')
    'SearchIndexer'      = @('Indexation de la recherche Windows', 'Ça se calme tout seul ; évite de copier beaucoup de fichiers juste avant de jouer.')
    'SearchProtocolHost' = @('Indexation de la recherche Windows', 'Ça se calme tout seul.')
    'OneDrive'           = @('OneDrive (synchronisation)', 'Mets OneDrive en pause ou lance MODE-PARTIE.bat.')
    'Dropbox'            = @('Dropbox (synchronisation)', 'Mets Dropbox en pause ou lance MODE-PARTIE.bat.')
    'GoogleDriveFS'      = @('Google Drive (synchronisation)', 'Mets Google Drive en pause ou lance MODE-PARTIE.bat.')
    'chrome'             = @('Google Chrome', 'Ferme les onglets vidéo / streams pendant que tu joues.')
    'msedge'             = @('Microsoft Edge', 'Ferme les onglets vidéo / streams pendant que tu joues.')
    'firefox'            = @('Firefox', 'Ferme les onglets vidéo / streams pendant que tu joues.')
    'opera'              = @('Opera / Opera GX', 'Ferme les onglets vidéo / streams pendant que tu joues.')
    'brave'              = @('Brave', 'Ferme les onglets vidéo / streams pendant que tu joues.')
    'Discord'            = @('Discord', 'Discord > Paramètres : désactive l''overlay en jeu et l''accélération matérielle.')
    'steam'              = @('Steam', 'Ferme Steam (ses téléchargements continuent pendant Fortnite).')
    'steamwebhelper'     = @('Steam', 'Ferme Steam (ses téléchargements continuent pendant Fortnite).')
    'EpicWebHelper'      = @('Launcher Epic (téléchargement / boutique)', 'Ne laisse pas un autre jeu se mettre à jour dans le launcher pendant que tu joues.')
    'Spotify'            = @('Spotify', 'Spotify > Paramètres : désactive l''accélération matérielle.')
    'obs64'              = @('OBS (enregistrement / stream)', 'Normal si tu enregistres : utilise l''encodeur de la carte graphique (NVENC / AMF).')
    'Medal'              = @('Medal (enregistrement de clips)', 'Ferme Medal si tu n''enregistres pas.')
    'Overwolf'           = @('Overwolf (overlay)', 'Ferme Overwolf pendant que tu joues.')
    'iCUE'               = @('Corsair iCUE (RGB)', 'Ferme iCUE ou limite ses effets RGB.')
    'wallpaper64'        = @('Wallpaper Engine', 'Wallpaper Engine > Paramètres : « Pause » quand une autre appli est en plein écran.')
    'wallpaper32'        = @('Wallpaper Engine', 'Wallpaper Engine > Paramètres : « Pause » quand une autre appli est en plein écran.')
    'System'             = @('Système Windows (pilotes)', 'Souvent un pilote : mets à jour le pilote graphique, réseau (Wi-Fi) et le chipset.')
    'dwm'                = @('Compositeur d''affichage Windows', 'Signe que le jeu n''est pas en vrai plein écran : mets « Plein écran » dans Fortnite.')
}
# Processus ignorés dans la recherche de coupables (le jeu, la mesure elle-même, l'inactivité).
$script:Ignorer = @('Idle', 'FortniteClient-Win64-Shipping', 'powershell', 'pwsh', 'PresentMon-2.6.0-x64', 'conhost', 'EasyAntiCheat', 'EasyAntiCheat_EOS')

# ---------------------------------------------------------------------------
# Affichage
# ---------------------------------------------------------------------------
function Write-Titre([string]$Texte)     { Write-Host ''; Write-Host "[*] $Texte" -ForegroundColor Cyan }
function Write-Ok([string]$Texte)        { Write-Host "    [OK] $Texte" -ForegroundColor Green }
function Write-Info([string]$Texte)      { Write-Host "         $Texte" -ForegroundColor Gray }
function Write-Attention([string]$Texte) { Write-Host "    [!]  $Texte" -ForegroundColor Yellow }
function Write-Grave([string]$Texte)     { Write-Host "    [X]  $Texte" -ForegroundColor Red }

function Write-Section([string]$Texte) {
    Write-Host ''
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host "   $Texte" -ForegroundColor Magenta
    Write-Host '  ==================================================' -ForegroundColor Magenta
}

function Read-Oui([string]$Question) {
    $reponse = "$(Read-Host "  $Question (O/N)")"
    return ($reponse -match '^\s*[oOyY]')
}

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Bip([int]$Frequence, [int]$Duree) {
    try { [Console]::Beep($Frequence, $Duree) } catch { }
}

function Format-Ms($Valeur) {
    if ($null -eq $Valeur) { return 'n/a' }
    return ([double]$Valeur).ToString('0.0', $script:Inv) + ' ms'
}

# ---------------------------------------------------------------------------
# Point de restauration (filet de sécurité, un par jour)
# ---------------------------------------------------------------------------
function Get-DatePoint($Point) {
    try { return $Point.ConvertToDateTime($Point.CreationTime) } catch { }
    try { return [Management.ManagementDateTimeConverter]::ToDateTime([string]$Point.CreationTime) } catch { }
    return $null
}

function Get-PointRecent {
    foreach ($p in @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object { $_.Description -eq $script:NomPoint })) {
        $date = Get-DatePoint $p
        if ($date -and $date -gt (Get-Date).AddHours(-24)) { return $date }
    }
    return $null
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
    $avant = 0
    $points = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue)
    if ($points.Count) { $avant = [int](($points | Measure-Object -Property SequenceNumber -Maximum).Maximum) }
    try {
        New-ItemProperty -LiteralPath $cle -Name $nom -Value 0 -PropertyType DWord -Force | Out-Null
        Checkpoint-Computer -Description $script:NomPoint -RestorePointType 'MODIFY_SETTINGS'
    } finally {
        if ($existait) { New-ItemProperty -LiteralPath $cle -Name $nom -Value $ancienne -PropertyType DWord -Force | Out-Null }
        else { Remove-ItemProperty -LiteralPath $cle -Name $nom -ErrorAction SilentlyContinue }
    }
    $nouveau = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
        Where-Object { [int]$_.SequenceNumber -gt $avant -and $_.Description -eq $script:NomPoint })
    if ($nouveau.Count -eq 0) { throw 'Windows n''a pas créé le point de restauration.' }
}

# Retourne $true si on peut continuer.
function Initialize-PointRestauration {
    Write-Titre 'Point de restauration (filet de sécurité)'
    $recent = Get-PointRecent
    if ($recent) {
        Write-Ok ("Point « {0} » déjà créé le {1:dd/MM à HH:mm}." -f $script:NomPoint, $recent)
        return $true
    }
    Write-Info 'Création du point de restauration (une fois par jour, jusqu''à 1 minute)...'
    try {
        New-PointRestaurationGaranti
        Write-Ok "Point de restauration « $($script:NomPoint) » créé et vérifié."
        return $true
    } catch {
        Write-Attention "Impossible de créer le point de restauration : $($_.Exception.Message)"
        Write-Info 'Ce programme ne modifie rien dans Windows ni dans Fortnite : continuer est sans risque.'
        return (Read-Oui 'Continuer quand même ?')
    }
}

function Open-RestaurationSysteme {
    Write-Section 'REVENIR EN ARRIÈRE'
    Write-Info 'Ce programme ne modifie rien. Mais si tu as changé des réglages depuis et que ça ne te plaît pas :'
    Write-Info "dans la fenêtre qui s'ouvre : « Choisir un autre point de restauration » > Suivant,"
    Write-Info "choisis « $($script:NomPoint) » (ou un point plus ancien) > Suivant > Terminer."
    Write-Info 'Le PC redémarre tout seul. Tes fichiers personnels ne sont pas touchés.'
    Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\rstrui.exe')
}

# ---------------------------------------------------------------------------
# Statistiques
# ---------------------------------------------------------------------------
function ConvertTo-Nombre($Texte) {
    $d = 0.0
    if ([double]::TryParse([string]$Texte, [Globalization.NumberStyles]::Float, $script:Inv, [ref]$d)) { return $d }
    return $null
}

# Centile p (0..1) d'une liste déjà triée.
function Get-Centile([double[]]$Trie, [double]$P) {
    if ($Trie.Count -eq 0) { return $null }
    $i = [math]::Ceiling($P * $Trie.Count) - 1
    if ($i -lt 0) { $i = 0 }
    if ($i -ge $Trie.Count) { $i = $Trie.Count - 1 }
    return $Trie[$i]
}

function Get-Stats([System.Collections.Generic.List[double]]$Valeurs) {
    if ($null -eq $Valeurs -or $Valeurs.Count -eq 0) { return $null }
    $trie = $Valeurs.ToArray()
    [array]::Sort($trie)
    $somme = 0.0
    foreach ($v in $trie) { $somme += $v }
    return [pscustomobject]@{
        Nombre  = $trie.Count
        Moyenne = $somme / $trie.Count
        Mediane = Get-Centile $trie 0.5
        P95     = Get-Centile $trie 0.95
        P99     = Get-Centile $trie 0.99
        Max     = $trie[$trie.Count - 1]
    }
}

# ---------------------------------------------------------------------------
# PresentMon (téléchargé une fois, vérifié : empreinte + signature Intel)
# ---------------------------------------------------------------------------
function Test-FichierPresentMon([string]$Chemin) {
    if (-not (Test-Path -LiteralPath $Chemin)) { return $false }
    $hash = (Get-FileHash -LiteralPath $Chemin -Algorithm SHA256).Hash
    if ($hash -ne $script:PresentMon.Sha256) { return $false }
    $signature = Get-AuthenticodeSignature -LiteralPath $Chemin
    return ([string]$signature.Status -eq 'Valid' -and [string]$signature.SignerCertificate.Subject -match 'Intel Corporation')
}

function Get-PresentMon {
    $candidats = New-Object System.Collections.Generic.List[string]
    if ($PSScriptRoot) { $candidats.Add((Join-Path $PSScriptRoot $script:PresentMon.Fichier)) }
    $candidats.Add((Join-Path $script:DossierOutils $script:PresentMon.Fichier))
    foreach ($c in $candidats) { if (Test-FichierPresentMon $c) { return $c } }

    Write-Info "Première utilisation : téléchargement de PresentMon $($script:PresentMon.Version) (outil d'Intel, 1 Mo)..."
    if (-not (Test-Path -LiteralPath $script:DossierOutils)) { New-Item -ItemType Directory -Path $script:DossierOutils -Force | Out-Null }
    $destination = Join-Path $script:DossierOutils $script:PresentMon.Fichier
    $temporaire = "$destination.telechargement"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ancienneProgression = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $script:PresentMon.Url -OutFile $temporaire -UseBasicParsing
    } finally {
        $ProgressPreference = $ancienneProgression
    }
    if (-not (Test-FichierPresentMon $temporaire)) {
        Remove-Item -LiteralPath $temporaire -Force -ErrorAction SilentlyContinue
        throw 'le fichier téléchargé n''est pas l''original signé par Intel : refusé par sécurité.'
    }
    Move-Item -LiteralPath $temporaire -Destination $destination -Force
    Write-Ok 'PresentMon téléchargé et vérifié (empreinte + signature Intel).'
    return $destination
}

# ---------------------------------------------------------------------------
# Surveillance du PC pendant la mesure (1 échantillon par seconde)
# ---------------------------------------------------------------------------
function Get-TempsProcesseur {
    $temps = @{}
    foreach ($p in Get-Process) {
        try {
            $t = $p.TotalProcessorTime
            if ($null -ne $t) { $temps[$p.Id] = @($p.ProcessName, $t.TotalMilliseconds) }
        } catch { }
    }
    return $temps
}

function Watch-Systeme([int]$Duree, [datetime]$Debut) {
    $coeurs = [Environment]::ProcessorCount
    $precedent = Get-TempsProcesseur
    $instantPrecedent = Get-Date
    $echantillons = New-Object System.Collections.Generic.List[object]
    for ($s = 1; $s -le $Duree; $s++) {
        $attente = ($Debut.AddSeconds($s) - (Get-Date)).TotalMilliseconds
        if ($attente -gt 0) { Start-Sleep -Milliseconds ([int]$attente) }
        $instant = Get-Date
        $ecoule = [math]::Max(1.0, ($instant - $instantPrecedent).TotalMilliseconds)
        $instantPrecedent = $instant

        $actuel = Get-TempsProcesseur
        $conso = @{}
        foreach ($id in $actuel.Keys) {
            if (-not $precedent.ContainsKey($id)) { continue }
            $nom = $actuel[$id][0]
            $pourcent = ($actuel[$id][1] - $precedent[$id][1]) / $ecoule / $coeurs * 100
            if ($pourcent -gt 0.3) {
                if ($conso.ContainsKey($nom)) { $conso[$nom] += $pourcent } else { $conso[$nom] = $pourcent }
            }
        }
        $precedent = $actuel

        $disque = $null; $reseau = $null
        try {
            $d = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'"
            $disque = [math]::Min(100, [int]$d.PercentDiskTime)
        } catch { }
        try {
            $interfaces = @(Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface)
            $reseau = [double](($interfaces | Measure-Object -Property BytesTotalPersec -Sum).Sum)
        } catch { }

        $echantillons.Add([pscustomobject]@{ Seconde = $s; Cpu = $conso; Disque = $disque; Reseau = $reseau })
        Write-Progress -Activity 'Mesure en cours : joue, ÉDITE et CLIQUE dans Fortnite !' `
            -Status "Encore $($Duree - $s) s" -PercentComplete ([int]($s * 100 / $Duree))
    }
    Write-Progress -Activity 'Mesure en cours' -Completed
    return $echantillons
}

# Programme hors jeu le plus gourmand pendant une seconde donnée.
function Get-CoupableSeconde($Echantillon) {
    $meilleur = $null; $max = 0.0
    foreach ($nom in $Echantillon.Cpu.Keys) {
        if ($script:Ignorer -contains $nom) { continue }
        if ($Echantillon.Cpu[$nom] -gt $max) { $max = $Echantillon.Cpu[$nom]; $meilleur = $nom }
    }
    return [pscustomobject]@{ Nom = $meilleur; Cpu = $max }
}

function Get-NomLisible([string]$Processus) {
    if ($script:Coupables.ContainsKey($Processus)) { return $script:Coupables[$Processus][0] }
    return $Processus
}

# ---------------------------------------------------------------------------
# Analyse du fichier PresentMon
# ---------------------------------------------------------------------------
function Get-Colonne($Entetes, [string[]]$Noms) {
    foreach ($n in $Noms) { if ($Entetes -contains $n) { return $n } }
    return $null
}

function Get-AnalyseCsv([string]$Chemin) {
    $lignes = @(Import-Csv -LiteralPath $Chemin)
    $lignes = @($lignes | Where-Object { [string]$_.Application -match 'FortniteClient' })
    if ($lignes.Count -lt 30) { throw "seulement $($lignes.Count) images enregistrées : Fortnite était-il au premier plan, en partie ?" }
    $entetes = @($lignes[0].PSObject.Properties.Name)

    $cTemps   = Get-Colonne $entetes @('TimeInSeconds', 'CPUStartTimeInSeconds', 'CPUStartTime')
    $cImage   = Get-Colonne $entetes @('MsBetweenPresents', 'FrameTime')
    $cEntree  = Get-Colonne $entetes @('MsAllInputToPhotonLatency', 'AllInputToPhotonLatency')
    $cClic    = Get-Colonne $entetes @('MsClickToPhotonLatency', 'ClickToPhotonLatency')
    $cPcl     = Get-Colonne $entetes @('MsPCLatency')
    $cGpu     = Get-Colonne $entetes @('MsGPUBusy', 'GPUBusy')
    $cCpu     = Get-Colonne $entetes @('MsCPUBusy', 'CPUBusy')
    $cAffiche = Get-Colonne $entetes @('MsUntilDisplayed')
    if (-not $cImage) { throw 'format de mesure inconnu (colonne du temps entre images absente).' }

    $images = New-Object 'System.Collections.Generic.List[double]'
    $temps = New-Object 'System.Collections.Generic.List[double]'
    $entrees = New-Object 'System.Collections.Generic.List[double]'
    $clics = New-Object 'System.Collections.Generic.List[double]'
    $pcl = New-Object 'System.Collections.Generic.List[double]'
    $gpu = New-Object 'System.Collections.Generic.List[double]'
    $cpu = New-Object 'System.Collections.Generic.List[double]'
    $affiche = New-Object 'System.Collections.Generic.List[double]'
    $modes = @{}; $vsync = @{}; $dechirure = @{}

    foreach ($l in $lignes) {
        $ft = ConvertTo-Nombre $l.$cImage
        if ($null -ne $ft -and $ft -gt 0 -and $ft -lt 1000) {
            $images.Add($ft)
            $t = 0.0
            if ($cTemps) { $v = ConvertTo-Nombre $l.$cTemps; if ($null -ne $v) { $t = $v } }
            $temps.Add($t)
        }
        foreach ($paire in @(@($cEntree, $entrees), @($cClic, $clics), @($cPcl, $pcl), @($cGpu, $gpu), @($cCpu, $cpu), @($cAffiche, $affiche))) {
            if (-not $paire[0]) { continue }
            $v = ConvertTo-Nombre $l.($paire[0])
            if ($null -ne $v -and $v -gt 0 -and $v -lt 1000) { $paire[1].Add($v) }
        }
        $m = [string]$l.PresentMode;   if ($m) { $modes[$m] = 1 + [int]$modes[$m] }
        $s = [string]$l.SyncInterval;  if ($s) { $vsync[$s] = 1 + [int]$vsync[$s] }
        $a = [string]$l.AllowsTearing; if ($a) { $dechirure[$a] = 1 + [int]$dechirure[$a] }
    }
    if ($images.Count -lt 30) { throw 'trop peu d''images valides dans la mesure.' }

    $statsImages = Get-Stats $images
    # Saccade = image beaucoup plus longue que la normale.
    $seuil = [math]::Max(2.5 * $statsImages.Mediane, $statsImages.Mediane + 5)
    $saccades = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $images.Count; $i++) {
        if ($images[$i] -gt $seuil) { $saccades.Add([pscustomobject]@{ Temps = $temps[$i]; Ms = $images[$i] }) }
    }
    $duree = [math]::Max(1.0, ($temps | Measure-Object -Maximum).Maximum - ($temps | Measure-Object -Minimum).Minimum)

    $modePrincipal = $null
    if ($modes.Count) { $modePrincipal = ($modes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key }
    $partVsync = 0.0
    if ($vsync.Count) {
        $total = 0; $avecVsync = 0
        foreach ($k in $vsync.Keys) { $total += $vsync[$k]; if ([int]$k -gt 0) { $avecVsync += $vsync[$k] } }
        if ($total) { $partVsync = $avecVsync / $total }
    }

    return [pscustomobject]@{
        Images        = $statsImages
        FpsMoyen      = 1000 / $statsImages.Moyenne
        Fps1Bas       = 1000 / $statsImages.P99
        Saccades      = $saccades
        SeuilSaccade  = $seuil
        Duree         = $duree
        Entree        = Get-Stats $entrees
        Clic          = Get-Stats $clics
        Pcl           = Get-Stats $pcl
        Gpu           = Get-Stats $gpu
        Cpu           = Get-Stats $cpu
        Affichage     = Get-Stats $affiche
        ModePrincipal = $modePrincipal
        Modes         = $modes
        PartVsync     = $partVsync
    }
}

# ---------------------------------------------------------------------------
# Écran (lecture seule)
# ---------------------------------------------------------------------------
function Initialize-Ecran {
    if ('OptiLatence.Ecran' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace OptiLatence {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
        public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
        public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;
        public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;
        public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;
        public int dmPanningWidth; public int dmPanningHeight;
    }
    public static class Ecran {
        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
        static DEVMODE Vide() { DEVMODE d = new DEVMODE(); d.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return d; }
        public static int Actuelle() { DEVMODE d = Vide(); EnumDisplaySettings(null, -1, ref d); return d.dmDisplayFrequency; }
        public static int Maximale() {
            DEVMODE a = Vide(); EnumDisplaySettings(null, -1, ref a);
            int max = a.dmDisplayFrequency; DEVMODE m = Vide();
            for (int i = 0; EnumDisplaySettings(null, i, ref m); i++) {
                if (m.dmPelsWidth == a.dmPelsWidth && m.dmPelsHeight == a.dmPelsHeight && m.dmDisplayFrequency > max) max = m.dmDisplayFrequency;
                m = Vide();
            }
            return max;
        }
    }
}
'@
}

function Get-FrequencesEcran {
    try {
        Initialize-Ecran
        return [pscustomobject]@{ Actuelle = [OptiLatence.Ecran]::Actuelle(); Maximale = [OptiLatence.Ecran]::Maximale() }
    } catch { return $null }
}

# ---------------------------------------------------------------------------
# Rapport de mesure
# ---------------------------------------------------------------------------
function Get-Note($Ms) {
    if ($null -eq $Ms) { return @('?', 'Gray') }
    if ($Ms -le 20) { return @('EXCELLENT', 'Green') }
    if ($Ms -le 30) { return @('TRÈS BON', 'Green') }
    if ($Ms -le 45) { return @('MOYEN', 'Yellow') }
    return @('LENT', 'Red')
}

# Ajoute un conseil avec sa priorité (1 = le plus important).
function Add-Conseil($Liste, [int]$Priorite, [string]$Texte) {
    $Liste.Add([pscustomobject]@{ Priorite = $Priorite; Ordre = $Liste.Count; Texte = $Texte })
}

function Show-Rapport($A, $Echantillons, $Ecran) {
    $conseils = New-Object System.Collections.Generic.List[object]

    Write-Section 'RÉSULTAT DE LA MESURE'

    # 1. Délai clic / touche -> écran
    Write-Titre 'Ton délai clic / touche -> écran (mesuré)'
    $reference = $null
    if ($A.Entree) {
        $reference = $A.Entree.Mediane
        $note = Get-Note $reference
        Write-Host ("    Délai habituel : {0}   (pire 5 % : {1})   -> {2}" -f (Format-Ms $A.Entree.Mediane), (Format-Ms $A.Entree.P95), $note[0]) -ForegroundColor $note[1]
        if ($A.Clic) { Write-Info ("Rien que les clics souris : {0} (sur {1} images avec un clic)" -f (Format-Ms $A.Clic.Mediane), $A.Clic.Nombre) }
        Write-Info 'C''est le temps entre ton action et l''image à l''écran, côté PC (souris et dalle de l''écran en plus).'
    } else {
        Write-Attention 'Pas assez de clics / touches pendant la mesure pour calculer ce délai.'
        Write-Info 'Refais la mesure en ÉDITANT et en CLIQUANT beaucoup.'
    }
    if ($A.Pcl) {
        Write-Ok ("NVIDIA Reflex détecté : latence PC mesurée par Reflex = {0}" -f (Format-Ms $A.Pcl.Mediane))
    }

    # 2. FPS et stabilité
    Write-Titre 'FPS et saccades'
    Write-Info ("FPS moyen : {0:0}   |   1 % les plus bas : {1:0} FPS   |   image normale : {2}" -f $A.FpsMoyen, $A.Fps1Bas, (Format-Ms $A.Images.Mediane))
    $parMinute = $A.Saccades.Count * 60 / $A.Duree
    if ($A.Saccades.Count -eq 0) {
        Write-Ok 'Aucune saccade : image parfaitement régulière.'
    } elseif ($parMinute -le 5) {
        Write-Ok ("{0} petite(s) saccade(s) en {1:0} s : c'est propre." -f $A.Saccades.Count, $A.Duree)
    } else {
        Write-Attention ("{0} saccades en {1:0} s (images de plus de {2}) : c'est ce que tu ressens comme du « lag »." -f $A.Saccades.Count, $A.Duree, (Format-Ms $A.SeuilSaccade))
    }
    if ($Ecran -and $Ecran.Actuelle -gt 0) {
        if ($Ecran.Actuelle -lt $Ecran.Maximale) {
            Write-Grave "Ton écran tourne à $($Ecran.Actuelle) Hz alors qu'il peut aller à $($Ecran.Maximale) Hz !"
            Add-Conseil $conseils 1 "Mets ton écran à $($Ecran.Maximale) Hz : Paramètres > Système > Écran > Affichage avancé (gros gain de délai)."
        }
        if ($A.FpsMoyen -lt 0.9 * $Ecran.Actuelle) {
            Write-Info ("Ton écran affiche {0} images/s mais le PC n'en produit que {1:0} en moyenne." -f $Ecran.Actuelle, $A.FpsMoyen)
        }
    }

    # 3. Coupables des saccades
    if ($A.Saccades.Count -gt 0 -and $Echantillons.Count -gt 0) {
        Write-Titre 'Qui cause les saccades ?'
        $compte = @{}
        $disqueSature = 0; $reseauCharge = 0
        $secondesVues = @{}
        foreach ($sac in $A.Saccades) {
            $s = [int][math]::Ceiling($sac.Temps)
            if ($secondesVues.ContainsKey($s)) { continue }
            $secondesVues[$s] = $true
            $meilleur = $null
            foreach ($decalage in @(0, -1, 1)) {
                $e = $Echantillons | Where-Object { $_.Seconde -eq ($s + $decalage) } | Select-Object -First 1
                if (-not $e) { continue }
                $c = Get-CoupableSeconde $e
                if ($c.Nom -and (-not $meilleur -or $c.Cpu -gt $meilleur.Cpu)) { $meilleur = $c }
                if ($decalage -eq 0) {
                    if ($null -ne $e.Disque -and $e.Disque -ge 80) { $disqueSature++ }
                    if ($null -ne $e.Reseau -and $e.Reseau -ge 5MB) { $reseauCharge++ }
                }
            }
            if ($meilleur -and $meilleur.Cpu -ge 4) {
                if ($compte.ContainsKey($meilleur.Nom)) { $compte[$meilleur.Nom]++ } else { $compte[$meilleur.Nom] = 1 }
            }
        }
        if ($compte.Count -eq 0 -and $disqueSature -eq 0 -and $reseauCharge -eq 0) {
            Write-Ok 'Aucun programme en fond ne ressort : les saccades viennent du jeu lui-même (chargements, effets).'
        }
        foreach ($k in ($compte.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 4)) {
            Write-Attention ("{0} : actif pendant {1} saccade(s)" -f (Get-NomLisible $k.Key), $k.Value)
            if ($script:Coupables.ContainsKey($k.Key)) { Add-Conseil $conseils 3 $script:Coupables[$k.Key][1] }
        }
        if ($disqueSature -gt 0) {
            Write-Attention "Disque saturé pendant $disqueSature saccade(s) (mise à jour, copie, antivirus...)."
            Add-Conseil $conseils 3 'Évite les téléchargements, copies de fichiers et mises à jour pendant que tu joues.'
        }
        if ($reseauCharge -gt 0) {
            Write-Attention "Gros téléchargement en cours pendant $reseauCharge saccade(s)."
            Add-Conseil $conseils 3 'Un téléchargement tournait pendant ta partie : coupe-le (Steam, Epic, Windows Update, navigateur).'
        }
    }

    # 4. Programmes en fond les plus gourmands sur toute la mesure
    if ($Echantillons.Count -gt 0) {
        $moyennes = @{}
        foreach ($e in $Echantillons) {
            foreach ($nom in $e.Cpu.Keys) {
                if ($script:Ignorer -contains $nom) { continue }
                if ($moyennes.ContainsKey($nom)) { $moyennes[$nom] += $e.Cpu[$nom] } else { $moyennes[$nom] = $e.Cpu[$nom] }
            }
        }
        $gros = @($moyennes.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{ Nom = $_.Key; Cpu = $_.Value / $Echantillons.Count } } |
            Where-Object { $_.Cpu -ge 2 } | Sort-Object -Property Cpu -Descending | Select-Object -First 5)
        if ($gros.Count -gt 0) {
            Write-Titre 'Programmes qui tournaient en fond pendant ta partie'
            foreach ($g in $gros) {
                Write-Info ("{0,-45} {1,5:0.0} % du processeur" -f (Get-NomLisible $g.Nom), $g.Cpu)
                if ($script:Coupables.ContainsKey($g.Nom) -and $g.Cpu -ge 3) { Add-Conseil $conseils 5 $script:Coupables[$g.Nom][1] }
            }
        }
    }

    # 5. Chemin d'affichage
    Write-Titre 'Comment l''image arrive à l''écran'
    $mode = [string]$A.ModePrincipal
    if ($mode -match '^Hardware') {
        Write-Ok "Mode « $mode » : affichage direct, le meilleur pour le délai."
    } elseif ($mode -match '^Composed') {
        Write-Grave "Mode « $mode » : l'image passe par le compositeur de Windows = environ 1 image de délai EN PLUS."
        Add-Conseil $conseils 2 'Fortnite : mets « Plein écran » (pas fenêtré), ferme les overlays (Discord, NVIDIA, Xbox Game Bar), et évite les fenêtres par-dessus le jeu.'
    } elseif ($mode) {
        Write-Info "Mode d'affichage : $mode"
    }
    if ($A.PartVsync -ge 0.5) {
        Write-Grave 'V-Sync ACTIVÉE dans le jeu : c''est une des plus grosses sources de délai.'
        Add-Conseil $conseils 1 'Fortnite > Paramètres > Vidéo : désactive la « Synchronisation verticale ».'
    } else {
        Write-Ok 'V-Sync du jeu désactivée.'
    }

    # 6. Qui limite : processeur ou carte graphique
    if ($A.Gpu -and $A.Images) {
        Write-Titre 'Qui limite tes FPS ?'
        $chargeGpu = $A.Gpu.Mediane / $A.Images.Mediane
        if ($chargeGpu -ge 0.9) {
            Write-Attention ("Carte graphique à fond (~{0:0} % du temps de chaque image)." -f (100 * [math]::Min(1, $chargeGpu)))
            if ($A.Pcl) {
                Write-Info 'Reflex est actif : il limite déjà le délai ajouté. Pour plus de FPS, baisse la qualité graphique.'
            } else {
                Write-Info 'Une carte graphique à 100 % fait attendre les images = délai en plus.'
                Add-Conseil $conseils 2 'Carte graphique à 100 % : active NVIDIA Reflex « Activé + Boost » (ou AMD Anti-Lag), sinon plafonne les FPS un peu sous ce que tu tiens.'
            }
            Add-Conseil $conseils 4 'Pour soulager la carte graphique : mode de rendu « Performance » ou résolution 3D plus basse dans Fortnite.'
        } else {
            Write-Ok ("Ta carte graphique a de la marge (~{0:0} % utilisée) : c'est le processeur ou le jeu qui fixe les FPS." -f (100 * $chargeGpu))
            if ($A.FpsMoyen -lt 144) {
                Add-Conseil $conseils 4 'Processeur limitant : mode de rendu « Performance », distance d''affichage moyenne, et ferme les programmes en fond (ou MODE-PARTIE.bat).'
            }
        }
    }

    # 7. Conseils
    Write-Titre 'CE QUE TU PEUX FAIRE (par ordre d''importance)'
    $uniques = @($conseils | Sort-Object -Property Priorite, Ordre | ForEach-Object { $_.Texte } | Select-Object -Unique)
    if ($uniques.Count -eq 0) {
        Write-Ok 'Rien à corriger côté PC : ton système est bien réglé.'
    } else {
        $n = 1
        foreach ($c in $uniques) { Write-Host ("    {0}. {1}" -f $n, $c) -ForegroundColor White; $n++ }
    }
    Write-Info 'Toujours valable : souris à 1000 Hz (Epic conseille 500 à 1000 Hz), câble Ethernet, MODE-PARTIE.bat.'

    return [pscustomobject]@{ Reference = $reference; Conseils = $uniques }
}

function Save-Historique($A, [string]$IdMesure) {
    $historique = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $script:FichierHistorique) {
        try {
            $anciens = Get-Content -LiteralPath $script:FichierHistorique -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($x in $anciens) { [void]$historique.Add($x) }
        } catch { }
    }
    $entree = [pscustomobject]@{
        Date      = (Get-Date).ToString('dd/MM/yyyy HH:mm')
        Id        = $IdMesure
        DelaiMs   = $(if ($A.Entree) { [math]::Round($A.Entree.Mediane, 1) } else { $null })
        Delai95Ms = $(if ($A.Entree) { [math]::Round($A.Entree.P95, 1) } else { $null })
        Fps       = [math]::Round($A.FpsMoyen, 0)
        Fps1Bas   = [math]::Round($A.Fps1Bas, 0)
        Saccades  = $A.Saccades.Count
        Mode      = [string]$A.ModePrincipal
    }
    $precedent = $null
    if ($historique.Count -gt 0) { $precedent = $historique[$historique.Count - 1] }
    [void]$historique.Add($entree)
    $json = ConvertTo-Json -InputObject @($historique.ToArray()) -Depth 4
    [System.IO.File]::WriteAllText($script:FichierHistorique, $json, (New-Object System.Text.UTF8Encoding($false)))

    if ($precedent -and $null -ne $precedent.DelaiMs -and $null -ne $entree.DelaiMs) {
        Write-Titre 'Comparaison avec ta mesure précédente'
        $diff = $entree.DelaiMs - [double]$precedent.DelaiMs
        $texte = "Délai : {0} -> {1} ms   |   FPS : {2} -> {3}   |   saccades : {4} -> {5}" -f `
            $precedent.DelaiMs, $entree.DelaiMs, $precedent.Fps, $entree.Fps, $precedent.Saccades, $entree.Saccades
        if ($diff -le -1) { Write-Ok "$texte   (MIEUX : -$([math]::Abs($diff)) ms)" }
        elseif ($diff -ge 1) { Write-Attention "$texte   (moins bien : +$diff ms)" }
        else { Write-Info "$texte   (pareil)" }
    }
}

function Invoke-Mesure {
    Write-Section "MESURE DE TA LATENCE ($Secondes secondes)"
    if (-not (Test-Path -LiteralPath $script:DossierMesures)) { New-Item -ItemType Directory -Path $script:DossierMesures -Force | Out-Null }

    try { $exe = Get-PresentMon } catch {
        Write-Grave "PresentMon indisponible : $($_.Exception.Message)"
        Write-Info 'Vérifie ta connexion Internet et relance. (Ou télécharge PresentMon-2.6.0-x64.exe sur le GitHub'
        Write-Info 'officiel GameTechDev/PresentMon et mets-le à côté de ce programme.)'
        return
    }

    if (-not (Get-Process -Name $script:ProcessusJeu -ErrorAction SilentlyContinue)) {
        Write-Attention 'Fortnite n''est pas lancé.'
        Write-Info 'Lance Fortnite et va dans une partie : l''idéal est une carte Créatif d''entraînement'
        Write-Info 'à l''édition (ou une partie normale), pour mesurer en conditions réelles.'
        Read-Host '  Appuie sur Entrée quand tu es EN JEU dans Fortnite' | Out-Null
        if (-not (Get-Process -Name $script:ProcessusJeu -ErrorAction SilentlyContinue)) { Write-Grave 'Fortnite n''est toujours pas lancé.'; return }
    }

    Write-Titre 'Comment ça marche'
    Write-Info "1. Appuie sur Entrée, puis retourne dans Fortnite dans les 5 secondes (Alt+Tab)."
    Write-Info "2. Un BIP marque le début : pendant $Secondes s, ÉDITE, CONSTRUIS et CLIQUE beaucoup"
    Write-Info '   (le délai est mesuré à chaque clic et à chaque touche).'
    Write-Info '3. Un DOUBLE BIP marque la fin : reviens sur cette fenêtre pour voir le résultat.'
    Write-Info 'Rien n''est modifié, ni dans Windows ni dans Fortnite : c''est uniquement une mesure.'
    Read-Host '  Appuie sur Entrée pour commencer' | Out-Null
    for ($i = 5; $i -ge 1; $i--) { Write-Host "    Retourne dans Fortnite : début dans $i..." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }

    $id = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
    $csv = Join-Path $script:DossierMesures "mesure-$id.csv"
    $arguments = @('--process_name', "$($script:ProcessusJeu).exe", '--output_file', "`"$csv`"",
        '--timed', "$Secondes", '--terminate_after_timed', '--stop_existing_session',
        '--session_name', 'FortniteOptiAnalyse', '--no_console_stats', '--track_pc_latency')
    $processus = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru -WindowStyle Hidden
    Invoke-Bip 880 250
    $debut = Get-Date
    $echantillons = Watch-Systeme -Duree $Secondes -Debut $debut
    if (-not $processus.WaitForExit(30000)) { try { $processus.Kill() } catch { } }
    Invoke-Bip 988 200; Invoke-Bip 1318 300

    if (-not (Test-Path -LiteralPath $csv)) {
        Write-Grave 'Aucune image enregistrée.'
        Write-Info 'Fortnite doit être au premier plan et en jeu pendant la mesure. Relance la mesure.'
        return
    }
    try {
        $analyse = Get-AnalyseCsv $csv
    } catch {
        Write-Grave "Mesure inexploitable : $($_.Exception.Message)"
        return
    }
    $ecran = Get-FrequencesEcran
    [void](Show-Rapport $analyse $echantillons $ecran)
    Save-Historique $analyse $id
    Write-Host ''
    Write-Info "Données brutes de la mesure : $csv"
    Write-Info 'Change UNE chose à la fois, puis refais une mesure pour voir si ça baisse vraiment.'
}

# ---------------------------------------------------------------------------
# Bilan des réglages (LECTURE SEULE)
# ---------------------------------------------------------------------------
function Get-ValeurRegistre([string]$Cle, [string]$Nom) {
    try {
        if (-not (Test-Path -LiteralPath $Cle)) { return $null }
        return (Get-ItemProperty -LiteralPath $Cle -Name $Nom -ErrorAction Stop).$Nom
    } catch { return $null }
}

function Get-ReglageIni([string]$Texte, [string]$Cle) {
    if ($Texte -match ('(?m)^[ \t]*' + [regex]::Escape($Cle) + '[ \t]*=[ \t]*([^\r\n]*)')) { return $Matches[1].Trim() }
    return $null
}

function Invoke-Bilan {
    Write-Section 'BILAN : ce qui peut ajouter du délai (lecture seule, rien n''est modifié)'
    $aCorriger = 0

    Write-Titre 'Écran'
    $ecran = Get-FrequencesEcran
    if ($ecran) {
        if ($ecran.Actuelle -lt $ecran.Maximale) {
            $aCorriger++
            Write-Grave "Écran à $($ecran.Actuelle) Hz alors qu'il peut aller à $($ecran.Maximale) Hz."
            Write-Info 'Paramètres > Système > Écran > Affichage avancé > Fréquence d''actualisation : prends la plus haute.'
        } else { Write-Ok "Écran à sa fréquence maximale ($($ecran.Actuelle) Hz)." }
    } else { Write-Info 'Fréquence de l''écran illisible.' }

    Write-Titre 'Fortnite (réglages lus, pas modifiés)'
    $ini = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
    if (Test-Path -LiteralPath $ini) {
        $texte = [System.IO.File]::ReadAllText($ini)
        $plein = Get-ReglageIni $texte 'FullscreenMode'
        if ($plein -eq '0') { Write-Ok 'Mode d''affichage : plein écran.' }
        elseif ($null -ne $plein) {
            $aCorriger++
            Write-Attention 'Mode d''affichage fenêtré ou plein écran fenêtré : souvent plus de délai.'
            Write-Info 'Fortnite > Paramètres > Vidéo > Mode de fenêtre : « Plein écran ».'
        }
        $vs = Get-ReglageIni $texte 'bUseVSync'
        if ($vs -eq 'True') { $aCorriger++; Write-Grave 'V-Sync activée : énorme source de délai. Désactive-la dans Paramètres > Vidéo.' }
        elseif ($vs -eq 'False') { Write-Ok 'V-Sync désactivée.' }
        $limite = ConvertTo-Nombre (Get-ReglageIni $texte 'FrameRateLimit')
        if ($null -ne $limite) {
            if ($limite -eq 0) { Write-Ok 'Limite de FPS : illimitée.' }
            elseif ($ecran -and $limite -lt $ecran.Maximale) {
                $aCorriger++
                Write-Attention ("Limite de FPS à {0:0}, sous la fréquence de ton écran ({1} Hz)." -f $limite, $ecran.Maximale)
                Write-Info 'Fortnite > Paramètres > Vidéo > Limite de FPS : au moins la fréquence de ton écran.'
            } else { Write-Ok ("Limite de FPS : {0:0}." -f $limite) }
        }
        $reflex = Get-ReglageIni $texte 'LatencyTweak2'
        $nvidia = $false
        try { $nvidia = @(Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' }).Count -gt 0 } catch { }
        if ($nvidia) {
            if ($reflex -eq '2') { Write-Ok 'NVIDIA Reflex : Activé + Boost.' }
            elseif ($reflex -eq '1') { Write-Ok 'NVIDIA Reflex : activé (« Activé + Boost » peut encore aider).' }
            elseif ($null -ne $reflex) { $aCorriger++; Write-Attention 'NVIDIA Reflex désactivé : active « Activé + Boost » dans Paramètres > Vidéo.' }
        }
        $flou = Get-ReglageIni $texte 'bMotionBlur'
        if ($flou -eq 'True') { Write-Attention 'Flou de mouvement activé : il gêne la lisibilité pendant les edits. Désactive-le.' }
    } else {
        Write-Info 'Fichier de réglages de Fortnite introuvable (lance le jeu une fois).'
    }
    Write-Info 'À vérifier toi-même dans Paramètres > Jeu : « Éditer au relâchement » ACTIVÉ, Construction turbo ACTIVÉE.'

    Write-Titre 'Windows'
    $plan = ''
    try { $plan = (& powercfg.exe /getactivescheme 2>$null | Out-String).Trim() } catch { }
    if ($plan -match 'conomie|saver') { $aCorriger++; Write-Grave "Plan d'alimentation « Économie d'énergie » : le processeur est bridé." }
    elseif ($plan -match '\((.+)\)') { Write-Ok "Plan d'alimentation : $($Matches[1])." }

    $modeJeu = Get-ValeurRegistre 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
    if ($modeJeu -eq 0) { $aCorriger++; Write-Attention 'Mode Jeu désactivé : Paramètres > Jeux > Mode Jeu > Activé.' }
    else { Write-Ok 'Mode Jeu activé.' }

    $enregistrement = Get-ValeurRegistre 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled'
    if ($enregistrement -eq 1) {
        $aCorriger++
        Write-Attention 'La Game Bar enregistre en continu les 30 dernières secondes : ça coûte des FPS.'
        Write-Info 'Paramètres > Jeux > Captures > « Enregistrer ce qui s''est passé » : Désactivé.'
    } else { Write-Ok 'Pas d''enregistrement vidéo en continu par la Game Bar.' }

    $vitesseSouris = Get-ValeurRegistre 'HKCU:\Control Panel\Mouse' 'MouseSpeed'
    if ($vitesseSouris -and [string]$vitesseSouris -ne '0') {
        Write-Attention '« Améliorer la précision du pointeur » activé (accélération souris dans les menus).'
        Write-Info 'Panneau de configuration > Souris > Options du pointeur : décoche-le.'
    } else { Write-Ok 'Accélération de la souris Windows désactivée.' }

    $hags = Get-ValeurRegistre 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
    if ($hags -eq 2) { Write-Ok 'Planification GPU accélérée par le matériel : activée.' }
    else { Write-Info 'Planification GPU accélérée par le matériel : désactivée (Paramètres > Écran > Graphiques). Effet faible.' }

    try {
        $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard
        if (@($dg.SecurityServicesRunning) -contains 2) {
            Write-Info 'Intégrité de la mémoire activée : protège Windows, mais coûte souvent 5 à 10 % de FPS (ton choix).'
        } else { Write-Ok 'Intégrité de la mémoire désactivée.' }
    } catch { }

    $preversions = Get-ValeurRegistre 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'IsContinuousInnovationOptedIn'
    if ($preversions -eq 1) {
        Write-Attention 'Les mises à jour « préversion » sont activées : elles peuvent échouer et se réessayer en fond.'
        Write-Info 'Windows Update : désactive « Recevez les dernières mises à jour dès qu''elles sont disponibles ».'
    }
    $pause = Get-ValeurRegistre 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'PauseUpdatesExpiryTime'
    if ($pause) {
        try { Write-Info ("Mises à jour suspendues jusqu'au {0:dd/MM/yyyy}." -f ([datetime]::Parse([string]$pause, $script:Inv))) } catch { }
    }
    $maj = @(Get-Process -Name 'TiWorker', 'MoUsoCoreWorker' -ErrorAction SilentlyContinue)
    if ($maj.Count -gt 0) {
        $aCorriger++
        Write-Attention 'Windows Update travaille EN CE MOMENT : ne joue pas avant la fin (ou suspends les mises à jour).'
    }

    Write-Titre 'Connexion'
    $actives = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
    $filaire = @($actives | Where-Object { -not ([string]$_.PhysicalMediaType -match '802\.11' -or [string]$_.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN') })
    if ($filaire.Count -gt 0) { Write-Ok "Câble Ethernet ($($filaire[0].LinkSpeed))." }
    elseif ($actives.Count -gt 0) { $aCorriger++; Write-Attention 'Wi-Fi : plus de pics de ping qu''en câble Ethernet.' }

    Write-Titre 'Programmes qui tournent en ce moment'
    $ouverts = @()
    foreach ($nom in $script:Coupables.Keys) {
        if (@('System', 'dwm', 'MsMpEng', 'SearchIndexer', 'SearchProtocolHost', 'TrustedInstaller', 'TiWorker', 'MoUsoCoreWorker') -contains $nom) { continue }
        if (Get-Process -Name $nom -ErrorAction SilentlyContinue) { $ouverts += $script:Coupables[$nom][0] }
    }
    $ouverts = @($ouverts | Select-Object -Unique)
    if ($ouverts.Count -eq 0) { Write-Ok 'Aucun programme gourmand connu n''est ouvert.' }
    else {
        foreach ($o in $ouverts) { Write-Info "- $o" }
        Write-Info 'Ferme ceux dont tu n''as pas besoin avant de jouer (ou lance MODE-PARTIE.bat).'
    }

    Write-Titre 'Rappels (impossibles à vérifier par logiciel)'
    Write-Info '- Souris : 1000 Hz dans son logiciel. Epic indique que 2000 Hz et plus peut faire chuter les FPS.'
    Write-Info '- Overlay Discord désactivé, overlay NVIDIA désactivé si tu ne t''en sers pas.'
    Write-Info '- BIOS : XMP / D.O.C.P. activé (RAM à pleine vitesse).'

    Write-Host ''
    if ($aCorriger -eq 0) { Write-Host '  ========= RIEN À CORRIGER : TOUT EST BIEN RÉGLÉ =========' -ForegroundColor Green }
    else { Write-Host "  ========= $aCorriger point(s) à corriger (en jaune / rouge au-dessus) =========" -ForegroundColor Yellow }
    Write-Info 'Rien n''a été modifié. Corrige ce que tu veux, puis vérifie l''effet avec « Mesurer ma latence ».'
}

# ---------------------------------------------------------------------------
# Historique
# ---------------------------------------------------------------------------
function Show-Historique {
    Write-Section 'HISTORIQUE DE TES MESURES'
    if (-not (Test-Path -LiteralPath $script:FichierHistorique)) { Write-Info 'Aucune mesure pour l''instant : lance « Mesurer ma latence ».'; return }
    # (Sous Windows PowerShell 5.1, ConvertFrom-Json renvoie le tableau en un seul bloc :
    #  on le range d'abord dans une variable pour pouvoir le parcourir ligne par ligne.)
    $brut = Get-Content -LiteralPath $script:FichierHistorique -Raw -Encoding UTF8 | ConvertFrom-Json
    $mesures = @($brut)
    Write-Host ''
    Write-Host ('   {0,-17} {1,10} {2,10} {3,6} {4,8} {5,9}' -f 'Date', 'Délai', 'Pire 5%', 'FPS', '1% bas', 'Saccades') -ForegroundColor White
    foreach ($m in $mesures) {
        $d = if ($null -ne $m.DelaiMs) { "$($m.DelaiMs) ms" } else { 'n/a' }
        $p = if ($null -ne $m.Delai95Ms) { "$($m.Delai95Ms) ms" } else { 'n/a' }
        Write-Host ('   {0,-17} {1,10} {2,10} {3,6} {4,8} {5,9}' -f $m.Date, $d, $p, $m.Fps, $m.Fps1Bas, $m.Saccades)
    }
    $avecDelai = @($mesures | Where-Object { $null -ne $_.DelaiMs })
    if ($avecDelai.Count -ge 2) {
        $meilleure = $avecDelai | Sort-Object -Property { [double]$_.DelaiMs } | Select-Object -First 1
        Write-Ok "Ta meilleure mesure : $($meilleure.DelaiMs) ms le $($meilleure.Date)."
    }
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------
function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Section 'ANALYSEUR DE LATENCE FORTNITE'
        Write-Host ''
        Write-Host '   1. MESURER MA LATENCE  (pendant que je joue / édite, 60 s)' -ForegroundColor Green
        Write-Host '   2. Bilan : ce qui peut ajouter du délai (lecture seule)'
        Write-Host '   3. Historique : comparer mes mesures'
        Write-Host '   4. Revenir en arrière (point de restauration)'
        Write-Host '   0. Quitter'
        Write-Host ''
        Write-Info 'Ce programme ne modifie rien : il mesure et il explique.'
        Write-Host ''
        $choix = "$(Read-Host '  Ton choix')".Trim()
        if ($choix -eq '0') { return }
        if ($choix -eq '1') { Invoke-Mesure }
        elseif ($choix -eq '2') { Invoke-Bilan }
        elseif ($choix -eq '3') { Show-Historique }
        elseif ($choix -eq '4') { Open-RestaurationSysteme }
        else { continue }
        Write-Host ''
        Read-Host '  Appuie sur Entrée pour revenir au menu' | Out-Null
    }
}

# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------
if ($env:OS -ne 'Windows_NT') {
    Write-Host 'Ce programme est fait pour Windows uniquement.' -ForegroundColor Red
    exit 1
}

# Les mesures d'affichage de Windows (ETW) demandent les droits administrateur.
if (-not (Test-Admin)) {
    Write-Host 'Demande des droits administrateur (nécessaires pour mesurer l''affichage)...' -ForegroundColor Yellow
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action -Secondes $Secondes"
    } catch {
        Write-Host 'Droits administrateur refusés : impossible de continuer.' -ForegroundColor Red
        Read-Host 'Appuie sur Entrée pour fermer' | Out-Null
    }
    exit
}

try { $Host.UI.RawUI.WindowTitle = 'Analyseur de latence Fortnite' } catch { }

if (-not (Initialize-PointRestauration)) {
    Write-Info 'Arrêté à ta demande : rien n''a été fait.'
    Read-Host '  Appuie sur Entrée pour fermer' | Out-Null
    exit
}

switch ($Action) {
    'Mesurer'    { Invoke-Mesure; Read-Host '  Appuie sur Entrée pour fermer' | Out-Null }
    'Bilan'      { Invoke-Bilan; Read-Host '  Appuie sur Entrée pour fermer' | Out-Null }
    'Historique' { Show-Historique; Read-Host '  Appuie sur Entrée pour fermer' | Out-Null }
    default      { Show-Menu }
}
