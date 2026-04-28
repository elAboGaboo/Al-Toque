# CanchApp ProGuard Rules
# Android minSdk 24, targetSdk 34

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Firestore
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# QR Scanner
-keep class com.google.zxing.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local notifications
-keep class com.dexterous.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep Google Maps
-keep class com.google.maps.** { *; }
-keep class com.google.android.libraries.maps.** { *; }

# Keep model classes (Firestore serialization)
-keep class pe.canchapp.app.** { *; }
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
