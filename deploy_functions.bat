@echo off
echo Deploying Firebase Functions...

REM Check if firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo You are not logged in to Firebase. Please run:
    echo firebase login
    pause
    exit /b 1
)

REM Deploy functions
echo Deploying functions...
firebase deploy --only functions

if %errorlevel% equ 0 (
    echo Functions deployed successfully!
    echo.
    echo Your function URL will be:
    echo https://us-central1-pivot-28563.cloudfunctions.net/send_notification
) else (
    echo Deployment failed!
    pause
    exit /b 1
)

pause 