@echo off
rem Repare Windows Update quand une mise a jour echoue (DISM, SFC, remise a zero).
title Reparation de Windows Update
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reparer-WindowsUpdate.ps1"
