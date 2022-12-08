@ECHO OFF

rem ------ ENVIRONMENT --------------------------------------------------------
rem The script depends on various environment variables to exist in order to
rem run properly. The java version we want to use, the location of the java
rem binaries (java home), and the project version as defined inside the pom.xml
rem file, e.g. 1.0-SNAPSHOT.
rem
rem PROJECT_VERSION: version used in pom.xml, e.g. 1.0-SNAPSHOT
rem APP_VERSION: the application version, e.g. 1.0.0, shown in "about" dialog

set MAIN_JAR=fxlauncher.jar
set MAIN_CLASS=fxlauncher.Start

rem Set desired installer type: "app-image" "msi" "exe".

echo "java home			: %JAVA_HOME%"
echo "java version		: %JAVA_VERSION%"
echo "intaller type		: %INSTALLER_TYPE%"
echo "app name			: %APP_NAME%"
echo "app dir			: %APP_DIR%"
echo "app dir \			: %APP_DIR:/=\%"
echo "install dir		: %INSTALL_DIR%"
echo "install dir \		: %INSTALL_DIR:/=\%"
echo "app icon			: %APP_ICON%"
echo "project version	: %PROJECT_VERSION%"
echo "app version		: %APP_VERSION%"
echo "main JAR file		: %MAIN_JAR%"
echo "main JAR file		: %MAIN_CLASS%"
echo "vendor			: %VENDOR%"

rem ------ SETUP DIRECTORIES AND FILES ----------------------------------------
rem Remove previously generated java runtime and installers. Copy all required
rem jar files into the input/libs folder.

IF EXIST target\java-runtime rmdir /S /Q  .\target\java-runtime
IF EXIST %INSTALL_DIR:/=\% rmdir /S /Q %INSTALL_DIR:/=\%
rem %string1:,=.%
xcopy /S /Q %APP_DIR:/=\%\* %INSTALL_DIR:/=\%\input\libs\
rem copy target\%MAIN_JAR% target\installer\input\libs\

rem ------ REQUIRED MODULES ---------------------------------------------------
rem Use jlink to detect all modules that are required to run the application.
rem Starting point for the jdep analysis is the set of jars being used by the
rem application.

echo detecting required modules

"%JAVA_HOME%\bin\jdeps" ^
  -q ^
  -recursive ^
  --multi-release %JAVA_VERSION% ^
  --ignore-missing-deps ^
  --module-path "mods;%INSTALL_DIR%/input/libs" ^
  --print-module-deps ^
  %INSTALL_DIR:/=\%/input\libs\%MAIN_JAR% > temp.txt

set /p detected_modules=<temp.txt

echo detected modules: %detected_modules%

rem ------ MANUAL MODULES -----------------------------------------------------
rem jdk.crypto.ec has to be added manually bound via --bind-services or
rem otherwise HTTPS does not work.
rem
rem See: https://bugs.openjdk.java.net/browse/JDK-8221674
rem
rem In addition we need jdk.localedata if the application is localized.
rem This can be reduced to the actually needed locales via a jlink parameter,
rem e.g., --include-locales=en,de.
rem
rem Don't forget the leading ','!

set manual_modules=,jdk.crypto.ec,jdk.localedata,java.management
echo manual modules: %manual_modules%

rem ------ RUNTIME IMAGE ------------------------------------------------------
rem Use the jlink tool to create a runtime image for our application. We are
rem doing this in a separate step instead of letting jlink do the work as part
rem of the jpackage tool. This approach allows for finer configuration and also
rem works with dependencies that are not fully modularized, yet.

echo creating java runtime image

call "%JAVA_HOME%\bin\jlink" ^
  --strip-native-commands ^
  --no-header-files ^
  --no-man-pages ^
  --compress=2 ^
  --strip-debug ^
  --add-modules %detected_modules%%manual_modules% ^
  --module-path "mods;%INSTALL_DIR%/input/libs" ^
  --include-locales=en,de ^
  --output target/java-runtime


rem ------ PACKAGING ----------------------------------------------------------
rem In the end we will find the package inside the target/installer directory.

echo "Creating installer of type %INSTALLER_TYPE%"

call "%JAVA_HOME%\bin\jpackage" ^
  --type %INSTALLER_TYPE% ^
  --dest %INSTALL_DIR% ^
  --input %INSTALL_DIR%/input/libs ^
  --name %APP_NAME% ^
  --main-class %MAIN_CLASS% ^
  --main-jar %MAIN_JAR% ^
  --java-options -Xmx2048m ^
  --runtime-image target/java-runtime ^
  --icon %APP_ICON% ^
  --app-version %APP_VERSION% ^
  --vendor "%VENDOR%" ^
  --copyright "Copyright © 2019-21 %VENDOR%" ^
  --win-dir-chooser ^
  --win-shortcut ^
  --win-per-user-install ^
  --win-menu
  
echo "Deleting jpackagefx-launcher jar"
del target/jpackagefx-launcher*.jar
