@echo off
setlocal EnableExtensions
title Kit Profissional de Diagnostico Windows V2.0

REM ------------------------------------------------------------
REM KIT PROFISSIONAL DE DIAGNOSTICO WINDOWS V2.0
REM Eleva automaticamente para obter o maximo de informacoes.
REM Nenhuma alteracao de sistema e feita sem confirmacao no PS1.
REM ------------------------------------------------------------
set "BASE=%~dp0"
set "SCRIPT=%BASE%Diagnostico_V2.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo [ERRO] Diagnostico_V2.ps1 nao foi encontrado.
    echo Coloque Diagnostico_V2.bat e Diagnostico_V2.ps1 na mesma pasta.
    pause
    exit /b 1
)

REM Verifica se ja esta elevado.
net session >nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo Solicitando permissao de Administrador...
    powershell.exe -NoLogo -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

REM Windows PowerShell 5.1 e usado por compatibilidade com Windows 10/11.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
    echo O diagnostico terminou com codigo %EXITCODE%.
)
echo.
echo Relatorios: %USERPROFILE%\Desktop\Diagnosticos_PC
pause
exit /b %EXITCODE%
