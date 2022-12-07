#!/bin/bash

# ------ ENVIRONMENT --------------------------------------------------------
# The script depends on various environment variables to exist in order to
# run properly. The java version we want to use, the location of the java
# binaries (java home), and the project version as defined inside the pom.xml
# file, e.g. 1.0-SNAPSHOT.
#
# PROJECT_VERSION: version used in pom.xml, e.g. 1.0-SNAPSHOT
# APP_VERSION: the application version, e.g. 1.0.0, shown in "about" dialog

MAIN_JAR="fxlauncher.jar"
MAIN_CLASS="fxlauncher.Start"

# Set desired installer type: "dmg", "pkg".

echo "java home			: $JAVA_HOME"
echo "java version		: $JAVA_VERSION"
echo "intaller type		: $INSTALLER_TYPE"
echo "app name			: $APP_NAME"
echo "app dir			: $APP_DIR"
echo "install dir		: $INSTALL_DIR"
echo "app icon			: $APP_ICON"
echo "project version	: $PROJECT_VERSION"
echo "app version		: $APP_VERSION"
echo "main JAR file		: $MAIN_JAR"
echo "main JAR file		: $MAIN_CLASS"
echo "vendor			: $VENDOR"
echo "package identifier: $PKG_IDENTIFIER"
echo "package name		: $PKG_NAME"

# ------ SETUP DIRECTORIES AND FILES ----------------------------------------
# Remove previously generated java runtime and installers. Copy all required
# jar files into the input/libs folder.

rm -rfd ./target/java-runtime/
rm -rfd ${INSTALL_DIR}/

mkdir -p ${INSTALL_DIR}/input/libs/

cp ${APP_DIR}/* ${INSTALL_DIR}/input/libs/

# ------ REQUIRED MODULES ---------------------------------------------------
# Use jlink to detect all modules that are required to run the application.
# Starting point for the jdep analysis is the set of jars being used by the
# application.

echo "detecting required modules"
detected_modules=`${JAVA_HOME}/bin/jdeps \
  -q \
  -recursive \
  --multi-release ${JAVA_VERSION} \
  --ignore-missing-deps \
  --print-module-deps \
  --module-path "mods:${INSTALL_DIR}/input/libs" \
  	${INSTALL_DIR}/input/libs/${MAIN_JAR}`

echo "detected modules: ${detected_modules}"


# ------ MANUAL MODULES -----------------------------------------------------
# jdk.crypto.ec has to be added manually bound via --bind-services or
# otherwise HTTPS does not work.
#
# See: https://bugs.openjdk.java.net/browse/JDK-8221674
#
# In addition we need jdk.localedata if the application is localized.
# This can be reduced to the actually needed locales via a jlink parameter,
# e.g., --include-locales=en,de.
#
# Don't forget the leading ','!

manual_modules=,jdk.crypto.ec,jdk.localedata,java.management
echo "manual modules: ${manual_modules}"

# ------ RUNTIME IMAGE ------------------------------------------------------
# Use the jlink tool to create a runtime image for our application. We are
# doing this in a separate step instead of letting jlink do the work as part
# of the jpackage tool. This approach allows for finer configuration and also
# works with dependencies that are not fully modularized, yet.

echo "creating java runtime image"
${JAVA_HOME}/bin/jlink \
  --strip-native-commands \
  --no-header-files \
  --no-man-pages  \
  --compress=2  \
  --strip-debug \
  --add-modules "${detected_modules}${manual_modules}" \
  --module-path "mods:${INSTALL_DIR}/input/libs" \
  --include-locales=en,fr \
  --output target/java-runtime

# ------ PACKAGING ----------------------------------------------------------
# In the end we will find the package inside the target/installer directory.

echo "Creating installer of type $INSTALLER_TYPE"

$JAVA_HOME/bin/jpackage \
--type ${INSTALLER_TYPE} \
--dest ${INSTALL_DIR} \
--input ${INSTALL_DIR}/input/libs \
--name ${APP_NAME} \
--main-class ${MAIN_CLASS} \
--main-jar ${MAIN_JAR} \
--java-options -Xmx2048m \
--runtime-image target/java-runtime \
--icon ${APP_ICON} \
--app-version ${APP_VERSION} \
--vendor "${VENDOR}" \
--copyright "Copyright © 2019-21 ${VENDOR}" \
--mac-package-identifier ${PKG_IDENTIFIER} \
--mac-package-name ${PKG_NAME}