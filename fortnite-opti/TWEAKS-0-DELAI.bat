@echo off
rem Applique tous les tweaks (ping, latence, FPS, Fortnite, Windows) en un clic.
title Tweaks 0 delai Fortnite
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimiser-Fortnite.ps1" -Action Tout
