import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is loaded from android/key.properties when that file exists.
// The file and its keystore are never committed (see .gitignore); CI generates
// them from protected environment secrets at release time.
//
// `flutter build apk --debug` never needs secrets. A release build without
// signing material falls back to the debug key so `flutter run --release` keeps
// working, but it must not be distributed: pass
// `-PrequireReleaseSigning=true` (or set the `requireReleaseSigning` Gradle
// property) to turn that fallback into a hard failure for real release builds.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val requireReleaseSigning =
    (project.findProperty("requireReleaseSigning") as String?)?.toBoolean() ?: false

if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

if (requireReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "A signed release build was requested but android/key.properties is " +
            "missing. Provide storeFile, storePassword, keyAlias, and " +
            "keyPassword before building a release artifact."
    )
}

if (!hasReleaseSigning) {
    logger.lifecycle(
        "android/key.properties not found: release builds are signed with the " +
            "debug key and must not be distributed (pass " +
            "-PrequireReleaseSigning=true to make this an error)."
    )
}

android {
    namespace = "com.app.meupreco"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Unique application ID; changing it later creates a different app
        // identity in Google Play. Must stay in sync with the `namespace`
        // above and the MainActivity package.
        applicationId = "com.app.meupreco"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Version code/name come from pubspec.yaml (`version: x.y.z+build`),
        // so every Play release only needs a pubspec version bump.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // Accept an absolute path (developer machine) or a path relative
                // to the android/ project root (portable, CI workspace).
                val storePath = keystoreProperties["storeFile"] as String
                val candidate = file(storePath)
                storeFile = if (candidate.isAbsolute) candidate
                else rootProject.file(storePath)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Explicit debug-key fallback for `flutter run --release`; not a
                // distribution artifact. `requireReleaseSigning=true` forbids it.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
