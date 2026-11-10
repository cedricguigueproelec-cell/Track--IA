<#
.SYNOPSIS
    Optimisation complète du PC pour Fortnite : ping, latence (input lag), FPS.

.DESCRIPTION
    Version 3. Menu par catégories + un bouton « TOUT OPTIMISER » + un
    « MODE PARTIE » à lancer avant chaque session (ping au minimum).

    N'applique que des réglages documentés et 100 % réversibles : chaque valeur
    est sauvegardée AVANT d'être modifiée, et l'option « Restaurer » remet tout
    exactement comme avant. Un point de restauration Windows est aussi créé.

    Ce script ne touche PAS :
      - aux fichiers du jeu ni à l'anti-cheat (Easy Anti-Cheat) -> aucun risque de ban
        (seul le fichier de RÉGLAGES de Fortnite est modifié, comme le ferait le menu du jeu) ;
      - à l'antivirus, au pare-feu ni aux mises à jour de sécurité.

.PARAMETER Action
    Menu (défaut), Tout, Partie, Connexion, Latence, Fps, Fortnite, Pc, Diagnostic, Restaurer.

.EXAMPLE
    Double-clic sur LANCER.bat (menu) ou MODE-PARTIE.bat (avant de jouer).
#>
[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Tout', 'Partie', 'Connexion', 'Latence', 'Fps', 'Fortnite', 'Pc', 'Diagnostic', 'Restaurer')]
    [string]$Action = 'Menu'
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constantes et état
# ---------------------------------------------------------------------------
$script:DossierSauvegarde = Join-Path $env:USERPROFILE 'FortniteOpti-Sauvegarde'
$script:FichierSauvegarde = Join-Path $script:DossierSauvegarde 'sauvegarde.json'
$script:RegexGuid         = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
$script:GuidUltimate      = 'e9a42b02-d5df-448d-aa00-03f14749eb61'  # Performances optimales
$script:GuidHautesPerf    = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'  # Performances élevées
$script:CleHvci           = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
$script:NomQos            = 'Fortnite - priorite reseau'
$script:ExeFortnite       = 'FortniteClient-Win64-Shipping.exe'
$script:FichierPartie     = Join-Path $script:DossierSauvegarde 'mode-partie.json'
$script:TachePartie       = 'FortniteOpti - reactiver la recherche Wi-Fi'

# Applis qui utilisent la connexion en fond (nom du processus = nom affiché).
$script:AppsGourmandes = [ordered]@{
    'OneDrive'        = 'OneDrive (synchro de fichiers)'
    'Dropbox'         = 'Dropbox (synchro de fichiers)'
    'GoogleDriveFS'   = 'Google Drive (synchro de fichiers)'
    'iCloudDrive'     = 'iCloud Drive (synchro de fichiers)'
    'MEGAsync'        = 'MEGA (synchro de fichiers)'
    'qbittorrent'     = 'qBittorrent (torrents)'
    'uTorrent'        = 'µTorrent (torrents)'
    'BitTorrent'      = 'BitTorrent (torrents)'
    'transmission-qt' = 'Transmission (torrents)'
    'steam'           = 'Steam (ses téléchargements ne s''arrêtent pas pendant Fortnite)'
    'EADesktop'       = 'EA app (téléchargements)'
    'Battle.net'      = 'Battle.net (téléchargements)'
    'upc'             = 'Ubisoft Connect (téléchargements)'
    'GalaxyClient'    = 'GOG Galaxy (téléchargements)'
}
# Celles-ci tournent normalement en permanence : on les relance à la fin de la partie.
$script:AppsARelancer = @('OneDrive', 'Dropbox', 'GoogleDriveFS', 'iCloudDrive', 'MEGAsync')

$script:Sauvegarde = New-Object System.Collections.ArrayList
$script:DejaSauve  = @{}
$script:PointRestaurationFait = $false
$script:ChoixHVCI = $null
$script:ChoixGraphismes = $null

$script:DetailsConnexion = @(
    'Carte réseau : économies d''énergie coupées (Green Ethernet, EEE, ULP...)'
    'Carte réseau : chaque paquet traité tout de suite (pas de regroupement ni de modération)'
    'Wi-Fi : moins de recherches de borne en arrière-plan + préférence pour le 5 GHz'
    'Paquets de Fortnite marqués prioritaires (QoS)'
    'Bridage réseau de Windows désactivé'
    'Windows n''utilise plus ta connexion pour envoyer des mises à jour à d''autres PC'
    'Mises à jour Windows en arrière-plan limitées à 20 % de ta connexion'
)
$script:DetailsLatence = @(
    'Accélération de la souris Windows coupée (mouvement 1:1)'
    'Raccourcis « touches rémanentes » coupés (plus de pop-up en pleine partie avec Maj)'
    'Planification GPU accélérée par le matériel activée'
    'Optimisations pour les jeux fenêtrés (Windows 11)'
    'Priorité CPU/GPU aux jeux dans le planificateur multimédia'
    'Mise en veille du PCI Express et de l''USB coupée (souris, carte graphique, réseau)'
)
$script:DetailsFps = @(
    'Plan d''alimentation hautes performances (sauf Ryzen X3D)'
    'Mode Jeu activé + enregistrement vidéo Game Bar en arrière-plan coupé'
    'Fortnite forcé sur la carte graphique dédiée'
    'OPTION (on te demande) : intégrité de la mémoire désactivée = + de FPS, - de sécurité'
)
$script:DetailsFortnite = @(
    'Plein écran, V-Sync coupée, flou de mouvement coupé, compteur de FPS'
    'NVIDIA Reflex « Activé + Boost » (cartes NVIDIA)'
    'Limite de FPS jamais en dessous de la fréquence de ton écran'
    'OPTION (on te demande) : graphismes compétitifs (ombres/effets au minimum)'
)
$script:DetailsPc = @(
    'Applications en arrière-plan coupées'
    'Transparence et animations de Windows coupées'
    'Démarrage rapide coupé (Windows repart propre à chaque démarrage)'
    'Service de télémétrie Microsoft coupé'
    'Nettoyage des fichiers temporaires (les caches de shaders sont gardés)'
    'Liste des programmes qui se lancent avec Windows'
)

# ---------------------------------------------------------------------------
# Affichage
# ---------------------------------------------------------------------------
function Write-Titre([string]$Texte)     { Write-Host ''; Write-Host "[*] $Texte" -ForegroundColor Cyan }
function Write-Ok([string]$Texte)        { Write-Host "    [OK] $Texte" -ForegroundColor Green }
function Write-Info([string]$Texte)      { Write-Host "         $Texte" -ForegroundColor Gray }
function Write-Attention([string]$Texte) { Write-Host "    [!]  $Texte" -ForegroundColor Yellow }

function Write-Section([string]$Texte) {
    Write-Host ''
    Write-Host '  --------------------------------------------------' -ForegroundColor Magenta
    Write-Host "   $Texte" -ForegroundColor Magenta
    Write-Host '  --------------------------------------------------' -ForegroundColor Magenta
}

function Write-Banniere {
    Write-Host ''
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host '     OPTIMISATION FORTNITE v3  -  ping / latence / FPS' -ForegroundColor Magenta
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host ''
}

function Read-Oui([string]$Question) {
    $reponse = "$(Read-Host "  $Question (O/N)")"
    return ($reponse -match '^\s*[oOyY]')
}

# ---------------------------------------------------------------------------
# Outils
# ---------------------------------------------------------------------------
function Test-Admin {
    $identite = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identite)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Lance un exécutable Windows (powercfg...) sans que sa sortie d'erreur
# ne soit transformée en exception par PowerShell.
function Invoke-Natif([string]$Exe, [string[]]$Arguments) {
    $ancien = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $sortie = & $Exe @Arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $ancien
    }
    return [pscustomobject]@{ Code = $code; Texte = (@($sortie) -join "`n") }
}

function Initialize-Natif {
    if (-not ('OptiFortnite.Natif' -as [type])) {
        Add-Type -Namespace 'OptiFortnite' -Name 'Natif' -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, int[] pvParam, uint fWinIni);
'@
    }
}

function Test-FortniteOuvert {
    return [bool](Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue)
}

function Test-CarteNvidia {
    try {
        return (@(Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' }).Count -gt 0)
    } catch { return $false }
}

function Get-FrequenceEcran {
    try {
        $frequences = @(Get-CimInstance -ClassName Win32_VideoController |
            Where-Object { $_.CurrentRefreshRate -gt 0 } | ForEach-Object { [int]$_.CurrentRefreshRate })
        if ($frequences.Count -eq 0) { return 0 }
        $mesure = $frequences | Measure-Object -Maximum
        return [int]$mesure.Maximum
    } catch { return 0 }
}

# Exécute une étape : si elle échoue, on prévient et on passe à la suivante.
function Invoke-Etape([string]$Titre, [scriptblock]$Bloc) {
    Write-Titre $Titre
    try {
        & $Bloc
    } catch {
        Write-Attention "Étape ignorée : $($_.Exception.Message)"
    } finally {
        try { Write-Sauvegarde } catch { Write-Attention "Impossible d'écrire la sauvegarde : $($_.Exception.Message)" }
    }
}

# ---------------------------------------------------------------------------
# Sauvegarde / restauration des réglages d'origine
# ---------------------------------------------------------------------------
function Read-Sauvegarde {
    $script:Sauvegarde = New-Object System.Collections.ArrayList
    $script:DejaSauve = @{}
    if (-not (Test-Path -LiteralPath $script:FichierSauvegarde)) { return }
    $contenu = Get-Content -LiteralPath $script:FichierSauvegarde -Raw -Encoding UTF8
    if (-not $contenu -or -not $contenu.Trim()) { return }
    $liste = ConvertFrom-Json $contenu
    foreach ($entree in $liste) {
        [void]$script:Sauvegarde.Add($entree)
        $script:DejaSauve[$entree.Id] = $true
    }
}

function Write-Sauvegarde {
    if ($script:Sauvegarde.Count -eq 0) { return }
    if (-not (Test-Path -LiteralPath $script:DossierSauvegarde)) {
        New-Item -ItemType Directory -Path $script:DossierSauvegarde -Force | Out-Null
    }
    $json = ConvertTo-Json -InputObject @($script:Sauvegarde.ToArray()) -Depth 5
    [System.IO.File]::WriteAllText($script:FichierSauvegarde, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# N'enregistre qu'une seule fois chaque réglage : si on relance le script,
# la sauvegarde garde toujours la valeur d'ORIGINE.
function Add-Entree {
    param(
        [string]$Id, [string]$Kind, [string]$Path = '', [string]$Name = '',
        [bool]$Existed = $false, [string]$ValueKind = '', $Value = $null
    )
    if ($script:DejaSauve.ContainsKey($Id)) { return }
    $entree = [pscustomobject]@{
        Id = $Id; Kind = $Kind; Path = $Path; Name = $Name
        Existed = $Existed; ValueKind = $ValueKind; Value = $Value
    }
    [void]$script:Sauvegarde.Add($entree)
    $script:DejaSauve[$Id] = $true
}

function Save-ValeurRegistre([string]$Path, [string]$Name) {
    $id = "REG|$Path|$Name"
    if ($script:DejaSauve.ContainsKey($id)) { return }
    $existait = $false; $type = ''; $valeur = $null
    if (Test-Path -LiteralPath $Path) {
        $cle = Get-Item -LiteralPath $Path
        if (@($cle.GetValueNames()) -contains $Name) {
            $existait = $true
            $type = $cle.GetValueKind($Name).ToString()
            $valeur = $cle.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        }
    }
    Add-Entree -Id $id -Kind 'Reg' -Path $Path -Name $Name -Existed $existait -ValueKind $type -Value $valeur
}

function Set-ValeurRegistre {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    Save-ValeurRegistre -Path $Path -Name $Name
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function ConvertTo-ValeurTypee($Entree) {
    switch ($Entree.ValueKind) {
        'DWord'       { return [int]$Entree.Value }
        'QWord'       { return [long]$Entree.Value }
        'Binary'      { return [byte[]]@($Entree.Value) }
        'MultiString' { return [string[]]@($Entree.Value) }
        default       { return [string]$Entree.Value }
    }
}

function New-PointRestauration {
    if ($script:PointRestaurationFait) { return }
    $script:PointRestaurationFait = $true
    Invoke-Etape 'Point de restauration Windows (filet de sécurité, ~1 min)' {
        Checkpoint-Computer -Description 'Avant optimisation Fortnite' -RestorePointType 'MODIFY_SETTINGS'
        Write-Ok 'Point de restauration prêt (Windows n''en crée qu''un par 24 h).'
    }
}

# ---------------------------------------------------------------------------
# Plan et réglages d'alimentation
# ---------------------------------------------------------------------------
function Get-PlanActif {
    $r = Invoke-Natif 'powercfg.exe' @('/getactivescheme')
    if ($r.Texte -match $script:RegexGuid) { return $Matches[0] }
    return $null
}

function Test-PlanExiste([string]$Guid) {
    $r = Invoke-Natif 'powercfg.exe' @('/list')
    return ($r.Texte -match [regex]::Escape($Guid))
}

# Valeur « sur secteur » d'un réglage d'alimentation. Dans la sortie de
# powercfg /query, les deux dernières valeurs 0x... sont : secteur, batterie.
function Get-ValeurEnergie([string]$Plan, [string]$Groupe, [string]$Reglage) {
    $r = Invoke-Natif 'powercfg.exe' @('/query', $Plan, $Groupe, $Reglage)
    if ($r.Code -ne 0) { return $null }
    $valeurs = [regex]::Matches($r.Texte, '0x([0-9a-fA-F]{8})')
    if ($valeurs.Count -lt 2) { return $null }
    return [Convert]::ToInt32($valeurs[$valeurs.Count - 2].Groups[1].Value, 16)
}

function Set-ValeurEnergie([string]$Groupe, [string]$Reglage, [int]$Valeur, [string]$Libelle) {
    $plan = Get-PlanActif
    if (-not $plan) { throw "Impossible de lire le plan d'alimentation actuel." }
    $actuel = Get-ValeurEnergie $plan $Groupe $Reglage
    if ($null -eq $actuel) { Write-Info "$Libelle : réglage absent sur ce PC."; return }
    if ($actuel -eq $Valeur) { Write-Ok "$Libelle (déjà réglé)."; return }
    Add-Entree -Id "PWRSET|$plan|$Groupe|$Reglage" -Kind 'PowerSetting' -Path $plan -Name "$Groupe|$Reglage" -Value $actuel
    $r = Invoke-Natif 'powercfg.exe' @('/setacvalueindex', $plan, $Groupe, $Reglage, [string]$Valeur)
    if ($r.Code -ne 0) { throw "powercfg : $($r.Texte)" }
    [void](Invoke-Natif 'powercfg.exe' @('/setactive', $plan))
    Write-Ok $Libelle
}

function Set-EnergieLatence {
    # PCI Express : gestion de l'alimentation de l'état de liaison -> Désactivé
    Set-ValeurEnergie '501a4d13-42af-4429-9fd1-a8218c268e20' 'ee12f906-d277-404b-b6da-e5fa1a576df5' 0 `
        'PCI Express : plus de mise en veille de la liaison (carte graphique / réseau réactives)'
    # USB : suspension sélective -> Désactivée
    Set-ValeurEnergie '2a737441-1930-4402-8d77-b2bebba308a3' '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0 `
        'USB : plus de mise en veille sélective (souris / clavier toujours réveillés)'
}

function Set-PlanAlimentation {
    $cpu = ''
    try { $cpu = [string](Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 -ExpandProperty Name) } catch { }

    # Les Ryzen X3D ont besoin du plan « Utilisation normale » + du Mode Jeu
    # pour que le pilote AMD place Fortnite sur les cœurs avec le cache 3D.
    if ($cpu -match 'X3D') {
        Write-Ok "Processeur $($cpu.Trim()) détecté : on GARDE le plan « Utilisation normale »."
        Write-Info 'C''est ce plan + le Mode Jeu qui permettent à AMD de mettre Fortnite sur les bons cœurs.'
        Set-EnergieLatence
        return
    }

    $portable = $false
    try { $portable = (@(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue).Count -gt 0) } catch { }

    $original = Get-PlanActif
    if (-not $original) { throw "Impossible de lire le plan d'alimentation actuel." }
    Add-Entree -Id 'POWER|ORIGINAL' -Kind 'PowerScheme' -Value $original

    $cible = $null; $nom = ''

    # Réutilise le plan déjà créé par une exécution précédente (pas de doublons).
    $dejaCree = @($script:Sauvegarde | Where-Object { $_.Kind -eq 'PowerCreated' }) | Select-Object -First 1
    if ($dejaCree -and (Test-PlanExiste $dejaCree.Value)) { $cible = $dejaCree.Value; $nom = 'Performances optimales' }

    if (-not $cible -and -not $portable) {
        $r = Invoke-Natif 'powercfg.exe' @('/duplicatescheme', $script:GuidUltimate)
        if ($r.Code -eq 0 -and $r.Texte -match $script:RegexGuid) {
            $cible = $Matches[0]; $nom = 'Performances optimales'
            Add-Entree -Id "POWER|CREATED|$cible" -Kind 'PowerCreated' -Value $cible
        }
    }
    if (-not $cible -and (Test-PlanExiste $script:GuidHautesPerf)) {
        $cible = $script:GuidHautesPerf; $nom = 'Performances élevées'
    }
    if (-not $cible) {
        Write-Attention 'Ce PC n''expose que le plan « Utilisation normale » (fréquent sur les portables récents).'
        Write-Info 'Règle-le à la main : Paramètres > Système > Alimentation > Mode d''alimentation > « Performances optimales ».'
        Set-EnergieLatence
        return
    }

    $r = Invoke-Natif 'powercfg.exe' @('/setactive', $cible)
    if ($r.Code -ne 0) { throw "powercfg n'a pas pu activer le plan : $($r.Texte)" }
    Write-Ok "Plan « $nom » activé (le processeur ne se met plus en économie pendant les combats)."
    if ($portable) {
        Write-Attention 'PC portable : joue BRANCHÉ sur secteur, sinon la carte graphique est bridée.'
    }
    Set-EnergieLatence
}

# ---------------------------------------------------------------------------
# CONNEXION
# ---------------------------------------------------------------------------
function Set-CarteReseau {
    $cartes = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
    if ($cartes.Count -eq 0) { Write-Info 'Aucune carte réseau active trouvée.'; return }

    # Mots-clés standard des pilotes (indépendants de la langue de Windows).
    $reglages = [ordered]@{
        '*EEE'                 = '0'  # Energy Efficient Ethernet
        'EEELinkAdvertisement' = '0'  # EEE (Intel)
        'AdvancedEEE'          = '0'  # EEE avancé (Realtek)
        'EnableGreenEthernet'  = '0'  # Green Ethernet (Realtek)
        'GreenEthernet'        = '0'
        'PowerSavingMode'      = '0'  # Économie d'énergie (Realtek)
        'ULPMode'              = '0'  # Ultra Low Power (Intel)
        '*PacketCoalescing'    = '0'  # regroupe les paquets pour économiser -> délai
        '*InterruptModeration' = '0'  # traite chaque paquet tout de suite
        'RoamAggressiveness'   = '0'  # Wi-Fi Intel : moins de scans de bornes -> moins de pics
        'RoamingPreferredBandType' = '2'  # Wi-Fi Intel : préférer le 5 GHz (moins encombré)
    }

    foreach ($carte in $cartes) {
        $modifiee = $false
        $proprietes = @(Get-NetAdapterAdvancedProperty -Name $carte.Name -ErrorAction SilentlyContinue)
        foreach ($motCle in $reglages.Keys) {
            $voulu = $reglages[$motCle]
            $p = $proprietes | Where-Object { $_.RegistryKeyword -eq $motCle } | Select-Object -First 1
            if (-not $p) { continue }
            $valeurActuelle = [string](@($p.RegistryValue)[0])
            if ($valeurActuelle -eq $voulu) { continue }
            if ($p.ValidRegistryValues -and (@($p.ValidRegistryValues) -notcontains $voulu)) { continue }
            # Ne remplace pas une préférence déjà réglée sur le 6 GHz (Wi-Fi 6E/7).
            if ($motCle -eq 'RoamingPreferredBandType' -and @('0', '1') -notcontains $valeurActuelle) { continue }
            try {
                Add-Entree -Id "NIC|$($carte.Name)|$motCle" -Kind 'Nic' -Path $carte.Name -Name $motCle -Value $valeurActuelle
                Set-NetAdapterAdvancedProperty -Name $carte.Name -RegistryKeyword $motCle -RegistryValue $voulu -NoRestart -Confirm:$false
                $modifiee = $true
                Write-Ok "$($carte.Name) : « $($p.DisplayName) » réglé pour la latence."
            } catch {
                Write-Attention "$($carte.Name) : « $($p.DisplayName) » non modifiable ($($_.Exception.Message))."
            }
        }
        if ($modifiee) {
            Write-Info "Redémarrage de « $($carte.Name) » (coupure de quelques secondes)..."
            Restart-NetAdapter -Name $carte.Name -Confirm:$false
        } else {
            Write-Ok "$($carte.Name) : déjà optimale."
        }
    }
}

function Set-QosFortnite {
    # Nécessaire pour que Windows applique la priorité hors réseau d'entreprise.
    Set-ValeurRegistre -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS' -Name 'Do not use NLA' -Value '1' -Type 'String'
    $existe = $null
    try { $existe = Get-NetQosPolicy -Name $script:NomQos -ErrorAction Stop } catch { }
    if (-not $existe) {
        New-NetQosPolicy -Name $script:NomQos -AppPathNameMatchCondition $script:ExeFortnite -DSCPAction 46 -NetworkProfile All | Out-Null
        Add-Entree -Id "QOS|$($script:NomQos)" -Kind 'Qos' -Name $script:NomQos
    }
    Write-Ok 'Paquets de Fortnite marqués « priorité temps réel » (DSCP 46).'
    Write-Info 'Utile surtout en Wi-Fi et avec les box qui gèrent la priorité (QoS).'
}

function Set-BridageReseau {
    $profil = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-ValeurRegistre -Path $profil -Name 'NetworkThrottlingIndex' -Value -1   # 0xFFFFFFFF = aucun bridage
    Write-Ok 'Bridage réseau de Windows désactivé (quand de la musique ou une vidéo tourne en fond).'
}

function Set-PartageMisesAJour {
    $cle = 'Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings'
    Set-ValeurRegistre -Path $cle -Name 'DownloadMode' -Value 0
    Write-Ok 'Windows n''envoie plus de morceaux de mises à jour à d''autres PC par ta connexion.'
    Write-Info '(Ça saturait ton envoi = pics de ping. Les mises à jour, elles, continuent normalement.)'

    $politique = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
    Set-ValeurRegistre -Path $politique -Name 'DOPercentageMaxBackgroundBandwidth' -Value 20
    Write-Ok 'Mises à jour Windows en arrière-plan limitées à 20 % de ta connexion.'
    Write-Info '(Windows Update peut afficher « certains paramètres sont gérés par votre organisation » : c''est ce réglage.)'
}

# ---------------------------------------------------------------------------
# MODE PARTIE (le temps d'une session, puis tout revient à la normale)
# ---------------------------------------------------------------------------
function Test-EstWifi($Carte) {
    return (([string]$Carte.PhysicalMediaType -match '802\.11') -or
            ([string]$Carte.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN|802\.11'))
}

# Cartes Wi-Fi actives, seulement si aucun câble Ethernet n'est branché.
function Get-WifiSeul {
    $actives = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
    if (@($actives | Where-Object { -not (Test-EstWifi $_) }).Count -gt 0) { return }
    foreach ($c in $actives) { if (Test-EstWifi $c) { $c.Name } }
}

function Test-PartieActive {
    if (-not (Test-Path -LiteralPath $script:FichierPartie)) { return $false }
    try {
        $etat = Get-Content -LiteralPath $script:FichierPartie -Raw -Encoding UTF8 | ConvertFrom-Json
        $p = Get-Process -Id ([int]$etat.Pid) -ErrorAction SilentlyContinue
        return [bool]($p -and $p.ProcessName -match 'powershell|pwsh')
    } catch { return $false }
}

function Close-Appli([string]$NomProcessus) {
    if ($NomProcessus -eq 'steam') {
        $p = Get-Process -Name 'steam' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($p -and $p.Path) { try { Start-Process -FilePath $p.Path -ArgumentList '-shutdown' } catch { } }
    } else {
        [void](Invoke-Natif 'taskkill.exe' @('/IM', "$NomProcessus.exe"))
    }
    for ($i = 0; $i -lt 20; $i++) {
        if (-not (Get-Process -Name $NomProcessus -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Milliseconds 500
    }
    Get-Process -Name $NomProcessus -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Register-SecoursWifi([string[]]$Interfaces) {
    $commandes = ($Interfaces | ForEach-Object { "netsh wlan set autoconfig enabled=yes interface=`"$_`"" }) -join ' & '
    $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c $commandes"
    $declencheurs = @((New-ScheduledTaskTrigger -AtStartup), (New-ScheduledTaskTrigger -AtLogOn))
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $script:TachePartie -Action $action -Trigger $declencheurs -Principal $principal -Force | Out-Null
}

function Stop-ModePartie([switch]$Silencieux) {
    if (-not (Test-Path -LiteralPath $script:FichierPartie)) { return }
    $etat = Get-Content -LiteralPath $script:FichierPartie -Raw -Encoding UTF8 | ConvertFrom-Json

    foreach ($nom in @($etat.Wifi)) {
        if (-not $nom) { continue }
        $r = Invoke-Natif 'netsh.exe' @('wlan', 'set', 'autoconfig', 'enabled=yes', "interface=$nom")
        if ($r.Code -eq 0) { Write-Ok "Wi-Fi « $nom » : recherche de réseaux réactivée." }
        else { Write-Attention "Wi-Fi « $nom » : $($r.Texte)" }
    }
    try { Unregister-ScheduledTask -TaskName $script:TachePartie -Confirm:$false -ErrorAction Stop } catch { }

    if (-not $Silencieux) {
        foreach ($app in @($etat.Apps)) {
            if (-not $app -or -not $app.Chemin -or -not $app.Relancer) { continue }
            if (-not (Test-Path -LiteralPath $app.Chemin)) { continue }
            # Via l'explorateur : l'appli repart SANS droits administrateur, comme d'habitude.
            try { Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$($app.Chemin)`""; Write-Ok "$($app.Nom) relancé." } catch { }
        }
    }
    Remove-Item -LiteralPath $script:FichierPartie -Force -ErrorAction SilentlyContinue
}

function Start-ModePartie {
    Write-Section 'MODE PARTIE : ping au minimum pendant que tu joues'
    if (Test-PartieActive) { Write-Attention 'Le mode partie est déjà actif dans une autre fenêtre.'; return }
    Stop-ModePartie -Silencieux   # restes d'une session mal fermée

    if (-not (Test-Path -LiteralPath $script:DossierSauvegarde)) {
        New-Item -ItemType Directory -Path $script:DossierSauvegarde -Force | Out-Null
    }
    $etat = [ordered]@{ Pid = $PID; Wifi = @(); Apps = @() }

    # 1. Applis qui utilisent la connexion en fond
    Write-Titre 'Applis qui utilisent ta connexion en fond'
    $trouvees = @()
    foreach ($nom in $script:AppsGourmandes.Keys) {
        $p = Get-Process -Name $nom -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($p) { $trouvees += [pscustomobject]@{ Processus = $nom; Nom = $script:AppsGourmandes[$nom]; Chemin = [string]$p.Path } }
    }
    if ($trouvees.Count -eq 0) {
        Write-Ok 'Aucune appli gourmande ouverte.'
    } else {
        foreach ($a in $trouvees) { Write-Info "- $($a.Nom)" }
        if (Read-Oui 'Les fermer pendant la partie (la synchro de fichiers sera relancée à la fin) ?') {
            foreach ($a in $trouvees) {
                Close-Appli $a.Processus
                Write-Ok "$($a.Nom) fermé."
                $etat['Apps'] += [pscustomobject]@{
                    Nom = $a.Nom; Chemin = $a.Chemin; Relancer = ($script:AppsARelancer -contains $a.Processus)
                }
            }
        }
    }

    # 2. Windows Update : téléchargements arrêtés pour la session
    Write-Titre 'Windows Update'
    foreach ($service in @('wuauserv', 'DoSvc', 'BITS')) {
        try { Stop-Service -Name $service -Force -ErrorAction Stop } catch { }
    }
    Write-Ok 'Téléchargements de mises à jour arrêtés pour la session (Windows les reprendra plus tard).'

    # 3. Wi-Fi : plus de recherche de réseaux en arrière-plan
    $wifi = @(Get-WifiSeul)
    if ($wifi.Count -gt 0) {
        Write-Titre 'Wi-Fi'
        Write-Info 'Toutes les ~60 s, Windows cherche d''autres réseaux Wi-Fi : ça crée un pic de ping régulier.'
        try { Register-SecoursWifi $wifi } catch { Write-Attention "Sécurité de réactivation non créée : $($_.Exception.Message)" }
        foreach ($nom in $wifi) {
            $r = Invoke-Natif 'netsh.exe' @('wlan', 'set', 'autoconfig', 'enabled=no', "interface=$nom")
            if ($r.Code -eq 0) { $etat['Wifi'] += $nom; Write-Ok "Wi-Fi « $nom » : recherche en arrière-plan coupée (tu restes connecté)." }
            else { Write-Attention "Wi-Fi « $nom » : $($r.Texte)" }
        }
        Write-Attention 'Le vrai remède reste un câble Ethernet : le Wi-Fi aura toujours plus de pics.'
    }

    $json = ConvertTo-Json -InputObject $etat -Depth 4
    [System.IO.File]::WriteAllText($script:FichierPartie, $json, (New-Object System.Text.UTF8Encoding($false)))

    Write-Host ''
    Write-Host '  ================ MODE PARTIE ACTIF ================' -ForegroundColor Green
    Write-Info 'Lance Fortnite et joue. Laisse cette fenêtre ouverte (tu peux la réduire).'
    Write-Info 'Pour la meilleure connexion : personne ne télécharge / ne regarde de vidéo 4K'
    Write-Info 'pendant ta partie, et la TV Freebox éteinte si tu sens plus de lag quand elle tourne.'
    Write-Host ''
    Read-Host '  Quand tu as FINI de jouer, appuie sur Entrée ici pour tout remettre' | Out-Null

    Write-Titre 'Fin de partie'
    Stop-ModePartie
    Write-Ok 'Tout est revenu à la normale.'
}

# ---------------------------------------------------------------------------
# LATENCE
# ---------------------------------------------------------------------------
function Update-Souris {
    Initialize-Natif
    $p = Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Mouse'
    $valeurs = [int[]]@([int]$p.MouseThreshold1, [int]$p.MouseThreshold2, [int]$p.MouseSpeed)
    # SPI_SETMOUSE (4), SPIF_UPDATEINIFILE | SPIF_SENDCHANGE (3) : appliqué tout de suite
    [void][OptiFortnite.Natif]::SystemParametersInfo(4, 0, $valeurs, 3)
}

function Set-Souris {
    $cle = 'HKCU:\Control Panel\Mouse'
    Set-ValeurRegistre -Path $cle -Name 'MouseSpeed' -Value '0' -Type 'String'
    Set-ValeurRegistre -Path $cle -Name 'MouseThreshold1' -Value '0' -Type 'String'
    Set-ValeurRegistre -Path $cle -Name 'MouseThreshold2' -Value '0' -Type 'String'
    Update-Souris
    Write-Ok '« Améliorer la précision du pointeur » désactivé : la souris bouge en 1:1 partout.'
}

function Set-TouchesRemanentes {
    $base = 'HKCU:\Control Panel\Accessibility'
    Set-ValeurRegistre -Path "$base\StickyKeys" -Name 'Flags' -Value '506' -Type 'String'
    Set-ValeurRegistre -Path "$base\ToggleKeys" -Name 'Flags' -Value '58' -Type 'String'
    Set-ValeurRegistre -Path "$base\Keyboard Response" -Name 'Flags' -Value '122' -Type 'String'
    Write-Ok 'Plus de fenêtre « touches rémanentes » quand tu spammes Maj (effet au redémarrage).'
}

function Set-Hags {
    Set-ValeurRegistre -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value 2
    Write-Ok 'Planification GPU accélérée par le matériel activée (si ta carte la gère, effet au redémarrage).'
}

function Set-JeuxFenetres {
    $cle = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    $actuel = ''
    if (Test-Path -LiteralPath $cle) {
        $actuel = [string](Get-ItemProperty -LiteralPath $cle -Name 'DirectXUserGlobalSettings' -ErrorAction SilentlyContinue).DirectXUserGlobalSettings
    }
    if ($actuel -notmatch 'SwapEffectUpgradeEnable=1') {
        $nouveau = $actuel -replace 'SwapEffectUpgradeEnable=\d;?', ''
        if ($nouveau -and -not $nouveau.EndsWith(';')) { $nouveau += ';' }
        $nouveau += 'SwapEffectUpgradeEnable=1;'
        Set-ValeurRegistre -Path $cle -Name 'DirectXUserGlobalSettings' -Value $nouveau -Type 'String'
    }
    Write-Ok 'Optimisations pour les jeux fenêtrés activées (Windows 11).'
}

function Set-PrioriteJeux {
    $profil = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-ValeurRegistre -Path $profil -Name 'SystemResponsiveness' -Value 10   # minimum réservé aux tâches de fond
    $jeux = "$profil\Tasks\Games"
    Set-ValeurRegistre -Path $jeux -Name 'GPU Priority' -Value 8
    Set-ValeurRegistre -Path $jeux -Name 'Priority' -Value 6
    Set-ValeurRegistre -Path $jeux -Name 'Scheduling Category' -Value 'High' -Type 'String'
    Set-ValeurRegistre -Path $jeux -Name 'SFIO Priority' -Value 'High' -Type 'String'
    Write-Ok 'Planificateur multimédia : priorité maximale aux jeux.'
}

# ---------------------------------------------------------------------------
# FPS
# ---------------------------------------------------------------------------
function Set-ModeJeu {
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1
    Write-Ok 'Mode Jeu activé (Windows Update ne s''installe pas en pleine partie, priorité au jeu).'
    Set-ValeurRegistre -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0
    Write-Ok 'Enregistrement vidéo en arrière-plan de la Game Bar coupé (il mange des FPS).'
    Write-Info '(ShadowPlay / NVIDIA App et Medal ne sont pas concernés.)'
}

function Get-FortniteExe {
    $dossiers = New-Object System.Collections.Generic.List[string]
    $manifestes = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
    if (Test-Path -LiteralPath $manifestes) {
        foreach ($fichier in @(Get-ChildItem -LiteralPath $manifestes -Filter '*.item' -ErrorAction SilentlyContinue)) {
            try {
                $j = Get-Content -LiteralPath $fichier.FullName -Raw | ConvertFrom-Json
                if (($j.AppName -eq 'Fortnite' -or $j.DisplayName -eq 'Fortnite') -and $j.InstallLocation) {
                    $dossiers.Add([string]$j.InstallLocation)
                }
            } catch { }
        }
    }
    $dossiers.Add((Join-Path $env:ProgramFiles 'Epic Games\Fortnite'))
    foreach ($dossier in $dossiers) {
        $exe = Join-Path $dossier "FortniteGame\Binaries\Win64\$($script:ExeFortnite)"
        if (Test-Path -LiteralPath $exe) { return [System.IO.Path]::GetFullPath($exe) }
    }
    return $null
}

function Set-GpuFortnite {
    $exe = Get-FortniteExe
    if (-not $exe) { Write-Attention 'Fortnite introuvable (installé ailleurs ?) : réglage ignoré.'; return }
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $exe -Value 'GpuPreference=2;' -Type 'String'
    Write-Ok 'Fortnite forcé sur la carte graphique la plus puissante.'
    Write-Info $exe
}

function Get-HvciActive {
    if (-not (Test-Path -LiteralPath $script:CleHvci)) { return $false }
    $valeur = (Get-ItemProperty -LiteralPath $script:CleHvci -Name 'Enabled' -ErrorAction SilentlyContinue).Enabled
    return ($valeur -eq 1)
}

function Request-ChoixHvci {
    if ($null -ne $script:ChoixHVCI) { return }
    if (-not (Get-HvciActive)) { $script:ChoixHVCI = $false; return }
    Write-Host ''
    Write-Attention 'OPTION : l''« intégrité de la mémoire » (Sécurité Windows) est activée sur ce PC.'
    Write-Info 'La couper donne souvent +5 à 10 % de FPS, MAIS Windows est moins protégé contre'
    Write-Info 'les virus qui s''attaquent au cœur du système. Tu peux la réactiver quand tu veux.'
    $script:ChoixHVCI = Read-Oui 'Désactiver l''intégrité de la mémoire ?'
}

function Set-IntegriteMemoire {
    if (-not (Get-HvciActive)) { Write-Ok 'Intégrité de la mémoire déjà désactivée : rien à faire.'; return }
    Request-ChoixHvci
    if (-not $script:ChoixHVCI) { Write-Info 'Conservée (tu as choisi la sécurité maximale).'; return }
    Set-ValeurRegistre -Path $script:CleHvci -Name 'Enabled' -Value 0
    Write-Ok 'Intégrité de la mémoire désactivée (effet au redémarrage).'
    Write-Info 'Pour la remettre : Sécurité Windows > Sécurité de l''appareil > Isolation du noyau, ou option « Restaurer ».'
}

# ---------------------------------------------------------------------------
# FORTNITE (fichier de réglages du jeu, comme le menu Paramètres)
# ---------------------------------------------------------------------------
function Request-ChoixGraphismes {
    if ($null -ne $script:ChoixGraphismes) { return }
    Write-Host ''
    Write-Attention 'OPTION : graphismes « compétitifs » dans Fortnite.'
    Write-Info 'Ombres, effets, reflets, post-traitement, illumination et herbe au minimum :'
    Write-Info 'beaucoup plus de FPS et une meilleure visibilité, mais une image moins jolie.'
    Write-Info '(Textures et distance d''affichage ne sont pas touchées.)'
    $script:ChoixGraphismes = Read-Oui 'Passer les graphismes en mode compétitif ?'
}

# Remplace la valeur d'une clé déjà présente dans le fichier (n'ajoute rien).
function Set-CleIni([string]$Texte, [string]$Cle, [string]$Valeur) {
    $motif = '(?m)^([ \t]*' + [regex]::Escape($Cle) + '[ \t]*=)[^\r\n]*'
    if ($Texte -notmatch $motif) { return $Texte }
    return [regex]::Replace($Texte, $motif, ('${1}' + $Valeur))
}

function Get-FichierReglagesFortnite {
    return (Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini')
}

function Set-ConfigFortnite {
    if (Test-FortniteOuvert) { throw 'Fortnite est ouvert : ferme-le puis relance cette option.' }
    $ini = Get-FichierReglagesFortnite
    if (-not (Test-Path -LiteralPath $ini)) {
        Write-Attention 'Fichier de réglages de Fortnite introuvable : lance le jeu une fois, ferme-le, puis relance cette option.'
        return
    }
    Request-ChoixGraphismes

    # Copie du fichier d'origine (une seule fois).
    $id = "FILE|$ini"
    if (-not $script:DejaSauve.ContainsKey($id)) {
        if (-not (Test-Path -LiteralPath $script:DossierSauvegarde)) {
            New-Item -ItemType Directory -Path $script:DossierSauvegarde -Force | Out-Null
        }
        $copie = Join-Path $script:DossierSauvegarde 'GameUserSettings.ini.original'
        Copy-Item -LiteralPath $ini -Destination $copie -Force
        Add-Entree -Id $id -Kind 'File' -Path $ini -Value $copie
    }

    # On réécrit le fichier dans son encodage d'origine.
    $octets = [System.IO.File]::ReadAllBytes($ini)
    $encodage = New-Object System.Text.UTF8Encoding($false)
    if ($octets.Length -ge 2 -and $octets[0] -eq 0xFF -and $octets[1] -eq 0xFE) {
        $encodage = New-Object System.Text.UnicodeEncoding($false, $true)
    } elseif ($octets.Length -ge 3 -and $octets[0] -eq 0xEF -and $octets[1] -eq 0xBB -and $octets[2] -eq 0xBF) {
        $encodage = New-Object System.Text.UTF8Encoding($true)
    }
    $texte = [System.IO.File]::ReadAllText($ini)
    $original = $texte

    $reglages = [ordered]@{
        'FullscreenMode'              = '0'
        'LastConfirmedFullscreenMode' = '0'
        'PreferredFullscreenMode'     = '0'
        'bUseVSync'                   = 'False'
        'bMotionBlur'                 = 'False'
        'bShowFPS'                    = 'True'
        'bDisableMouseAcceleration'   = 'True'
    }
    if (Test-CarteNvidia) { $reglages['LatencyTweak2'] = '2' }
    if ($script:ChoixGraphismes) {
        foreach ($cle in @('sg.ShadowQuality', 'sg.GlobalIlluminationQuality', 'sg.ReflectionQuality',
                           'sg.PostProcessQuality', 'sg.EffectsQuality', 'sg.FoliageQuality')) {
            $reglages[$cle] = '0'
        }
    }

    $libelles = @{
        'FullscreenMode'               = 'Mode plein écran'
        'bUseVSync'                    = 'V-Sync désactivée'
        'bMotionBlur'                  = 'Flou de mouvement désactivé'
        'bShowFPS'                     = 'Compteur de FPS affiché'
        'bDisableMouseAcceleration'    = 'Accélération souris du jeu désactivée'
        'LatencyTweak2'                = 'NVIDIA Reflex : Activé + Boost'
        'sg.ShadowQuality'             = 'Ombres désactivées'
        'sg.GlobalIlluminationQuality' = 'Illumination globale au minimum'
        'sg.ReflectionQuality'         = 'Reflets au minimum'
        'sg.PostProcessQuality'        = 'Post-traitement au minimum'
        'sg.EffectsQuality'            = 'Effets au minimum'
        'sg.FoliageQuality'            = 'Herbe / végétation au minimum'
    }

    $modifs = New-Object System.Collections.Generic.List[string]
    foreach ($cle in $reglages.Keys) {
        $avant = $texte
        $texte = Set-CleIni -Texte $texte -Cle $cle -Valeur $reglages[$cle]
        if ($texte -cne $avant -and $libelles.ContainsKey($cle)) { $modifs.Add($libelles[$cle]) }
    }

    # Limite de FPS : jamais en dessous de la fréquence de l'écran.
    $hz = Get-FrequenceEcran
    if ($hz -gt 60 -and $texte -match '(?m)^[ \t]*FrameRateLimit[ \t]*=[ \t]*([0-9.]+)') {
        $limite = [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
        if ($limite -gt 0 -and $limite -lt $hz) {
            $texte = Set-CleIni -Texte $texte -Cle 'FrameRateLimit' -Valeur ('{0}.000000' -f $hz)
            $modifs.Add("Limite de FPS remontée de $([int]$limite) à $hz (fréquence de ton écran)")
        }
    }

    if ($texte -cne $original) {
        [System.IO.File]::WriteAllText($ini, $texte, $encodage)
        foreach ($m in $modifs) { Write-Ok $m }
    } else {
        Write-Ok 'Les réglages de Fortnite étaient déjà optimisés.'
    }
}

function Show-ReglagesManuelsFortnite {
    Write-Info 'À vérifier une fois dans le jeu (Paramètres > Vidéo) :'
    Write-Info ' - Mode de rendu : « Performance » (le plus réactif)'
    Write-Info ' - NVIDIA Reflex : « Activé + Boost »  |  carte AMD : « Anti-Lag 2 » activé'
    Write-Info ' - Paramètres > Jeu : région de matchmaking avec le ping le plus bas'
    Write-Info ' - Active les « statistiques réseau » (Net Debug Stats) pour voir ton vrai ping'
}

# ---------------------------------------------------------------------------
# PC COMPLET
# ---------------------------------------------------------------------------
function Set-AppsArrierePlan {
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name 'GlobalUserDisabled' -Value 1
    Write-Ok 'Applications du Microsoft Store bloquées en arrière-plan.'
    Write-Info '(Les logiciels classiques comme Discord ou Steam ne sont pas concernés.)'
}

function Set-EffetsVisuels {
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0
    Set-ValeurRegistre -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value '0' -Type 'String'
    Write-Ok 'Transparence et animations des fenêtres coupées (Windows plus vif).'
}

function Set-DemarrageRapide {
    Set-ValeurRegistre -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
    Write-Ok 'Démarrage rapide coupé : pilotes et mémoire repartent propres à chaque allumage.'
}

function Set-Telemetrie {
    $cle = 'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack'
    if (-not (Test-Path -LiteralPath $cle)) { Write-Info 'Service de télémétrie absent.'; return }
    Set-ValeurRegistre -Path $cle -Name 'Start' -Value 4
    Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue
    Write-Ok 'Télémétrie Microsoft (DiagTrack) arrêtée : une tâche de fond en moins.'
}

function Clear-FichiersTemp {
    $limite = (Get-Date).AddDays(-1)
    $total = [long]0; $nombre = 0
    foreach ($dossier in @($env:TEMP, (Join-Path $env:SystemRoot 'Temp'))) {
        if (-not $dossier -or -not (Test-Path -LiteralPath $dossier)) { continue }
        $fichiers = @(Get-ChildItem -LiteralPath $dossier -Recurse -Force -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $limite })
        foreach ($f in $fichiers) {
            try {
                $taille = $f.Length
                Remove-Item -LiteralPath $f.FullName -Force
                $total += $taille; $nombre++
            } catch { }
        }
    }
    Write-Ok ('{0} fichiers temporaires supprimés ({1:N0} Mo libérés).' -f $nombre, ($total / 1MB))
    Write-Info 'Les caches de shaders sont gardés exprès : les vider provoquerait des saccades.'
}

function Show-ProgrammesDemarrage {
    $liste = @(Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name -Unique)
    if ($liste.Count -eq 0) { Write-Ok 'Aucun programme au démarrage détecté.'; return }
    Write-Info "$($liste.Count) programme(s) se lancent avec Windows :"
    foreach ($nom in $liste) { Write-Info " - $nom" }
    Write-Attention 'Désactive ceux qui ne servent pas : Ctrl+Maj+Échap > Applications de démarrage.'
    Write-Info '(Garde l''antivirus, les pilotes audio/graphiques et le logiciel de ta souris.)'
}

# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------
function Invoke-SectionConnexion {
    Write-Section 'CONNEXION : réduire le ping et les pics de lag'
    Invoke-Etape 'Carte réseau' { Set-CarteReseau }
    Invoke-Etape 'Priorité réseau pour Fortnite (QoS)' { Set-QosFortnite }
    Invoke-Etape 'Bridage réseau de Windows' { Set-BridageReseau }
    Invoke-Etape 'Partage des mises à jour Windows' { Set-PartageMisesAJour }
}

function Invoke-SectionLatence {
    Write-Section 'LATENCE : supprimer le délai (input lag)'
    Invoke-Etape 'Souris' { Set-Souris }
    Invoke-Etape 'Touches rémanentes' { Set-TouchesRemanentes }
    Invoke-Etape 'Planification GPU' { Set-Hags }
    Invoke-Etape 'Jeux fenêtrés' { Set-JeuxFenetres }
    Invoke-Etape 'Priorité aux jeux' { Set-PrioriteJeux }
    Invoke-Etape 'Mise en veille PCI Express / USB' { Set-EnergieLatence }
}

function Invoke-SectionFps {
    Write-Section 'FPS : plus d''images par seconde, plus stables'
    Invoke-Etape 'Plan d''alimentation' { Set-PlanAlimentation }
    Invoke-Etape 'Mode Jeu + Game Bar' { Set-ModeJeu }
    Invoke-Etape 'Carte graphique dédiée pour Fortnite' { Set-GpuFortnite }
    Invoke-Etape 'Intégrité de la mémoire' { Set-IntegriteMemoire }
}

function Invoke-SectionFortnite {
    Write-Section 'FORTNITE : réglages du jeu'
    Invoke-Etape 'Fichier de réglages de Fortnite' { Set-ConfigFortnite }
    Show-ReglagesManuelsFortnite
}

function Invoke-SectionPc {
    Write-Section 'PC COMPLET : Windows plus léger'
    Invoke-Etape 'Applications en arrière-plan' { Set-AppsArrierePlan }
    Invoke-Etape 'Effets visuels' { Set-EffetsVisuels }
    Invoke-Etape 'Démarrage rapide' { Set-DemarrageRapide }
    Invoke-Etape 'Télémétrie' { Set-Telemetrie }
    Invoke-Etape 'Nettoyage des fichiers temporaires' { Clear-FichiersTemp }
    Invoke-Etape 'Programmes au démarrage' { Show-ProgrammesDemarrage }
}

function Show-Fin {
    Write-Host ''
    Write-Host '  ==================== TERMINÉ ====================' -ForegroundColor Green
    Write-Info "Réglages d'origine sauvegardés dans : $script:DossierSauvegarde"
    Write-Info 'Pour tout annuler : relance LANCER.bat et choisis « 9. Restaurer ».'
    Write-Host ''
    Write-Attention 'AVANT CHAQUE SESSION : double-clic sur MODE-PARTIE.bat (ping au minimum pendant la partie).'
    Write-Host ''
    Write-Attention 'Ce qu''AUCUN logiciel ne peut faire à ta place (et c''est là que se joue le ping) :'
    Write-Info ' - un câble Ethernet entre le PC et la box (le Wi-Fi = pics de ping)'
    Write-Info ' - personne qui télécharge ou regarde un stream pendant tes parties'
    Write-Info ' - la bonne région de matchmaking dans Fortnite'
    Write-Info 'Détails dans le guide README.md.'
    Write-Host ''
    if (Read-Oui 'Redémarrer le PC maintenant (nécessaire pour tout activer) ?') { Restart-Computer -Force }
}

function Invoke-Application([string]$Titre, [string[]]$Details, [scriptblock]$Sections, [bool]$CoupeReseau) {
    Write-Titre $Titre
    foreach ($ligne in $Details) { Write-Info "- $ligne" }
    Write-Host ''
    if (Test-FortniteOuvert) { Write-Attention 'Fortnite est ouvert : ferme-le avant de continuer.' }
    if ($CoupeReseau) { Write-Attention 'Internet va couper quelques secondes (redémarrage de la carte réseau).' }
    if (-not (Read-Oui 'Continuer ?')) { Write-Info 'Annulé, rien n''a été modifié.'; return }
    Read-Sauvegarde
    New-PointRestauration
    & $Sections
    Show-Fin
}

function Invoke-Tout {
    Write-Titre 'TOUT OPTIMISER : voici tout ce qui va être fait'
    Write-Host '   Connexion' -ForegroundColor White;  foreach ($l in $script:DetailsConnexion) { Write-Info "- $l" }
    Write-Host '   Latence' -ForegroundColor White;    foreach ($l in $script:DetailsLatence)   { Write-Info "- $l" }
    Write-Host '   FPS' -ForegroundColor White;        foreach ($l in $script:DetailsFps)       { Write-Info "- $l" }
    Write-Host '   Fortnite' -ForegroundColor White;   foreach ($l in $script:DetailsFortnite)  { Write-Info "- $l" }
    Write-Host '   PC complet' -ForegroundColor White; foreach ($l in $script:DetailsPc)        { Write-Info "- $l" }
    Write-Host ''
    if (Test-FortniteOuvert) { Write-Attention 'Fortnite est ouvert : ferme-le avant de continuer.' }
    Write-Attention 'Internet va couper quelques secondes (redémarrage de la carte réseau).'
    if (-not (Read-Oui 'Lancer l''optimisation complète ?')) { Write-Info 'Annulé, rien n''a été modifié.'; return }

    # Les 2 seules questions, posées avant de commencer.
    Request-ChoixHvci
    if (Test-Path -LiteralPath (Get-FichierReglagesFortnite)) { Request-ChoixGraphismes }

    Read-Sauvegarde
    New-PointRestauration
    Invoke-SectionFps        # en premier : le plan d'alimentation
    Invoke-SectionLatence
    Invoke-SectionConnexion
    Invoke-SectionFortnite
    Invoke-SectionPc
    Show-Fin
}

# ---------------------------------------------------------------------------
# Restauration
# ---------------------------------------------------------------------------
function Invoke-Restauration {
    if ((Test-Path -LiteralPath $script:FichierPartie) -and -not (Test-PartieActive)) {
        Write-Titre 'Mode partie'
        Stop-ModePartie -Silencieux
    }
    Read-Sauvegarde
    if ($script:Sauvegarde.Count -eq 0) { Write-Attention 'Aucune sauvegarde trouvée : rien à restaurer.'; return }
    if (-not (Read-Oui 'Remettre TOUS les réglages comme avant ?')) { return }

    $entrees = @($script:Sauvegarde.ToArray())
    [array]::Reverse($entrees)
    $erreurs = 0

    Write-Titre 'Alimentation'
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'PowerSetting' })) {
        if (-not (Test-PlanExiste $e.Path)) { continue }
        $parties = ([string]$e.Name).Split('|')
        $r = Invoke-Natif 'powercfg.exe' @('/setacvalueindex', [string]$e.Path, $parties[0], $parties[1], [string]$e.Value)
        if ($r.Code -ne 0) { $erreurs++; Write-Attention $r.Texte }
    }
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'PowerScheme' })) {
        $r = Invoke-Natif 'powercfg.exe' @('/setactive', [string]$e.Value)
        if ($r.Code -eq 0) { Write-Ok 'Plan d''origine réactivé.' } else { $erreurs++; Write-Attention $r.Texte }
    }
    $actif = Get-PlanActif
    if ($actif) { [void](Invoke-Natif 'powercfg.exe' @('/setactive', $actif)) }
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'PowerCreated' })) {
        $r = Invoke-Natif 'powercfg.exe' @('/delete', [string]$e.Value)
        if ($r.Code -eq 0) { Write-Ok 'Plan « Performances optimales » supprimé.' }
    }
    Write-Ok 'Réglages d''alimentation remis.'

    Write-Titre 'Registre'
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'Reg' })) {
        try {
            if ($e.Existed) {
                if (-not (Test-Path -LiteralPath $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
                New-ItemProperty -LiteralPath $e.Path -Name $e.Name -Value (ConvertTo-ValeurTypee $e) -PropertyType $e.ValueKind -Force | Out-Null
            } elseif (Test-Path -LiteralPath $e.Path) {
                Remove-ItemProperty -LiteralPath $e.Path -Name $e.Name -ErrorAction SilentlyContinue
            }
        } catch {
            $erreurs++
            Write-Attention "$($e.Path)\$($e.Name) : $($_.Exception.Message)"
        }
    }
    try { Update-Souris } catch { }
    Write-Ok 'Valeurs du registre remises comme avant.'

    Write-Titre 'Réseau'
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'Qos' })) {
        try { Remove-NetQosPolicy -Name ([string]$e.Name) -Confirm:$false -ErrorAction Stop; Write-Ok 'Priorité QoS de Fortnite retirée.' }
        catch { $erreurs++; Write-Attention "QoS : $($_.Exception.Message)" }
    }
    $cartes = @{}
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'Nic' })) {
        try {
            Set-NetAdapterAdvancedProperty -Name $e.Path -RegistryKeyword $e.Name -RegistryValue ([string]$e.Value) -NoRestart -Confirm:$false
            $cartes[$e.Path] = $true
        } catch {
            $erreurs++
            Write-Attention "$($e.Path) / $($e.Name) : $($_.Exception.Message)"
        }
    }
    foreach ($nomCarte in @($cartes.Keys)) {
        try { Restart-NetAdapter -Name $nomCarte -Confirm:$false; Write-Ok "$nomCarte : réglages d'origine remis." } catch { $erreurs++ }
    }

    Write-Titre 'Fortnite'
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'File' })) {
        if (Test-FortniteOuvert) { $erreurs++; Write-Attention 'Fortnite est ouvert : ses réglages n''ont pas été remis.'; continue }
        try {
            Copy-Item -LiteralPath ([string]$e.Value) -Destination ([string]$e.Path) -Force
            Write-Ok 'Fichier de réglages de Fortnite remis comme avant.'
        } catch { $erreurs++; Write-Attention "Fortnite : $($_.Exception.Message)" }
    }

    # On archive la sauvegarde pour repartir de zéro la prochaine fois.
    if ($erreurs -eq 0) {
        $archive = Join-Path $script:DossierSauvegarde ('sauvegarde-restauree-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
        Move-Item -LiteralPath $script:FichierSauvegarde -Destination $archive -Force
    }

    Write-Host ''
    if ($erreurs -eq 0) {
        Write-Host '  ============ TOUT EST REVENU COMME AVANT ============' -ForegroundColor Green
    } else {
        Write-Attention "$erreurs réglage(s) n'ont pas pu être remis (la sauvegarde est gardée : tu peux relancer « Restaurer »)."
        Write-Info 'Le point de restauration Windows « Avant optimisation Fortnite » reste aussi disponible.'
    }
    Write-Info 'Redémarre le PC pour finaliser.'
}

# ---------------------------------------------------------------------------
# Diagnostic
# ---------------------------------------------------------------------------
function Measure-Ping([string]$Cible, [int]$Nombre = 40) {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $temps = New-Object 'System.Collections.Generic.List[double]'
    $perdus = 0
    for ($i = 1; $i -le $Nombre; $i++) {
        try {
            $reponse = $ping.Send($Cible, 1000)
            if ($reponse.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $temps.Add([double]$reponse.RoundtripTime)
            } else { $perdus++ }
        } catch { $perdus++ }
        Write-Progress -Activity "Ping vers $Cible" -PercentComplete ([int]($i * 100 / $Nombre))
        Start-Sleep -Milliseconds 100
    }
    Write-Progress -Activity "Ping vers $Cible" -Completed
    $ping.Dispose()

    $resultat = [pscustomobject]@{
        Cible = $Cible; Recus = $temps.Count; Pertes = [math]::Round($perdus * 100.0 / $Nombre, 1)
        Min = 0; Moy = 0; Max = 0; Gigue = 0
    }
    if ($temps.Count -gt 0) {
        $stats = $temps | Measure-Object -Minimum -Maximum -Average
        $resultat.Min = $stats.Minimum
        $resultat.Max = $stats.Maximum
        $resultat.Moy = [math]::Round($stats.Average, 1)
        if ($temps.Count -gt 1) {
            $ecarts = 0.0
            for ($j = 1; $j -lt $temps.Count; $j++) { $ecarts += [math]::Abs($temps[$j] - $temps[$j - 1]) }
            $resultat.Gigue = [math]::Round($ecarts / ($temps.Count - 1), 1)
        }
    }
    return $resultat
}

function Show-Ping($Resultat) {
    if ($Resultat.Recus -eq 0) { Write-Attention 'Aucune réponse (la cible bloque peut-être le ping).'; return }
    Write-Info ('Moyenne {0} ms | min {1} | max {2} | gigue {3} ms | pertes {4} %' -f `
        $Resultat.Moy, $Resultat.Min, $Resultat.Max, $Resultat.Gigue, $Resultat.Pertes)
}

# Temps d'ouverture d'une connexion TCP (≈ ping) vers un datacenter.
function Measure-Tcp([string]$Hote, [int]$Port = 443, [int]$Essais = 5) {
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($Hote) |
            Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
            Select-Object -First 1
    } catch { return $null }
    if (-not $ip) { return $null }
    $meilleur = $null
    for ($i = 0; $i -lt $Essais; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $chrono = [System.Diagnostics.Stopwatch]::StartNew()
            $tache = $client.ConnectAsync($ip, $Port)
            if ($tache.Wait(2000) -and $client.Connected) {
                $chrono.Stop()
                $ms = $chrono.Elapsed.TotalMilliseconds
                if ($null -eq $meilleur -or $ms -lt $meilleur) { $meilleur = $ms }
            }
        } catch { } finally { $client.Close() }
    }
    return $meilleur
}

function Invoke-Diagnostic {
    Write-Titre 'Écran'
    try {
        $gpus = @(Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.CurrentRefreshRate -gt 0 })
        foreach ($g in $gpus) {
            Write-Info ('{0} : {1}x{2} à {3} Hz' -f $g.Name, $g.CurrentHorizontalResolution, $g.CurrentVerticalResolution, $g.CurrentRefreshRate)
            if ($g.CurrentRefreshRate -le 60) {
                Write-Attention "Écran à $($g.CurrentRefreshRate) Hz. S'il est vendu 144/165/240 Hz, règle-le au max :"
                Write-Info 'Paramètres > Système > Écran > Affichage avancé > Fréquence d''actualisation.'
            }
        }
    } catch { Write-Attention 'Impossible de lire les infos de l''écran.' }

    Write-Titre 'Type de connexion'
    $wifi = $false; $ethernet = $false
    foreach ($c in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })) {
        $estWifi = ([string]$c.PhysicalMediaType -match '802\.11') -or ($c.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN|802\.11')
        if ($estWifi) { $wifi = $true; $type = 'Wi-Fi' } else { $ethernet = $true; $type = 'Câble Ethernet' }
        Write-Info ('{0} - {1} - {2}' -f $type, $c.InterfaceDescription, $c.LinkSpeed)
        if (-not $estWifi -and [string]$c.LinkSpeed -match '^100 Mbps') {
            Write-Attention 'Câble limité à 100 Mb/s : câble abîmé ou trop vieux, prends un câble Cat 6.'
        }
    }
    if ($wifi -and -not $ethernet) {
        Write-Attention 'Tu joues en Wi-Fi : 1re cause des pics de ping et du « lag ». Un câble Ethernet change tout.'
    }

    $passerelle = $null
    try {
        $passerelle = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
            Sort-Object -Property RouteMetric | Select-Object -First 1 -ExpandProperty NextHop
    } catch { }

    $box = $null
    if ($passerelle -and $passerelle -ne '0.0.0.0') {
        Write-Titre "Ping vers ta box ($passerelle) - 40 mesures"
        $box = Measure-Ping -Cible $passerelle
        Show-Ping $box
    }

    Write-Titre 'Ping vers Internet (1.1.1.1) - 40 mesures'
    $internet = Measure-Ping -Cible '1.1.1.1'
    Show-Ping $internet

    Write-Titre 'Estimation vers les grands datacenters européens'
    $datacenters = [ordered]@{
        'Paris'     = 'dynamodb.eu-west-3.amazonaws.com'
        'Francfort' = 'dynamodb.eu-central-1.amazonaws.com'
        'Londres'   = 'dynamodb.eu-west-2.amazonaws.com'
    }
    foreach ($ville in $datacenters.Keys) {
        $ms = Measure-Tcp -Hote $datacenters[$ville]
        if ($ms) { Write-Info ('{0,-10} ~{1:N0} ms' -f $ville, $ms) } else { Write-Info ('{0,-10} injoignable' -f $ville) }
    }

    Write-Titre 'Verdict'
    if ($box -and $box.Recus -gt 0) {
        if ($box.Moy -gt 5 -or $box.Gigue -gt 3 -or $box.Pertes -gt 0) {
            Write-Attention 'Liaison PC <-> box instable (Wi-Fi / CPL / câble). Passe en câble Ethernet direct.'
        } else {
            Write-Ok 'Liaison PC <-> box : propre.'
        }
    }
    if ($internet.Recus -gt 0) {
        if ($internet.Pertes -gt 0) {
            Write-Attention "Pertes de paquets ($($internet.Pertes) %) : téléportations, tirs non comptés. Redémarre la box ; si ça dure, appelle ton FAI."
        }
        if ($internet.Gigue -gt 5) {
            Write-Attention "Ping instable (gigue $($internet.Gigue) ms) : quelqu'un télécharge / regarde un stream, ou Wi-Fi."
        }
        if ($internet.Moy -le 20)     { Write-Ok "Ping Internet excellent ($($internet.Moy) ms)." }
        elseif ($internet.Moy -le 40) { Write-Ok "Ping Internet correct ($($internet.Moy) ms)." }
        else { Write-Attention "Ping Internet élevé ($($internet.Moy) ms) : ADSL, box 4G/5G ou réseau saturé." }
    }
    Write-Info 'Le chiffre qui compte vraiment : dans Fortnite, active les « statistiques réseau » (Net Debug Stats).'
    Write-Info 'Test de saturation de la box (bufferbloat) : https://www.waveform.com/tools/bufferbloat'
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------
function Invoke-Choix([string]$Choix) {
    switch ($Choix) {
        'Tout'       { Invoke-Tout }
        'Partie'     { Start-ModePartie }
        'Connexion'  { Invoke-Application 'CONNEXION : réduire le ping et les pics de lag' $script:DetailsConnexion { Invoke-SectionConnexion } $true }
        'Latence'    { Invoke-Application 'LATENCE : supprimer le délai (input lag)' $script:DetailsLatence { Invoke-SectionLatence } $false }
        'Fps'        { Invoke-Application 'FPS : plus d''images par seconde' $script:DetailsFps { Invoke-SectionFps } $false }
        'Fortnite'   { Invoke-Application 'FORTNITE : réglages du jeu' $script:DetailsFortnite { Invoke-SectionFortnite } $false }
        'Pc'         { Invoke-Application 'PC COMPLET : Windows plus léger' $script:DetailsPc { Invoke-SectionPc } $false }
        'Diagnostic' { Invoke-Diagnostic }
        'Restaurer'  { Invoke-Restauration }
    }
}

function Show-Menu {
    $correspondance = @{ '1' = 'Tout'; '2' = 'Partie'; '3' = 'Connexion'; '4' = 'Latence'; '5' = 'Fps'; '6' = 'Fortnite'; '7' = 'Pc'; '8' = 'Diagnostic'; '9' = 'Restaurer' }
    while ($true) {
        Clear-Host
        Write-Banniere
        Write-Host '   1. TOUT OPTIMISER EN UN CLIC  (à faire une fois)' -ForegroundColor Green
        Write-Host '   2. MODE PARTIE  (avant chaque session : ping au minimum)' -ForegroundColor Green
        Write-Host ''
        Write-Host '   3. Connexion  : réduire le ping et les pics de lag'
        Write-Host '   4. Latence    : supprimer le délai (input lag)'
        Write-Host '   5. FPS        : plus d''images par seconde, plus stables'
        Write-Host '   6. Fortnite   : réglages du jeu (plein écran, V-Sync, Reflex...)'
        Write-Host '   7. PC complet : Windows plus léger + nettoyage'
        Write-Host ''
        Write-Host '   8. Diagnostic : écran, Wi-Fi ou câble, ping, gigue, pertes'
        Write-Host '   9. Restaurer  : tout remettre comme avant'
        Write-Host '   0. Quitter'
        Write-Host ''
        $choix = "$(Read-Host '  Ton choix')".Trim()
        if ($choix -eq '0') { return }
        if (-not $correspondance.ContainsKey($choix)) { continue }
        Invoke-Choix $correspondance[$choix]
        Write-Host ''
        Read-Host '  Appuie sur Entrée pour revenir au menu' | Out-Null
    }
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
    $argumentsPs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action"
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argumentsPs
    } catch {
        Write-Host 'Droits administrateur refusés : impossible de continuer.' -ForegroundColor Red
        Read-Host 'Appuie sur Entrée pour fermer' | Out-Null
    }
    exit
}

try { $Host.UI.RawUI.WindowTitle = 'Optimisation Fortnite v3' } catch { }

# Mode partie mal fermé (fenêtre fermée, PC redémarré) : on remet le Wi-Fi normal.
if ($Action -ne 'Partie' -and (Test-Path -LiteralPath $script:FichierPartie) -and -not (Test-PartieActive)) {
    try { Stop-ModePartie -Silencieux } catch { }
}

if ($Action -eq 'Menu') {
    Show-Menu
} else {
    Invoke-Choix $Action
    Read-Host '  Appuie sur Entrée pour fermer' | Out-Null
}
