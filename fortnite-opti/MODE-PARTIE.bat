@echo off
rem A lancer avant chaque session de Fortnite : ping au minimum pendant la partie.
title Mode partie Fortnite
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimiser-Fortnite.ps1" -Action Partie
