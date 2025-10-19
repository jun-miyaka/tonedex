import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sax_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.junmiyakawa.tonedex"
        minSdk = 23        // record_android が要求（23以上）
        targetSdk = flutter.targetSdkVersion
        versionCode = 18
        versionName = "5.0.6"
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = "410410jj"
            keyAlias = "tonedex"
            keyPassword = "410410jj"
            storeType = "PKCS12" // ← ここを追加！
        }
    }

  buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        isMinifyEnabled = false
        proguardFiles(
            getDefaultProguardFile("proguard-android.txt"),
            "proguard-rules.pro"
        )

        // 🔽 Kotlin DSL 用：Lint無効化
        lint {
            checkReleaseBuilds = false
            abortOnError = false
        }
        }
    }
}

flutter {
    source = "../.."
}
