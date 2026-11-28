@echo off
rem Remet TOUS les reglages modifies par ZERO-DELAI exactement comme avant.
title Restaurer tout comme avant
set "SCRIPT=%~dp0Optimiser-Fortnite.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0..\fortnite-opti\Optimiser-Fortnite.ps1"
if not exist "%SCRIPT%" (
    echo Fichier Optimiser-Fortnite.ps1 introuvable.
    echo Garde tous les fichiers du dossier ensemble, puis relance.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Action Restaurer
