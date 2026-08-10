# Keep Isar native C++ FFI bindings
-keep class dev.isar.** { *; }
-keepclassmembers class dev.isar.** { *; }
-keep class io.isar.** { *; }
-keepclassmembers class io.isar.** { *; }

# Keep Flutter FFI and native library loading
-keep class java.lang.System { *; }
-keep class com.sun.jna.** { *; }
