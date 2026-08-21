allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}



subprojects {
    // Inject namespace early and set compileSdk for all Android modules
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null) {
            val ns = android.namespace
            if (ns == null || ns.isEmpty()) {
                android.namespace = "com.example." + project.name.replace("-", ".").replace("_", "")
            }
            android.compileSdkVersion(35)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
