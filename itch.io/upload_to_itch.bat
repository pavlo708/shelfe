@echo off
set PROJECT_NAME=pavlo708/cabinet
set CHANNEL=win
set BUILD_PATH="C:\Users\vana7\OneDrive\Dokumente\shelfe\build"

echo --------------------------------------------------
echo Подготовка к загрузке обновления на Itch.io...
echo --------------------------------------------------

butler push %BUILD_PATH% %PROJECT_NAME%:%CHANNEL%

echo --------------------------------------------------
echo Обновление успешно отправлено!
echo --------------------------------------------------
pause