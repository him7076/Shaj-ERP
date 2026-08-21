import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing key properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Load local properties for version code and name
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 11
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.8"

android {
    namespace = "com.example.business_sahaj_erp"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Application ID matched to previous release for in-place overwrite updates
        applicationId = "com.sahaj.business_sahaj_erp"
        minSdk = 23
        targetSdk = 34
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    signingConfigs {
        getByName("debug") {
            // Default AGP debug configuration
        }
        val keystoreFile = file("release.keystore")
        if (keystoreFile.exists()) {
            create("release") {
                keyAlias = (keystoreProperties["keyAlias"] as String?) ?: "sahajkey"
                keyPassword = (keystoreProperties["keyPassword"] as String?) ?: "sahajerppassword"
                storeFile = keystoreFile
                storePassword = (keystoreProperties["storePassword"] as String?) ?: "sahajerppassword"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
