# R8 / ProGuard keep rules for Vườn Nhà release builds.
# Flutter's Gradle plugin already adds the Flutter engine rules; plugins ship
# consumer rules. These cover what has bitten Flutter release builds in practice.

# --- flutter_local_notifications: scheduled notifications are persisted as JSON
# with Gson and read back by the boot/alarm receivers; names must survive R8.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# --- Firebase / Google Play services (firebase_core, firebase_messaging)
-keep class io.flutter.plugins.firebase.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- drift / sqlite3 (drift_flutter -> sqlite3 via FFI + native libs, no reflection;
# keep JNI entry points of any bundled sqlite helper just in case)
-keep class eu.simonbinder.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# --- image_picker (+ androidx.exifinterface / activity result APIs)
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.exifinterface.** { *; }

# --- camera (in-app live preview + capture)
-keep class io.flutter.plugins.camera.** { *; }

# --- share_plus uses plain Android APIs (FileProvider / intents)
-keep class dev.fluttercommunity.plus.share.** { *; }

# --- Flutter deferred components / Play Core are not used; silence R8 missing classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep line numbers for readable crash stack traces (upload mapping.txt to Play Console).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# --- Flutter plugins talk to Dart through Pigeon-generated channels; R8 stripped
# SharedPreferencesApiRegistrar.getAll in the first release build (NoSuchMethodError
# at Supabase.initialize). Keep every plugin package and the Pigeon runtime.
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class com.llfbandit.app_links.** { *; }

# --- shared_preferences (and other jni/jnigen-based plugins) look up Kotlin methods from
# native code by their full JNI signature. Keeping the classes is not enough: R8 still
# renamed kotlin.coroutines.Continuation in getAll(String, List, Continuation), so the
# lookup failed. Shrink, but never rename.
-dontobfuscate
-keep class com.github.dart_lang.jni.** { *; }
