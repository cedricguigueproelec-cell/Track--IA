@echo off
REM Relance automatiquement le bot s'il s'arrete ou plante, sans intervention.
REM A utiliser a la place d'un lancement direct de "python bot.py" si vous
REM voulez une resilience maximale (ex: pendant une absence prolongee).

cd /d %~dp0
call venv\Scripts\activate.bat

:loop
echo [%date% %time%] Demarrage du bot...
python bot.py
echo [%date% %time%] Le bot s'est arrete (code %errorlevel%), relance dans 15 secondes...
timeout /t 15 /nobreak > nul
goto loop
