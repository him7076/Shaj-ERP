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
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

subprojects {
    val configureSubproject = {
        val android = extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>
        if (android != null) {
            if (android.namespace == null) {
                android.namespace = "com.example." + project.name.replace("-", ".").replace("_", ".")
            }
            android.compileSdk = 34
            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }

        val manifestFile = file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            try {
                var content = manifestFile.readText(Charsets.UTF_8)
                if (content.contains("package=")) {
                    val regex = Regex("""package="[^"]*"""")
                    content = content.replace(regex, "")
                    manifestFile.writeText(content, Charsets.UTF_8)
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (state.executed) {
        configureSubproject()
    } else {
        afterEvaluate {
            configureSubproject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
