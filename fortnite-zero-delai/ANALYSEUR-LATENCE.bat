@echo off
rem Analyseur de latence Fortnite : mesure ton vrai delai clic -> ecran et trouve ce qui le cause.
title Analyseur de latence Fortnite
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Analyseur-Latence.ps1"
