# ProGuard rules for Go Wapit (ML Kit Barcode Scanning, CameraX, Mobile Scanner)

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# AndroidX CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Mobile Scanner Flutter Plugin
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**

# Flutter framework
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
