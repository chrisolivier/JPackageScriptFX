# FORK of JPackageScriptFX #
A POC to demonstrate how to integrate fxlauncher from Edvin and use scripts from JPackageScriptFX to build self-contained,  
platform-specific executables and installers of your JavaFX applications with the ability to auto update.  

Documentation of [JPackageScriptFX](https://github.com/dlemmermann/JPackageScriptFX).  
Documentation of [fxlauncher](https://github.com/edvin/fxlauncher).  

I made a [fork](https://github.com/chrisolivier/fxlauncher) of fxlauncher to get it works with JDK 17 and OpenJFX 18.  
This POC is based on this fork. 

### How to use

First update the pom of the jpackagefx-main project with your data, this project is a sample that should be replace by your own project.  
Most important is to update app.url and app.deploy.target properties it's where your app will be stored.  

```bash
    <properties>
        <client.version>1.0.0</client.version>
        <exec.maven.plugin.version>1.6.0</exec.maven.plugin.version>
        <fxlauncher.version>1.0.0-SNAPSHOT</fxlauncher.version>
        
        <!-- tornado properties -->
        <!-- The JavaFX Application class name -->
        <app.mainClass>com.dlsc.jpackagefx.App</app.mainClass>

        <!-- Optional parameters to the application, will be embedded in the launcher and can be overriden on the command line -->
        <app.parameters>--myOption=myValue --myOtherOption=myOtherValue</app.parameters>
        
        <!-- Optional override to specify where the cached files are stored. Default is current working directory -->
		<app.cacheDir>USERLIB/JPackageScriptFX</app.cacheDir>

        <!-- Base URL where you will host the application artifacts -->
        <app.url>http://localhost:8080/</app.url>

        <!-- Optional scp target for application artifacts hosted at the above url -->
        <app.deploy.target>login@localhost:www</app.deploy.target>

        <!-- The app and launcher will be assembled in this folder -->
        <app.dir>${project.build.directory}/libs</app.dir>

        <!-- Should the client downgrade if the server version is older than the local version? -->
        <app.acceptDowngrade>false</app.acceptDowngrade>
    </properties>
```

Next, update the pom  of the jpackagefx-launcher.

```bash
	<properties>
		<javafx.version>18</javafx.version>
		<maven.compiler.source>17</maven.compiler.source>
		<maven.compiler.target>17</maven.compiler.target>
		
		<exec.maven.plugin.version>1.6.0</exec.maven.plugin.version>
		<fxlauncher.version>1.0.0-SNAPSHOT</fxlauncher.version>

		<!-- tornado properties -->
		<!-- Installer Filename without suffix -->
		<app.name>JPackageScriptFX</app.name>

		<!-- The Application vendor used by javapackager -->
		<app.vendor>Acme Inc.</app.vendor>

		<!-- The Application version used by javapackager -->
		<app.version>1.0.0</app.version>

		<!-- Base URL where you will host the application artifacts -->
		<app.url>http://localhost:8080/</app.url>

		<!-- The app and launcher will be assembled in this folder -->
		<app.dir>target/libs</app.dir>

		<!-- Native installers will be built in this folder -->
		<app.installerdir>target/installer</app.installerdir>
	</properties>
```

### How to build

##### Package the parent project  

Go to the JPackageScriptFX folder:  

```bash
	mvn clean package
```
At this point your app will be ready on your remote folder.


##### Then generate the launcher  

Go to the jpackagefx-launcher project:    

```bash
	mvn clean install
```
You will find the installer in jpackagefx-launcher/target/installer/JPackageScriptFX/bin for linux.
This has to be done for each os linux, win and mac but only once as the launcher will not need to be updated.
