@echo off
rem Annule la reparation de Windows Update (dossiers d'origine + Restauration du systeme).
title Annuler la reparation de Windows Update
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reparer-WindowsUpdate.ps1" -Action Annuler
