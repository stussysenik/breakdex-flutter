# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep class kotlin.Metadata { *; }

# Keep R8 from stripping things needed for serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Play Core (deferred components — used by Flutter internally)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# General
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe
