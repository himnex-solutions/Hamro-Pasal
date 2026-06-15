@echo off
title Smart Saoji - SMTP Credentials Configurator
cls
echo ============================================================
echo   Smart Saoji - Supabase SMTP Secrets Configurator
echo ============================================================
echo.
echo This script will set the SMTP credentials for your Supabase 
echo project's send-email Edge Function.
echo.
echo PREREQUISITES:
echo 1. You must have the Supabase CLI installed.
echo 2. You must have run 'supabase login' to authenticate.
echo 3. You need a Google App Password for your Google ID.
echo.

set /p PROJECT_REF="Enter your Supabase Project Reference (e.g., abcdefghijklmnopqrst): "
if "%PROJECT_REF%"=="" (
    echo.
    echo Error: Project Reference is required!
    pause
    exit /b
)

set GMAIL_USER=smartsaoji@gmail.com
set /p GMAIL_USER="Enter your new Google Email [default: %GMAIL_USER%]: "

set GMAIL_APP_PASS=ehowncpvrhjtprf
set /p GMAIL_APP_PASS="Enter your 16-character Google App Password [default: %GMAIL_APP_PASS%]: "


:: Remove spaces from the app password if any
set GMAIL_APP_PASS=%GMAIL_APP_PASS: =%

echo.
echo Configuring SMTP secrets for project: %PROJECT_REF%...
echo Gmail User: %GMAIL_USER%
echo Host: smtp.gmail.com
echo Port: 587
echo.

call supabase secrets set --project-ref %PROJECT_REF% SMTP_HOST=smtp.gmail.com SMTP_PORT=587 SMTP_USER="%GMAIL_USER%" SMTP_PASS="%GMAIL_APP_PASS%" SMTP_FROM="Smart Saoji <%GMAIL_USER%>"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo   SUCCESS: SMTP Secrets configured successfully!
    echo ============================================================
) else (
    echo.
    echo ============================================================
    echo   ERROR: Failed to configure secrets. Please check the error
    echo   message above and make sure you are logged in via Supabase CLI.
    echo ============================================================
)
echo.
pause
