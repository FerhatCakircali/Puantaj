# 📱 Puantaj Yönetim Sistemi

Modern, güvenli ve kullanıcı dostu bir puantaj (devam) takip sistemi. Flutter ile geliştirilmiş, Supabase backend ve Firebase Cloud Messaging ile bildirim desteği sunar.

## ✨ Özellikler

- 👥 Kullanıcı ve çalışan yönetimi
- 📅 Günlük devam takibi (tam gün, yarım gün, gelmedi)
- 💰 Ödeme takibi ve hesaplama
- 🔔 Gerçek zamanlı push bildirimleri (FCM)
- 📊 Detaylı raporlama
- 🔐 Güvenli kimlik doğrulama
- 🌍 Türkiye saati (UTC+3) desteği
- 📱 Android desteği

## 🚀 Hızlı Başlangıç

Detaylı kurulum talimatları için [SETUP.md](SETUP.md) dosyasına bakın.

### Gereksinimler

- Flutter SDK 3.32.0+
- Android Studio / VS Code
- Supabase hesabı
- Firebase hesabı

### Kurulum

```bash
# Projeyi klonlayın
git clone https://github.com/FerhatCakircali/Puantaj.git
cd Puantaj

# Bağımlılıkları yükleyin
flutter pub get

# Yapılandırma dosyalarını oluşturun
cp lib/config/secrets.dart.example lib/config/secrets.dart
cp android/app/google-services.json.example android/app/google-services.json

# Secrets dosyasını düzenleyin ve bilgilerinizi girin
# Detaylar için SETUP.md'ye bakın

# Uygulamayı çalıştırın
flutter run
```

## 📚 Dokümantasyon

- [SETUP.md](SETUP.md) - Detaylı kurulum rehberi
- [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Deployment kontrol listesi
- [FCM_MIGRATION_SUMMARY.md](FCM_MIGRATION_SUMMARY.md) - FCM migration özeti
- [BILDIRIM_SISTEMI_README.md](BILDIRIM_SISTEMI_README.md) - Bildirim sistemi dokümantasyonu

## 🏗️ Teknoloji Stack

- **Frontend:** Flutter 3.32.0
- **Backend:** Supabase (PostgreSQL)
- **Bildirimler:** Firebase Cloud Messaging (FCM)
- **State Management:** Provider
- **Local Storage:** SharedPreferences
- **Timezone:** Europe/Istanbul (UTC+3)

## 📁 Proje Yapısı

```
lib/
├── config/              # Yapılandırma dosyaları
├── data/                # Data layer (services, models)
├── presentation/        # UI layer (screens, widgets)
├── services/            # Business logic services
└── main.dart            # Uygulama giriş noktası

android/                 # Android platform kodu
SonAsamaSQL/            # SQL migration dosyaları
```

## 🔐 Güvenlik

Bu proje hassas bilgileri (API keys, tokens) güvenli bir şekilde yönetir:

- Tüm hassas bilgiler `.gitignore`'da
- Environment variables kullanımı
- Placeholder dosyalar ile örnek yapılandırma
- Service Role Key sadece backend'de

Detaylar için [SETUP.md](SETUP.md) dosyasına bakın.

## 🧪 Test

```bash
# Tüm testleri çalıştır
flutter test

# Analiz
flutter analyze
```

## 📱 Platform Desteği

- ✅ Android
- ⏳ iOS (yakında)
- ⏳ Web (yakında)

## 🤝 Katkıda Bulunma

Bu proje özel bir projedir. Katkıda bulunmak için lütfen iletişime geçin.

## 📄 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.

## 📞 İletişim

Sorularınız için lütfen issue açın veya iletişime geçin.

---

**Not:** Projeyi çalıştırmadan önce mutlaka [SETUP.md](SETUP.md) dosyasını okuyun!
