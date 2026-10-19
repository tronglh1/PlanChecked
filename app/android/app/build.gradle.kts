import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Release hardening notes:
// - versionCode/versionName come from pubspec.yaml `version: x.y.z+N` through the
//   Flutter Gradle plugin (override with --build-name / --build-number).
// - compileSdk/targetSdk follow the Flutter SDK defaults; the check below fails the
//   build if the pinned Flutter ever ships a targetSdk below Google Play's minimum.
val playMinTargetSdk = 35
check(flutter.targetSdkVersion >= playMinTargetSdk) {
    "targetSdk ${flutter.targetSdkVersion} is below Google Play's requirement ($playMinTargetSdk)"
}

// Firebase (FCM): the google-services plugin is applied only when the owner has put
// google-services.json in android/app (CI writes it from a secret). Without the file
// the app still builds and push is simply disabled (see push_service.dart).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.planchecked.vuonnha"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time on API < 26).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.planchecked.vuonnha"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // R8 shrinking + resource shrinking; keep rules live in proguard-rules.pro.
            // mapping.txt is written to build/app/outputs/mapping/release/.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Uses key.properties (android/key.properties) when present,
            // otherwise falls back to debug signing so CI/local release builds still work.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
