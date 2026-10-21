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
