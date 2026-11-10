@echo off
rem Lance l'optimisation Fortnite (demande les droits administrateur).
title Optimisation Fortnite
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimiser-Fortnite.ps1"
