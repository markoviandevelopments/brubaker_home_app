# Flutter-specific rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Firebase-specific rules (since you're using google-services)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Add rules for other libraries if needed
-keep class com.brubaker.** { *; }
-dontwarn com.brubaker.**