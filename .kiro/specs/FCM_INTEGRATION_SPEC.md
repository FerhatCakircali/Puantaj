# FCM (Firebase Cloud Messaging) Entegrasyon Spesifikasyonu

## 1. Proje Hedefi
Mevcut Realtime bildirim sistemine **FCM desteği ekleyerek**, uygulama kapalıyken bile push notification alınmasını sağlamak.

## 2. Mimari Kararlar

### 2.1 Hibrit Bildirim Sistemi
```
┌─────────────────────────────────────────────────────────┐
│              BİLDİRİM MİMARİSİ                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  REALTIME (Uygulama Açıkken - Mevcut Sistem)          │
│  ├─ Yevmiye Talepleri (attendance_request)            │
│  ├─ Çalışan Hatırlatıcıları (attendance_reminder)     │
│  └─ Anlık bildirimler (düşük latency)                 │
│                                                         │
│  FCM (Uygulama Kapalıyken - YENİ)                     │
│  ├─ Tüm bildirim tipleri                              │
│  ├─ Background/Terminated state desteği               │
│  └─ Supabase Edge Function ile tetiklenir             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Neden Hibrit Sistem?
- **Realtime장점:** Düşük latency, anlık bildirim (uygulama açıkken)
- **FCM장점:** Background/terminated state desteği
- **Sonuç:** İki sistemin güçlü yönlerini birleştiriyoruz

## 3. Teknik Tasarım

### 3.1 Database Schema

#### Yeni Tablo: `fcm_tokens`
```sql
CREATE TABLE fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL, -- 'android' veya 'ios'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraint: user_id veya worker_id'den biri olmalı
  CONSTRAINT check_user_or_worker CHECK (
    (user_id IS NOT NULL AND worker_id IS NULL) OR
    (user_id IS NULL AND worker_id IS NOT NULL)
  )
);

-- Index'ler
CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_worker_id ON fcm_tokens(worker_id);
CREATE INDEX idx_fcm_tokens_token ON fcm_tokens(token);
```

### 3.2 Supabase Edge Function

#### Function: `send-push-notification`
```typescript
// Deno Edge Function
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { recipientId, title, message, notificationType, relatedId } = await req.json()
    
    // 1. FCM token'ı al
    const { data: tokens } = await supabase
      .from('fcm_tokens')
      .select('token')
      .or(`user_id.eq.${recipientId},worker_id.eq.${recipientId}`)
    
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: 'No FCM token found' }), { status: 404 })
    }
    
    // 2. Firebase Admin SDK ile push notification gönder
    const fcmResponse = await fetch('https://fcm.googleapis.com/v1/projects/puantaj-f769d/messages:send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: tokens[0].token,
          notification: { title, body: message },
          data: { type: notificationType, relatedId: String(relatedId) },
        },
      }),
    })
    
    return new Response(JSON.stringify({ success: true }), { status: 200 })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
```

### 3.3 Database Trigger

#### Trigger: `on_notification_insert`
```sql
CREATE OR REPLACE FUNCTION notify_via_fcm()
RETURNS TRIGGER AS $$
BEGIN
  -- Edge Function'ı çağır (HTTP POST)
  PERFORM net.http_post(
    url := 'https://[PROJECT_REF].supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object(
      'recipientId', NEW.recipient_id,
      'title', NEW.title,
      'message', NEW.message,
      'notificationType', NEW.notification_type,
      'relatedId', NEW.related_id
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı notifications tablosuna bağla
CREATE TRIGGER on_notification_insert_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_via_fcm();
```

### 3.4 Flutter Service Layer

#### FCMService Sorumlulukları:
1. ✅ FCM token alma ve kaydetme
2. ✅ Foreground notification handling
3. ✅ Background notification handling
4. ✅ Notification tap handling
5. ✅ Token refresh handling

#### Entegrasyon Noktaları:
- `main.dart`: Firebase initialization
- `auth_service.dart`: Login/logout'ta token kaydetme/silme
- `worker_home_screen.dart`: Çalışan login'de token kaydetme

## 4. İmplementasyon Adımları

### Adım 1: Database Setup ✅ TAMAMLANDI
- [x] `fcm_tokens` tablosu oluştur
- [x] Index'leri ekle
- [x] RLS (Row Level Security) politikaları
- [x] Yardımcı fonksiyonlar (cleanup)

### Adım 2: Flutter FCM Service ✅ TAMAMLANDI
- [x] Token kaydetme (User/Worker)
- [x] Token silme
- [x] Token deaktif etme
- [x] Token refresh handling

### Adım 3: Auth Integration ✅ TAMAMLANDI
- [x] User login'de token kaydetme
- [x] User logout'ta token silme
- [x] Worker login'de token kaydetme
- [x] Worker logout'ta token silme

### Adım 4: Edge Function ✅ TAMAMLANDI
- [x] `send-push-notification` function oluştur
- [x] Firebase FCM Legacy API entegrasyonu
- [x] Error handling ve logging
- [x] Token validation ve cleanup

### Adım 5: Database Trigger ✅ TAMAMLANDI
- [x] `notify_via_fcm()` function oluştur
- [x] Trigger'ı notifications tablosuna bağla
- [x] pg_net extension kontrolü
- [x] Asenkron çağrı (non-blocking)

### Adım 6: Kurulum Dokümantasyonu ✅ TAMAMLANDI
- [x] FCM_SETUP_GUIDE.md oluşturuldu
- [x] Adım adım kurulum talimatları
- [x] Test senaryoları
- [x] Sorun giderme rehberi

### Adım 7: Testing 🔄 BEKLEMEDE
- [ ] Uygulama açıkken bildirim testi
- [ ] Uygulama kapalıyken bildirim testi
- [ ] Token refresh testi
- [ ] Multi-device testi

## 5. Güvenlik Önlemleri

### 5.1 RLS Politikaları
```sql
-- Kullanıcılar sadece kendi token'larını görebilir
CREATE POLICY "Users can view own tokens"
ON fcm_tokens FOR SELECT
USING (
  (auth.uid() IS NOT NULL AND user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
  OR
  (worker_id IS NOT NULL) -- Çalışanlar için ayrı kontrol
);

-- Kullanıcılar sadece kendi token'larını ekleyebilir
CREATE POLICY "Users can insert own tokens"
ON fcm_tokens FOR INSERT
WITH CHECK (
  (auth.uid() IS NOT NULL AND user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
  OR
  (worker_id IS NOT NULL) -- Çalışanlar için ayrı kontrol
);
```

### 5.2 Edge Function Security
- Service role key kullanımı
- Rate limiting
- Input validation

## 6. Performans Optimizasyonları

### 6.1 Token Yönetimi
- Token cache (SharedPreferences)
- Token refresh sadece gerektiğinde
- Duplicate token kontrolü

### 6.2 Notification Batching
- Çoklu bildirim durumunda batch gönderim
- Rate limiting (spam önleme)

## 7. Monitoring & Logging

### 7.1 Metrics
- FCM token kayıt başarı oranı
- Push notification delivery rate
- Notification tap rate
- Error rate

### 7.2 Logging
- Token kayıt/silme işlemleri
- Push notification gönderim durumu
- Error logs (Edge Function)

## 8. Rollback Planı

### Sorun Durumunda:
1. Database trigger'ı devre dışı bırak
2. Edge Function'ı durdur
3. Realtime sistemi aktif tut (mevcut sistem)
4. FCM token kayıtlarını sil (opsiyonel)

## 9. Başarı Kriterleri

- ✅ Uygulama kapalıyken push notification alınıyor
- ✅ Notification tap'te doğru sayfaya yönlendirme
- ✅ Token refresh otomatik çalışıyor
- ✅ Multi-device desteği
- ✅ Error rate < %1
- ✅ Delivery rate > %95

## 10. Zaman Tahmini

- Database Setup: 30 dakika
- Edge Function: 1 saat
- Flutter Integration: 1 saat
- Testing: 1 saat
- **Toplam: ~3.5 saat**

---

**Hazırlayan:** Kiro AI  
**Tarih:** 2026-02-21  
**Versiyon:** 1.0  
**Durum:** İmplementasyon Aşamasında
