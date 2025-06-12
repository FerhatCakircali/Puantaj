package com.example.puantaj

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec
import android.content.SharedPreferences
import android.content.Context

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.puantaj/background_service"
    private val NOTIFICATION_CHANNEL = "com.example.puantaj/notification"
    private var notificationMessageChannel: BasicMessageChannel<String>? = null
    private val SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Metod kanalı oluştur
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startBackgroundService") {
                // Arka plan servisi başlatma mantığı buraya eklenebilir
                result.success("Arka plan servisi başlatıldı")
            } else if (call.method == "openAttendancePage") {
                // Bu metot Flutter tarafından çağrılabilir ve yevmiye sayfasını açmak için kullanılabilir
                Log.d("MainActivity", "openAttendancePage metodu çağrıldı")
                notificationMessageChannel?.send("attendance_reminder")
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        
        // Bildirim mesaj kanalını oluştur
        notificationMessageChannel = BasicMessageChannel(flutterEngine.dartExecutor.binaryMessenger, 
                                                       NOTIFICATION_CHANNEL, 
                                                       StringCodec.INSTANCE)
        
        // Eğer bildirimden başlatıldıysa, Flutter tarafına bildir
        checkNotificationLaunch(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Uygulama başlatıldığında bildirim bayrağını kontrol et
        checkNotificationFlag()
        
        // Bildirim izinlerini kontrol et (Android 13+ için)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13 ve üzeri için bildirim izinleri burada istenebilir
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Yeni intent geldiğinde bildirim kontrolü yap
        checkNotificationLaunch(intent)
    }
    
    private fun checkNotificationLaunch(intent: Intent) {
        try {
            // Intent'ten bildirim verilerini al
            val launchedFromNotification = intent.getBooleanExtra("launched_from_notification", false)
            val notificationPayload = intent.getStringExtra("notification_payload")
            
            if (launchedFromNotification && notificationPayload != null) {
                Log.d("MainActivity", "Bildirimden başlatıldı: $notificationPayload")
                
                // Flutter tarafına bildirim bilgisini gönder
                notificationMessageChannel?.send("attendance_reminder")
            } else {
                // Intent aksiyon kontrol et
                if (intent.action == "FLUTTER_NOTIFICATION_CLICK" || 
                    intent.action == "OPEN_ATTENDANCE_PAGE") {
                    Log.d("MainActivity", "Bildirim aksiyon alındı: ${intent.action}")
                    notificationMessageChannel?.send("attendance_reminder")
                    
                    // Bildirim bayrağını ayarla
                    setNotificationFlag(true)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Bildirim kontrolünde hata: ${e.message}")
        }
    }
    
    private fun checkNotificationFlag() {
        try {
            val sharedPreferences = getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
            val notificationNeeded = sharedPreferences.getBoolean("flutter.notification_needs_handling", false)
            
            if (notificationNeeded) {
                Log.d("MainActivity", "Bildirim işleme bayrağı bulundu, yevmiye sayfasına yönlendiriliyor...")
                
                // Flutter tarafına bildirim bilgisini gönder (2 saniye gecikme ile)
                android.os.Handler().postDelayed({
                    notificationMessageChannel?.send("attendance_reminder")
                    // Bayrağı temizle
                    setNotificationFlag(false)
                }, 2000)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Bildirim bayrağı kontrolünde hata: ${e.message}")
        }
    }
    
    private fun setNotificationFlag(value: Boolean) {
        try {
            val sharedPreferences = getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
            val editor = sharedPreferences.edit()
            editor.putBoolean("flutter.notification_needs_handling", value)
            editor.apply()
        } catch (e: Exception) {
            Log.e("MainActivity", "Bildirim bayrağı ayarlanırken hata: ${e.message}")
        }
    }
}
