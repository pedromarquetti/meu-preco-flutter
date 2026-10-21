# Flutter embedding keeps. R8 removes reflection-based engine bindings
# unless they are retained explicitly.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Required by flutter_secure_storage (uses platform crypto via reflection).
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Flutter's embedding ships Play Store deferred-component support that only
# activates when an app opts into deferred components. This app does not: there
# is no `deferred-components` configuration in pubspec.yaml or Gradle, so the
# `PlayStoreDeferredComponentManager` / `FlutterPlayStoreSplitApplication`
# references never execute at runtime. R8 cannot prove that and reports the
# Play Core classes below as missing. Suppress only these warnings; the runtime
# classes are not required and no Play Core dependency is added.
# Regenerate with `flutter build apk --release` and review against the Flutter
# embedding version if it is upgraded.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
