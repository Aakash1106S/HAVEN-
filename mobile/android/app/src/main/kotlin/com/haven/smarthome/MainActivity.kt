package com.haven.smarthome

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.i("HAVEN_NATIVE", ">>> configureFlutterEngine: Explicitly registering plugins with GeneratedPluginRegistrant")
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
            Log.i("HAVEN_NATIVE", ">>> configureFlutterEngine: Successfully registered all plugins!")
        } catch (e: Exception) {
            Log.e("HAVEN_NATIVE", ">>> configureFlutterEngine: FAILED to register plugins", e)
        }
    }
}
