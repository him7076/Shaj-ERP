import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing key properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
        minSdk = 21
        targetSdk = 34
        versionCode = (flutter.versionCode as Int?) ?: 11
        versionName = (flutter.versionName as String?) ?: "1.0.8"
    }

    signingConfigs {
        create("release") {
            keyAlias = (keystoreProperties["keyAlias"] as String?) ?: "sahajkey"
            keyPassword = (keystoreProperties["keyPassword"] as String?) ?: "sahajerppassword"
            storeFile = file("release.keystore")
            storePassword = (keystoreProperties["storePassword"] as String?) ?: "sahajerppassword"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("debug") ?: signingConfigs.findByName("release")
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
