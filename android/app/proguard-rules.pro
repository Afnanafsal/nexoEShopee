# Razorpay
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Fluttertoast
-keep class io.github.ponnamkarthik.toast.fluttertoast.** { *; }

# Ignore missing Google Pay classes (used by Razorpay for GPay integration)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# Ignore missing proguard.annotation.Keep classes
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers