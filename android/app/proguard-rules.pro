# Flutter ProGuard Rules
# Keep Flutter wrapper and engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Play Core (referenced by Flutter embedding for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep platform channels
-keepclassmembers class * {
    @io.flutter.embedding.engine.systemchannels.** *;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# SQLite/sqflite plugin
-keep class com.tekartik.sqflite.** { *; }

# File picker plugin
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Image picker plugin
-keep class io.flutter.plugins.imagepicker.** { *; }

# Photo manager plugin
-keep class com.fluttercandies.photo_manager.** { *; }

# Path provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# Share plus plugin
-keep class dev.fluttercommunity.plus.share.** { *; }

# Package info plus plugin
-keep class io.flutter.plugins.packageinfo.** { *; }

# Permission handler plugin
-keep class com.baseflow.permissionhandler.** { *; }

# In-app purchase plugin
-keep class io.flutter.plugins.inapppurchase.** { *; }

# Keep Gson used by plugins (if any)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep database models and entities
-keep class com.vitomein.loadintel.** { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Preserve line numbers for debugging crashes
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
