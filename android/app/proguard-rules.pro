# Flutter and R8 Optimization Rules
# Strips unused code, classes, and debug line tables while retaining Flutter embeddings

-repackageclasses ''
-allowaccessmodification
-dontusemixedcaseclassnames

# Flutter engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep MainActivity and its internal helper classes
-keep class com.example.perfomance_booster_and_saver_app.** { *; }

# Strip line numbers and debug info to minimize DEX size
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
