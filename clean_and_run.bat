@echo off
echo =======================================================
echo             Smart Saoji - Quick Build & Memory Fixer
echo =======================================================
echo.
echo This script will free up physical memory, stop zombie Java/Gradle 
echo processes, clean the build cache, and compile your app.
echo.
pause

echo.
echo [1/4] Stopping all active background Gradle daemons to release RAM...
if exist android (
    cd android
    call gradlew --stop
    cd ..
)

echo.
echo [2/4] Cleaning the Flutter build cache...
call flutter clean

echo.
echo [3/4] Fetching latest dependencies...
call flutter pub get

echo.
echo [4/4] Launching the application...
echo Running 'flutter run' now...
call flutter run

pause
