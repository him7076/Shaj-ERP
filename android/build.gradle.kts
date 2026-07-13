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

    tasks.whenTaskAdded {
        if (name.contains("checkReleaseAarMetadata") || name.contains("checkDebugAarMetadata")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
