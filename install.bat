@echo off
rem Set the variables below to your desired values, before invoking this script.
rem The default values are set for a typical personal install.

rem This directory will contain binaries, default assets, locale and dll's
set INSTALL_DIRECTORY=%LOCALAPPDATA%\.opentaiko
rem This will be the directory where maps, custom assets and personal settings
rem are located. Set this to "disabled" (without the quotes) if you are
rem installing for multiple users.
set USER_DIRECTORY=disabled
rem The batch file required to start the game will be created in this directory.
set SHORTCUT_DIRECTORY=%APPDATA%"\Microsoft\Windows\Start Menu\Programs\OpenTaiko"
rem This will be the name of the shortcut.
set SHORTCUT_NAME="Launch OpenTaiko.bat"

set COMPILEFIRST=You need to compile the game before you can install. See README.md for details.

if not exist "OpenTaiko.exe" echo %COMPILEFIRST% && timeout /T -1 && exit

echo Copying files...
if not exist %INSTALL_DIRECTORY% mkdir %INSTALL_DIRECTORY%
robocopy . %INSTALL_DIRECTORY% *.exe *.dll
if not exist %INSTALL_DIRECTORY%\assets mkdir %INSTALL_DIRECTORY%\assets
robocopy assets\ %INSTALL_DIRECTORY%\assets /E
if not exist %INSTALL_DIRECTORY%\locale mkdir %INSTALL_DIRECTORY%\locale
robocopy locale\ %INSTALL_DIRECTORY%\locale /E
if not exist %INSTALL_DIRECTORY%\maps mkdir %INSTALL_DIRECTORY%\maps
robocopy maps\ %INSTALL_DIRECTORY%\maps /E

echo Creating shortcut...
if not exist %SHORTCUT_DIRECTORY% mkdir %SHORTCUT_DIRECTORY%
echo ^@echo off>%SHORTCUT_DIRECTORY%\%SHORTCUT_NAME%
echo set OPENTAIKO_INSTALLDIR=%INSTALL_DIRECTORY%>>%SHORTCUT_DIRECTORY%\%SHORTCUT_NAME%
if not %USER_DIRECTORY%==disabled echo set OPENTAIKO_USERDIR=%USER_DIRECTORY%>>%SHORTCUT_DIRECTORY%\%SHORTCUT_NAME%
echo %INSTALL_DIRECTORY%\OpenTaiko.exe>>%SHORTCUT_DIRECTORY%\%SHORTCUT_NAME%

echo Installation finished.
echo You can run the installed game from the batch file at %SHORTCUT_DIRECTORY%\%SHORTCUT_NAME%.
echo You can also create a shortcut manually. To do this, find the executable in %INSTALL_DIRECTORY%\OpenTaiko.exe and use "create shortcut" and then add " --install-dir %INSTALL_DIRECTORY%" to the target.
timeout /T -1
