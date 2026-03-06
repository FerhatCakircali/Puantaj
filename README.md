# 📱 Puantaj - Flutter Çalışan Yönetim Uygulaması

Modern, performanslı ve **offline-first** çalışan yönetim sistemi. Puantaj takibi, ödeme yönetimi, avans/masraf takibi ve raporlama özellikleri sunar.

## 🚀 Özellikler

### 👥 Çalışan Yönetimi
- Çalışan ekleme, düzenleme, silme
- Profil fotoğrafı yönetimi (cached image loading)
- Güvenilir çalışan sistemi
- Kullanıcı adı ve e-posta doğrulama
- **Offline çalışma desteği**

### 📅 Puantaj Takibi
- Günlük puantaj girişi (tam gün / yarım gün)
- Takvim görünümü ile kolay navigasyon
- Ödenen günler takibi
- Otomatik hesaplama (ödenmemiş günler)
- **Offline puantaj girişi**

### 💰 Ödeme Yönetimi
- Çalışan ödemeleri kayıt ve takip
- Avans yönetimi (verilmiş/düşülmüş)
- Masraf yönetimi (kategorize edilmiş)
- Ödeme geçmişi ve detayları
- **Offline ödeme kaydı**

### 📊 Raporlama
- Finansal özet raporları (PDF)
- Çalışan bazlı detaylı raporlar (PDF)
- Dönemsel raporlar (günlük, haftalık, aylık, yıllık)
- Özelleştirilebilir tarih aralığı

### 🔔 Bildirimler
- Yevmiye hatırlatıcıları
- Özelleştirilebilir bildirim zamanları
- Çalışan bazlı bildirim ayarları
- FCM push notifications

### 🎨 Kullanıcı Deneyimi
- Material 3 Design System
- Dark/Light tema desteği
- Responsive tasarım (telefon/tablet)
- Smooth animasyonlar
- **Offline-first yaklaşım** ✅

### 🔥 Yeni: Offline-First & Crash Monitoring
- **Hive** yerel veritabanı ile tam offline destek
- Otomatik senkronizasyon (online olduğunda)
- **Firebase Crashlytics** ile production hata izleme
- Optimistic UI updates (anında geri bildirim)
- Rollback mekanizması (hata durumunda)

---

## 🏗️ Mimari

### Offline-First Mimari

Uygulama **Offline-First** prensibiyle tasarlanmıştır. Tüm veriler önce yerel olarak (Hive) saklanır, ardından arka planda Supabase ile senkronize edilir.

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                            │
│  (Riverpod Providers + ConsumerWidgets)                 │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│                  Service Layer                           │
│  (WorkerService, AttendanceService, PaymentService)     │
└────────┬────────────────────────────────────────────────┘
         │
         ├──────────────┬──────────────┐
         ▼              ▼              ▼
┌────────────┐  ┌──────────────┐  ┌──────────────┐
│  Supabase  │  │ Hive Service │  │ Sync Manager │
│  (Remote)  │  │   (Local)    │  │  (Offline)   │
└────────────┘  └──────────────┘  └──────────────┘
```

### Hive Yerel Veritabanı

**Box Yapısı:**
- `workers` - Worker verileri
- `employees` - Employee verileri
- `attendance` - Yevmiye kayıtları
- `payments` - Ödeme kayıtları
- `pending_sync` - Senkronize edilmeyi bekleyen veriler
- `metadata` - Son sync zamanı, vb.

**TypeAdapter'lar:**
```dart
// Type ID: 0
class AttendanceAdapter extends TypeAdapter<Attendance> { ... }

// Type ID: 1
class WorkerAdapter extends TypeAdapter<Worker> { ... }

// Type ID: 2
class PaymentAdapter extends TypeAdapter<Payment> { ... }

// Type ID: 3
class EmployeeAdapter extends TypeAdapter<Employee> { ... }
```

### SyncManager - Otomatik Senkronizasyon

```dart
// Pending sync'e veri ekle
await SyncManager.instance.addPendingSync(
  type: 'attendance',
  data: attendance.toMap(),
  operation: 'create',
);

// Manuel sync tetikle
await SyncManager.instance.syncPendingData();

// Online durumu kontrol et
final isOnline = SyncManager.instance.isOnline;

// Bekleyen sync sayısı
final pendingCount = SyncManager.instance.pendingSyncCount;
```

### Firebase Crashlytics

Production'da tüm hatalar otomatik olarak Firebase Crashlytics'e gönderilir:

```dart
// ErrorLogger otomatik entegrasyon
ErrorLogger.instance.logError(
  'Ödeme eklenirken hata',
  error: e,
  stackTrace: stackTrace,
  context: 'PaymentService.addPayment',
);
// Production'da (kReleaseMode) otomatik Crashlytics'e gönderilir
```

### State Management
**Riverpod** - Modern, tip-güvenli state management

```dart
// Auth State
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(() {
  return AuthStateNotifier();
});

// Theme State
final themeStateProvider = NotifierProvider<ThemeStateNotifier, ThemeMode>(() {
  return ThemeStateNotifier();
});

// User Data State
final userDataProvider = NotifierProvider<UserDataNotifier, Map<String, dynamic>?>(() {
  return UserDataNotifier();
});
```

### Utility Modülleri

**DateFormatter** - Türkiye saat dilimi (UTC+3) desteği
```dart
// ISO 8601 format (YYYY-MM-DD)
final formatted = DateFormatter.toIso8601Date(DateTime.now());

// Display format (DD.MM.YYYY)
final display = DateFormatter.toDisplayDate(DateTime.now());
```

**CurrencyFormatter** - Türk lirası formatı
```dart
// Binlik ayırıcı ile format
final formatted = CurrencyFormatter.format(123456.78); // "123.456,78 ₺"
```

**ErrorLogger** - Merkezi hata yönetimi + Crashlytics
```dart
ErrorLogger.instance.logError('Context', error, stackTrace);
ErrorLogger.instance.logWarning('Context', 'Warning message');
ErrorLogger.instance.logInfo('Context', 'Info message');
```

### Performans Optimizasyonları

**Hive vs Supabase Hız Karşılaştırması:**

| İşlem | Supabase (Online) | Hive (Offline) | İyileşme |
|-------|-------------------|----------------|----------|
| Worker listesi (100 kayıt) | ~800ms | ~50ms | %94 ⚡ |
| Attendance kaydetme | ~500ms | ~20ms | %96 ⚡ |
| Payment geçmişi (50 kayıt) | ~600ms | ~40ms | %93 ⚡ |

**CachedFutureBuilder** - Generic cache widget
```dart
CachedFutureBuilder<List<Worker>>(
  cacheKey: 'workers_list',
  cacheDuration: Duration(minutes: 5),
  future: () => workerService.getWorkers(),
  builder: (context, data) => WorkerList(workers: data),
)
```

**N+1 Query Çözümü** - Supabase RPC fonksiyonları
- `get_workers_with_unpaid_days()` - 15+ query → 1 query (%93 azalma)
- `get_payment_summary()` - 10+ query → 1 query (%90 azalma)

**Image Caching** - cached_network_image
```dart
CachedProfileAvatar(
  imageUrl: worker.profileImageUrl,
  name: worker.name,
  radius: 40,
)
```

---

## 🛠️ Teknoloji Stack

### Framework & Language
- **Flutter** 3.32.0+
- **Dart** 3.8.0+

### State Management
- **flutter_riverpod** ^3.2.1 - Modern state management

### Backend & Database
- **supabase_flutter** ^2.9.0 - Backend as a Service
- **PostgreSQL** - Supabase database

### UI & Design
- **Material 3** - Modern design system
- **google_fonts** ^6.2.1 - Custom fonts
- **responsive_framework** ^1.1.1 - Responsive design

### Navigation
- **go_router** ^17.0.0 - Declarative routing

### Local Storage
- **shared_preferences** ^2.5.3 - Key-value storage

### Notifications
- **firebase_messaging** ^16.1.1 - Push notifications
- **flutter_local_notifications** 19.2.1 - Local notifications

### PDF Generation
- **pdf** ^3.10.8 - PDF document creation
- **path_provider** ^2.1.5 - File system paths

### Image Caching
- **cached_network_image** ^3.3.1 - Network image caching
- **flutter_cache_manager** ^3.4.1 - Cache management

### Utilities
- **intl** ^0.20.2 - Internationalization
- **timezone** ^0.10.1 - Timezone support
- **uuid** ^4.5.2 - UUID generation
- **bcrypt** ^1.2.0 - Password hashing

---

## 📦 Kurulum

### Gereksinimler
- Flutter SDK 3.32.0 veya üzeri
- Dart SDK 3.8.0 veya üzeri
- Android Studio / VS Code
- Git

### Adımlar

1. **Repository'yi klonlayın**
```bash
git clone https://github.com/FerhatCakircali/Puantaj.git
cd Puantaj
```

2. **Dependencies'leri yükleyin**
```bash
flutter pub get
```

3. **Environment dosyasını oluşturun**
```bash
cp .env.example .env
```

`.env` dosyasını düzenleyin:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Secrets dosyasını oluşturun**
```bash
cp lib/config/secrets.dart.example lib/config/secrets.dart
```

`secrets.dart` dosyasını düzenleyin ve API anahtarlarınızı ekleyin.

5. **Uygulamayı çalıştırın**
```bash
flutter run
```

---

## 🗄️ Database Setup

### Supabase Migration'ları

1. **Supabase projenizi oluşturun**
   - https://supabase.com adresinden yeni proje oluşturun

2. **SQL migration'ları çalıştırın**
   - `SonAsamaSQL/PuantajAllQuery.sql` dosyasını Supabase SQL Editor'da çalıştırın
   - Veya `database_migrations/` klasöründeki dosyaları sırayla çalıştırın

3. **RPC Fonksiyonları**
   - `011_rpc_get_workers_with_unpaid_days.sql`
   - `012_rpc_get_payment_summary.sql`

---

## 🧪 Test

### Unit Tests
```bash
flutter test
```

### Test Coverage
```bash
flutter test --coverage
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## 🏗️ Build

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## 📊 Performans Metrikleri

| Metrik | Önce | Sonra | İyileşme |
|--------|------|-------|----------|
| Network Requests | 15+ query | 1-2 query | %93 azalma |
| Cache Hit Rate | %0 | %85+ | ∞ artış |
| Memory Usage | 180MB | ~140MB | %22 azalma |
| Code Duplication | Yüksek | Minimal | %80 azalma |
| flutter analyze | 150+ issues | 91 issues | %39 azalma |

Detaylı performans analizi için: [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md)

---

## 📚 Dokümantasyon

- **[OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md)** - Optimizasyon projesi özeti
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Mimari dokümantasyonu
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Geçiş rehberi
- **[PERFORMANCE.md](PERFORMANCE.md)** - Performans best practices
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

---

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

### Commit Mesaj Formatı
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: Yeni özellik
- `fix`: Bug fix
- `docs`: Dokümantasyon
- `style`: Formatting, missing semi colons, etc
- `refactor`: Code refactoring
- `test`: Test ekleme/düzenleme
- `chore`: Build process, dependencies

---

## 📝 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.

---

## 👨‍💻 Geliştirici

**Ferhat Çakırcalı**
- GitHub: [@FerhatCakircali](https://github.com/FerhatCakircali)

---

## 🙏 Teşekkürler

- Flutter Team - Harika framework
- Supabase Team - Backend infrastructure
- Riverpod Community - Modern state management
- Tüm açık kaynak katkıda bulunanlar

---

## 📞 İletişim

Sorularınız veya önerileriniz için:
- GitHub Issues: [Proje Issues](https://github.com/FerhatCakircali/Puantaj/issues)
- Email: [İletişim bilgisi]

---

**Son Güncelleme:** 6 Mart 2026  
**Versiyon:** 1.0.0  
**Durum:** 🟢 Production Ready
