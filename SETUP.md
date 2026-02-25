# 🚀 Puantaj Yönetim Sistemi - Kurulum Rehberi

Bu rehber, projeyi GitHub'dan klonladıktan sonra çalıştırmak için gerekli adımları içerir.

## 📋 Gereksinimler

- Flutter SDK (3.32.0 veya üzeri)
- Android Studio / VS Code
- Supabase hesabı
- Firebase hesabı
- Git

## 🔧 Kurulum Adımları

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/YOUR_USERNAME/puantaj.git
cd puantaj
```

### 2. Flutter Bağımlılıklarını Yükleyin

```bash
flutter pub get
```

### 3. Supabase Yapılandırması

#### 3.1 Supabase Projesi Oluşturun

1. [Supabase Dashboard](https://app.supabase.com)'a giriş yapın
2. "New Project" butonuna tıklayın
3. Proje adı, veritabanı şifresi ve bölge seçin
4. Projenin oluşmasını bekleyin (2-3 dakika)

#### 3.2 API Bilgilerini Alın

1. Supabase Dashboard'da projenizi açın
2. Sol menüden "Project Settings" > "API" seçin
3. Şu bilgileri not edin:
   - **Project URL** (örn: `https://xxxxx.supabase.co`)
   - **Anon Key** (public key)
   - **Service Role Key** (secret key - dikkatli kullanın!)

#### 3.3 Secrets Dosyasını Oluşturun

```bash
# secrets.dart.example dosyasını kopyalayın
cp lib/config/secrets.dart.example lib/config/secrets.dart
```

`lib/config/secrets.dart` dosyasını açın ve bilgilerinizi girin:

```dart
class Secrets {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  static const String resendApiKey = 'YOUR_RESEND_API_KEY_HERE';
}
```

⚠️ **ÖNEMLİ:** `secrets.dart` dosyası `.gitignore`'da olduğu için GitHub'a yüklenmeyecektir.

### 4. Firebase Yapılandırması

#### 4.1 Firebase Projesi Oluşturun

1. [Firebase Console](https://console.firebase.google.com)'a giriş yapın
2. "Add project" butonuna tıklayın
3. Proje adı girin ve adımları takip edin

#### 4.2 Android Uygulaması Ekleyin

1. Firebase Console'da projenizi açın
2. "Add app" > "Android" seçin
3. Package name: `com.example.puantaj`
4. App nickname: `Puantaj` (isteğe bağlı)
5. "Register app" butonuna tıklayın

#### 4.3 google-services.json İndirin

1. "Download google-services.json" butonuna tıklayın
2. İndirdiğiniz dosyayı `android/app/` klasörüne kopyalayın

```bash
# Dosya konumu şöyle olmalı:
# android/app/google-services.json
```

#### 4.4 Firebase Cloud Messaging (FCM) Aktifleştirin

1. Firebase Console'da "Build" > "Cloud Messaging" seçin
2. "Get started" butonuna tıklayın
3. FCM API'yi aktifleştirin

### 5. SQL Veritabanı Kurulumu

#### 5.1 SQL Dosyasını Hazırlayın

```bash
# PuantajAllQuery.sql.local dosyasını oluşturun
cp SonAsamaSQL/PuantajAllQuery.sql SonAsamaSQL/PuantajAllQuery.sql.local
```

#### 5.2 Placeholder'ları Değiştirin

`SonAsamaSQL/PuantajAllQuery.sql.local` dosyasını açın ve şu satırları bulun:

```sql
url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY_HERE'
```

Değiştirin:

```sql
url := 'https://uvdcefauzxordqgvvweq.supabase.co/functions/v1/send-push-notification',
'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

⚠️ **ÖNEMLİ:** Service Role Key'i kullanın (Anon Key değil!)

#### 5.3 SQL'i Supabase'e Yükleyin

1. Supabase Dashboard'da "SQL Editor" seçin
2. "New query" butonuna tıklayın
3. `SonAsamaSQL/PuantajAllQuery.sql.local` dosyasının içeriğini kopyalayın
4. SQL Editor'e yapıştırın
5. "Run" butonuna tıklayın

### 6. Email Servisi (Opsiyonel)

Eğer email bildirimleri kullanacaksanız:

1. [Resend](https://resend.com) hesabı oluşturun
2. API Key alın
3. `lib/config/secrets.dart` dosyasına ekleyin

## 🏃 Uygulamayı Çalıştırın

### Android Emulator

```bash
flutter run
```

### Fiziksel Cihaz

```bash
# USB debugging aktif olmalı
flutter run
```

## ✅ Kurulum Kontrolü

Uygulama başladığında console'da şu logları görmelisiniz:

```
🔧 ServiceInitializer: Servis başlatma işlemi başlıyor
🔧 ServiceInitializer: Timezone başlatılıyor
✅ ServiceInitializer: Timezone ayarlandı (Europe/Istanbul)
🔧 ServiceInitializer: LocalStorage başlatılıyor
✅ ServiceInitializer: LocalStorage başlatıldı
🔧 ServiceInitializer: Supabase başlatılıyor
✅ ServiceInitializer: Supabase başlatıldı
🔧 ServiceInitializer: Bildirim servisi başlatılıyor
✅ ServiceInitializer: Bildirim servisi başlatıldı
🔧 ServiceInitializer: FCM servisi başlatılıyor
✅ ServiceInitializer: FCM servisi başlatıldı
✅ ServiceInitializer: Tüm servisler başarıyla başlatıldı
```

## 🐛 Sorun Giderme

### Supabase Bağlantı Hatası

```
❌ Supabase connection failed
```

**Çözüm:**
- `lib/config/secrets.dart` dosyasındaki URL ve Anon Key'i kontrol edin
- İnternet bağlantınızı kontrol edin
- Supabase projesinin aktif olduğundan emin olun

### Firebase Hatası

```
❌ google-services.json not found
```

**Çözüm:**
- `android/app/google-services.json` dosyasının var olduğundan emin olun
- Dosya adının tam olarak `google-services.json` olduğunu kontrol edin

### FCM Token Alınamıyor

```
⚠️ FCM token alınamadı
```

**Çözüm:**
- Firebase Console'da FCM API'nin aktif olduğunu kontrol edin
- `google-services.json` dosyasının doğru olduğundan emin olun
- Uygulamayı yeniden başlatın

### SQL Hatası

```
❌ Function notify_via_fcm does not exist
```

**Çözüm:**
- SQL dosyasının Supabase'e yüklendiğinden emin olun
- SQL Editor'de hata olup olmadığını kontrol edin
- Service Role Key'in doğru olduğundan emin olun

## 📁 Dosya Yapısı

```
Puantaj/
├── .env.example                      # Environment variables şablonu
├── .gitignore                        # Git ignore kuralları
├── SETUP.md                          # Bu dosya
├── lib/
│   ├── config/
│   │   ├── env_config.dart           # Environment yapılandırması
│   │   ├── secrets.dart.example      # Secrets şablonu
│   │   ├── secrets.dart              # Gerçek secrets (gitignore'da)
│   │   └── service_initializer.dart  # Servis başlatıcı
├── android/app/
│   ├── google-services.json          # Firebase config (gitignore'da)
│   └── google-services.json.example  # Firebase config şablonu
└── SonAsamaSQL/
    ├── PuantajAllQuery.sql           # SQL şablonu (placeholder)
    └── PuantajAllQuery.sql.local     # Gerçek SQL (gitignore'da)
```

## 🔐 Güvenlik Notları

1. **Asla commit etmeyin:**
   - `lib/config/secrets.dart`
   - `android/app/google-services.json`
   - `SonAsamaSQL/PuantajAllQuery.sql.local`
   - `.env`

2. **Service Role Key:**
   - Sadece backend/SQL'de kullanın
   - Flutter kodunda kullanmayın
   - GitHub'a asla yüklemeyin

3. **Anon Key:**
   - Flutter kodunda kullanılabilir
   - Public key'dir
   - RLS politikaları ile korunur

## 📞 Destek

Sorun yaşarsanız:

1. Bu dokümantasyonu tekrar okuyun
2. Console loglarını kontrol edin
3. `.gitignore` dosyasını kontrol edin
4. `git status` ile hangi dosyaların commit edileceğini kontrol edin

## 📝 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.
