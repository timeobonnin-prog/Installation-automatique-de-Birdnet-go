@echo off
title BirdNET-Go Server
color 0A
echo ====================================================
echo   Lancement de BirdNET-Go...
echo ====================================================
echo.

:: Ouvre le navigateur en arrière-plan
start http://localhost:8080

:: Lance le serveur (la fenêtre restera ouverte grâce à l'appel direct)
"%~dp0birdnet-go.exe"

:: Si le serveur s'arrête ou plante, on met en pause pour que l'utilisateur puisse lire l'erreur
echo.
echo Le serveur s'est arrete. Appuyez sur une touche pour fermer.
pause > nul
