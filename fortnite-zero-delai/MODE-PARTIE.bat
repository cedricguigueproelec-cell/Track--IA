@echo off
rem A lancer avant chaque session : ping et delai au minimum pendant la partie.
title Mode partie Fortnite
set "SCRIPT=%~dp0Optimiser-Fortnite.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0..\fortnite-opti\Optimiser-Fortnite.ps1"
if not exist "%SCRIPT%" (
    echo Fichier Optimiser-Fortnite.ps1 introuvable.
    echo Garde tous les fichiers du dossier ensemble, puis relance.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Action Partie
