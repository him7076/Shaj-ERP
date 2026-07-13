allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureNamespace = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android")
            if (android != null) {
                // Resolve missing namespaces
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    if (getNamespace.invoke(android) == null) {
                        val packageName = "com.example." + project.name.replace("-", ".").replace("_", ".")
                        setNamespace.invoke(android, packageName)
                    }
                } catch (e: Exception) {
                    // Ignore reflection errors if properties differ
                }

                // Dynamically align compileSdk to 36 for all dependencies to support latest lifecycle/geolocator libs
                try {
                    val compileSdkMethod = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    compileSdkMethod.invoke(android, 36)
                } catch (e: Exception) {
                    try {
                        val compileSdkVersionMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        compileSdkVersionMethod.invoke(android, 36)
                    } catch (ex: Exception) {
                        // Ignore
                    }
                }
            }
        }
    }

    val cleanAndroidManifest = {
        val manifestFile = file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            try {
                var content = manifestFile.readText(Charsets.UTF_8)
                if (content.contains("package=")) {
                    val regex = Regex("""package="[^"]*"""")
                    content = content.replace(regex, "")
                    manifestFile.writeText(content, Charsets.UTF_8)
                    project.logger.quiet("Stripped package attribute from: ${manifestFile.absolutePath}")
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (state.executed) {
        configureNamespace()
        cleanAndroidManifest()
    } else {
        afterEvaluate {
            configureNamespace()
            cleanAndroidManifest()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
