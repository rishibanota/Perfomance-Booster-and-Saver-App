# Micro Native App ProGuard / R8 Rules
-repackageclasses ''
-allowaccessmodification
-dontusemixedcaseclassnames
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

-keep class com.example.perfomance_booster.micro.** { *; }
