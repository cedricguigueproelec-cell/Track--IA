@echo off
rem Remet TOUS les reglages modifies par les tweaks exactement comme avant.
title Restaurer tout comme avant
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimiser-Fortnite.ps1" -Action Restaurer
