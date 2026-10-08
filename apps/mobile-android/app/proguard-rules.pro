# Add project specific ProGuard rules here.
-keepattributes *Annotation*
-dontwarn javax.annotation.**
-keepclassmembers class * {
    @androidx.room.* <methods>;
}
