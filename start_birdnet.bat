@echo off
title BirdNET-Go
echo ====================================================
echo   Lancement de BirdNET-Go...
echo   L'interface Web va s'ouvrir dans votre navigateur.
echo   Adresse : http://localhost:8080
echo ====================================================
echo.
echo Ne fermez pas cette fenetre, c'est le serveur !
echo.

:: Lancement du serveur en arrière-plan
start "" "%~dp0birdnet-go.exe"

:: Attente de 3 secondes pour laisser le temps au serveur de démarrer
timeout /t 3 /nobreak > NUL

:: Ouverture du navigateur par défaut
start http://localhost:8080
