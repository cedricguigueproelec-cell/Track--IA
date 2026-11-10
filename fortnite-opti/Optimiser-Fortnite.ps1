<#
.SYNOPSIS
    Optimisation Windows pour Fortnite : moins d'input lag, FPS plus stables,
    connexion plus propre.

.DESCRIPTION
    N'applique que des réglages documentés, sans danger et 100 % réversibles :
    chaque valeur est sauvegardée AVANT d'être modifiée, et l'option
    « Restaurer » remet tout exactement comme avant.

    Ce script ne touche PAS :
      - aux fichiers du jeu ni à l'anti-cheat (Easy Anti-Cheat) -> aucun risque de ban ;
      - à la sécurité de Windows (Defender, pare-feu, mises à jour, mitigations CPU).

.PARAMETER Action
    Menu (par défaut), Appliquer, Restaurer ou Diagnostic.

.EXAMPLE
    Double-clic sur LANCER.bat (recommandé).
#>
[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Appliquer', 'Restaurer', 'Diagnostic')]
    [string]$Action = 'Menu'
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------
$script:DossierSauvegarde = Join-Path $env:USERPROFILE 'FortniteOpti-Sauvegarde'
$script:FichierSauvegarde = Join-Path $script:DossierSauvegarde 'sauvegarde.json'
$script:RegexGuid         = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
$script:GuidUltimate      = 'e9a42b02-d5df-448d-aa00-03f14749eb61'  # Performances optimales
$script:GuidHautesPerf    = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'  # Performances élevées

$script:Sauvegarde = New-Object System.Collections.ArrayList
$script:DejaSauve  = @{}

# ---------------------------------------------------------------------------
# Affichage
# ---------------------------------------------------------------------------
function Write-Titre([string]$Texte)     { Write-Host ''; Write-Host "[*] $Texte" -ForegroundColor Cyan }
function Write-Ok([string]$Texte)        { Write-Host "    [OK] $Texte" -ForegroundColor Green }
function Write-Info([string]$Texte)      { Write-Host "         $Texte" -ForegroundColor Gray }
function Write-Attention([string]$Texte) { Write-Host "    [!]  $Texte" -ForegroundColor Yellow }

function Write-Banniere {
    Write-Host ''
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host '     OPTIMISATION FORTNITE  -  latence minimale'      -ForegroundColor Magenta
    Write-Host '  ==================================================' -ForegroundColor Magenta
    Write-Host ''
}

function Read-Oui([string]$Question) {
    $reponse = Read-Host "  $Question (O/N)"
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

# ---------------------------------------------------------------------------
# Étapes d'optimisation
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

function Set-PlanAlimentation {
    $cpu = ''
    try { $cpu = [string](Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 -ExpandProperty Name) } catch { }

    # Les Ryzen X3D ont besoin du plan « Utilisation normale » + du Mode Jeu
    # pour que le pilote AMD place Fortnite sur les cœurs avec le cache 3D.
    if ($cpu -match 'X3D') {
        Write-Ok "Processeur $($cpu.Trim()) détecté : on GARDE le plan « Utilisation normale »."
        Write-Info "C'est ce plan + le Mode Jeu qui permettent à AMD de mettre Fortnite sur les bons cœurs."
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
        Write-Attention "Ce PC n'expose que le plan « Utilisation normale » (fréquent sur les portables récents)."
        Write-Info "Règle-le à la main : Paramètres > Système > Alimentation > Mode d'alimentation > « Performances optimales »."
        return
    }

    $r = Invoke-Natif 'powercfg.exe' @('/setactive', $cible)
    if ($r.Code -ne 0) { throw "powercfg n'a pas pu activer le plan : $($r.Texte)" }
    Write-Ok "Plan « $nom » activé (le processeur ne se met plus en économie pendant les combats)."
    if ($portable) {
        Write-Attention "PC portable : joue BRANCHÉ sur secteur, sinon la carte graphique est bridée."
    }
}

function Set-ModeJeu {
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1
    Write-Ok "Mode Jeu activé (Windows Update ne s'installe pas en pleine partie, priorité au jeu)."

    Set-ValeurRegistre -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0
    Set-ValeurRegistre -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0
    Write-Ok "Enregistrement vidéo en arrière-plan de la Xbox Game Bar coupé (il mange des FPS)."
    Write-Info "(ShadowPlay / NVIDIA App et Medal ne sont pas concernés.)"
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
        $exe = Join-Path $dossier 'FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe'
        if (Test-Path -LiteralPath $exe) { return [System.IO.Path]::GetFullPath($exe) }
    }
    return $null
}

function Set-OptionsGraphiques {
    $cle = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'

    $exe = Get-FortniteExe
    if ($exe) {
        Set-ValeurRegistre -Path $cle -Name $exe -Value 'GpuPreference=2;' -Type 'String'
        Write-Ok "Fortnite forcé sur la carte graphique la plus puissante."
        Write-Info $exe
    } else {
        Write-Attention "Fortnite introuvable (installé ailleurs ?) : réglage GPU ignoré."
    }

    # « Optimisations pour les jeux fenêtrés » (Windows 11) : moins de latence
    # en mode fenêtré / plein écran fenêtré.
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
    Write-Ok "Optimisations pour les jeux fenêtrés activées (Windows 11)."
}

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
    Write-Ok "« Améliorer la précision du pointeur » désactivé : la souris bouge en 1:1 partout."
    Write-Info "(En partie, Fortnite lit déjà la souris en direct ; ça rend surtout menus et éditions cohérents.)"
}

function Set-PrioriteJeux {
    $profil = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-ValeurRegistre -Path $profil -Name 'NetworkThrottlingIndex' -Value -1   # 0xFFFFFFFF = pas de bridage réseau
    Set-ValeurRegistre -Path $profil -Name 'SystemResponsiveness' -Value 10     # 10 % réservés aux tâches de fond (minimum)

    $jeux = "$profil\Tasks\Games"
    Set-ValeurRegistre -Path $jeux -Name 'GPU Priority' -Value 8
    Set-ValeurRegistre -Path $jeux -Name 'Priority' -Value 6
    Set-ValeurRegistre -Path $jeux -Name 'Scheduling Category' -Value 'High' -Type 'String'
    Set-ValeurRegistre -Path $jeux -Name 'SFIO Priority' -Value 'High' -Type 'String'
    Write-Ok "Planificateur multimédia : priorité aux jeux, pas de bridage réseau (gain léger, sans risque)."
}

function Set-CarteReseau {
    $cartes = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
    if ($cartes.Count -eq 0) { Write-Info "Aucune carte réseau active trouvée."; return }

    # Fonctions d'économie d'énergie qui ajoutent des micro-coupures / du délai.
    # Mots-clés standard des pilotes (indépendants de la langue de Windows).
    $motsCles = @('*EEE', 'EEELinkAdvertisement', 'AdvancedEEE', 'EnableGreenEthernet',
                  'GreenEthernet', 'PowerSavingMode', 'ULPMode')

    foreach ($carte in $cartes) {
        $modifiee = $false
        $proprietes = @(Get-NetAdapterAdvancedProperty -Name $carte.Name -ErrorAction SilentlyContinue)
        foreach ($motCle in $motsCles) {
            $p = $proprietes | Where-Object { $_.RegistryKeyword -eq $motCle } | Select-Object -First 1
            if (-not $p) { continue }
            $valeurActuelle = [string](@($p.RegistryValue)[0])
            if ($valeurActuelle -eq '0') { continue }
            if ($p.ValidRegistryValues -and (@($p.ValidRegistryValues) -notcontains '0')) { continue }
            try {
                Add-Entree -Id "NIC|$($carte.Name)|$motCle" -Kind 'Nic' -Path $carte.Name -Name $motCle -Value $valeurActuelle
                Set-NetAdapterAdvancedProperty -Name $carte.Name -RegistryKeyword $motCle -RegistryValue '0' -NoRestart -Confirm:$false
                $modifiee = $true
                Write-Ok "$($carte.Name) : « $($p.DisplayName) » désactivé."
            } catch {
                Write-Attention "$($carte.Name) : « $($p.DisplayName) » non modifiable ($($_.Exception.Message))."
            }
        }
        if ($modifiee) {
            Write-Info "Redémarrage de « $($carte.Name) » (coupure de quelques secondes)..."
            Restart-NetAdapter -Name $carte.Name -Confirm:$false
        } else {
            Write-Ok "$($carte.Name) : rien à changer."
        }
    }
}

# ---------------------------------------------------------------------------
# Actions du menu
# ---------------------------------------------------------------------------
function Invoke-Optimisation {
    Write-Titre 'Ce qui va être fait'
    Write-Info '1. Point de restauration Windows (filet de sécurité)'
    Write-Info '2. Plan d''alimentation hautes performances'
    Write-Info '3. Mode Jeu activé + enregistrement Game Bar en arrière-plan coupé'
    Write-Info '4. Fortnite sur la carte graphique dédiée + jeux fenêtrés optimisés'
    Write-Info '5. Accélération de la souris Windows désactivée'
    Write-Info '6. Priorité aux jeux dans le planificateur multimédia'
    Write-Info '7. Économies d''énergie de la carte réseau désactivées'
    Write-Host ''
    Write-Attention 'Ferme Fortnite et le launcher Epic avant de continuer.'
    Write-Attention 'Internet peut couper quelques secondes pendant l''étape 7.'
    if (-not (Read-Oui 'Continuer ?')) { Write-Info 'Annulé, rien n''a été modifié.'; return }

    Read-Sauvegarde

    Invoke-Etape 'Point de restauration Windows (peut prendre 1 minute)' {
        Checkpoint-Computer -Description 'Avant optimisation Fortnite' -RestorePointType 'MODIFY_SETTINGS'
        Write-Ok 'Point de restauration prêt (Windows n''en crée qu''un par 24 h).'
    }
    Invoke-Etape 'Plan d''alimentation'                                     { Set-PlanAlimentation }
    Invoke-Etape 'Mode Jeu + Game Bar'                                      { Set-ModeJeu }
    Invoke-Etape 'Carte graphique'                                          { Set-OptionsGraphiques }
    Invoke-Etape 'Souris'                                                   { Set-Souris }
    Invoke-Etape 'Priorité aux jeux'                                        { Set-PrioriteJeux }
    Invoke-Etape 'Carte réseau'                                             { Set-CarteReseau }

    Write-Host ''
    Write-Host '  ==================== TERMINÉ ====================' -ForegroundColor Green
    Write-Info "Réglages d'origine sauvegardés dans : $script:FichierSauvegarde"
    Write-Info 'Pour tout annuler : relance LANCER.bat et choisis « 2. Restaurer ».'
    Write-Host ''
    Write-Attention 'Le plus gros gain reste dans les réglages de Fortnite et de ta carte graphique :'
    Write-Attention 'suis le guide README.md (Plein écran, Mode Performance, NVIDIA Reflex, câble Ethernet...).'
    Write-Host ''
    if (Read-Oui 'Redémarrer le PC maintenant (conseillé) ?') { Restart-Computer -Force }
}

function Invoke-Restauration {
    Read-Sauvegarde
    if ($script:Sauvegarde.Count -eq 0) { Write-Attention 'Aucune sauvegarde trouvée : rien à restaurer.'; return }
    if (-not (Read-Oui 'Remettre TOUS les réglages comme avant ?')) { return }

    $entrees = @($script:Sauvegarde.ToArray())
    [array]::Reverse($entrees)
    $erreurs = 0

    Write-Titre 'Plan d''alimentation'
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'PowerScheme' })) {
        $r = Invoke-Natif 'powercfg.exe' @('/setactive', [string]$e.Value)
        if ($r.Code -eq 0) { Write-Ok "Plan d'origine réactivé." } else { $erreurs++; Write-Attention $r.Texte }
    }
    foreach ($e in @($entrees | Where-Object { $_.Kind -eq 'PowerCreated' })) {
        $r = Invoke-Natif 'powercfg.exe' @('/delete', [string]$e.Value)
        if ($r.Code -eq 0) { Write-Ok 'Plan « Performances optimales » supprimé.' }
    }

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

    Write-Titre 'Carte réseau'
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
    if ($cartes.Count -eq 0) { Write-Ok 'Rien à remettre.' }

    # On archive la sauvegarde pour repartir de zéro la prochaine fois.
    $archive = Join-Path $script:DossierSauvegarde ("sauvegarde-restauree-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date))
    Move-Item -LiteralPath $script:FichierSauvegarde -Destination $archive -Force

    Write-Host ''
    if ($erreurs -eq 0) {
        Write-Host '  ============ TOUT EST REVENU COMME AVANT ============' -ForegroundColor Green
    } else {
        Write-Attention "$erreurs réglage(s) n'ont pas pu être remis. Le point de restauration Windows « Avant optimisation Fortnite » reste disponible."
    }
    Write-Info 'Redémarre le PC pour finaliser.'
}

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

function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Banniere
        Write-Host '   1. Appliquer les optimisations'
        Write-Host '   2. Restaurer les réglages d''origine'
        Write-Host '   3. Diagnostic (écran, Wi-Fi/câble, ping, gigue, pertes)'
        Write-Host '   4. Quitter'
        Write-Host ''
        $choix = (Read-Host '  Ton choix').Trim()
        if ($choix -eq '4') { return }
        if ($choix -notin @('1', '2', '3')) { continue }
        if ($choix -eq '1') { Invoke-Optimisation }
        if ($choix -eq '2') { Invoke-Restauration }
        if ($choix -eq '3') { Invoke-Diagnostic }
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

try { $Host.UI.RawUI.WindowTitle = 'Optimisation Fortnite' } catch { }

switch ($Action) {
    'Appliquer'  { Invoke-Optimisation }
    'Restaurer'  { Invoke-Restauration }
    'Diagnostic' { Invoke-Diagnostic }
    default      { Show-Menu }
}
