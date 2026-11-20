@echo off
title BirdNET-Go Server
color 0A
echo ====================================================
echo   Lancement de BirdNET-Go...
echo ====================================================
echo.

:: Ouvre le navigateur en arrière-plan (après 2 secondes)
start "" cmd /c "timeout /t 2 >nul & start http://localhost:8080"

:: Lance le serveur (avec l'argument "serve" !)
"%~dp0birdnet-go.exe" serve

:: Si le serveur s'arrête ou plante, on met en pause pour que l'utilisateur puisse lire l'erreur
echo.
echo Le serveur s'est arrete. Appuyez sur une touche pour fermer.
pause > nul
