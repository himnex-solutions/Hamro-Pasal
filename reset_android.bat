@echo off
echo =======================================================
echo              Smart Saoji - Android Resetter
echo =======================================================
echo.
echo This script will safely recreate your Android folder and
echo restore all custom configurations (Supabase deep links,
echo camera permissions, local notifications, multidex, etc.)
echo from your backup!
echo.
pause

echo.
echo [1/5] Stopping all background Gradle daemons to free up memory...
if exist android (
    cd android
    call gradlew --stop
    cd ..
)

echo.
echo [2/5] Deleting the old android folder...
if exist android (
    rmdir /s /q android
)

echo.
echo [3/5] Recreating Android folder using Flutter CLI...
call flutter create --platforms=android .

echo.
echo [4/5] Restoring custom configurations from backup...
if exist android_backup (
    copy /y android_backup\AndroidManifest.xml android\app\src\main\AndroidManifest.xml
    copy /y android_backup\build.gradle.kts android\app\build.gradle.kts
    copy /y android_backup\gradle.properties android\gradle.properties
    copy /y android_backup\settings.gradle.kts android\settings.gradle.kts
    copy /y android_backup\gradle-wrapper.properties android\gradle\wrapper\gradle-wrapper.properties
    echo Restore completed successfully!
) else (
    echo WARNING: android_backup folder not found. Custom configurations could not be restored!
)

echo.
echo [5/5] Performing a clean build and fetching dependencies...
call flutter clean
call flutter pub get

echo.
echo =======================================================
echo RESET COMPLETE! You can now run:
echo   flutter run
echo =======================================================
pause
