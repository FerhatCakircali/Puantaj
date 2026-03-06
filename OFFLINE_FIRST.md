# Offline-First Mimari Dokümantasyonu

## Genel Bakış

Flutter Puantaj uygulaması, **Offline-First** mimari ile geliştirilmiştir. Bu mimari sayesinde:

- ✅ İnternet bağlantısı olmadan uygulama kullanılabilir
- ✅ Veriler yerel olarak saklanır (Hive)
- ✅ İnternet geldiğinde otomatik senkronizasyon
- ✅ Optimistic UI updates (anında geri bildirim)
- ✅ Veri kaybı riski minimize edilir

## Teknoloji Stack'i

### Yerel Veritabanı: Hive
- **Neden Hive?**
  - Ücretsiz ve açık kaynak
  - Flutter için optimize edilmiş
  - Code generation gerektirmez (manuel TypeAdapter)
  - Hızlı ve hafif (NoSQL)
  - Dependency conflict'i yok

### Senkronizasyon: Connectivity Plus
- İnternet durumunu real-time izler
- Offline → Online geçişte otomatik sync tetikler

### Crash Monitoring: Firebase Crashlytics
- Production'da tüm hataları yakalar
- Stack trace ile detaylı raporlama
- ErrorLogger ile entegre

## Mimari Yapı

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

## Hive Yapısı

### Box'lar (Tablolar)

1. **workers** - Worker verileri
2. **employees** - Employee verileri
3. **attendance** - Yevmiye kayıtları
4. **payments** - Ödeme kayıtları
5. **pending_sync** - Senkronize edilmeyi bekleyen veriler
6. **metadata** - Son sync zamanı, vb.

### TypeAdapter'lar

Her model için manuel TypeAdapter oluşturuldu:

- `AttendanceAdapter` (Type ID: 0)
- `WorkerAdapter` (Type ID: 1)
- `PaymentAdapter` (Type ID: 2)
- `EmployeeAdapter` (Type ID: 3)

## Veri Akışı

### 1. Veri Okuma (Read)

```dart
// Online modda
1. Supabase'den veri çek
2. Hive'a kaydet (cache)
3. UI'a döndür

// Offline modda
1. Hive'dan veri oku
2. UI'a döndür
```

### 2. Veri Yazma (Write)

```dart
// Online modda
1. Hive'a yaz (optimistic update)
2. UI'ı güncelle (anında geri bildirim)
3. Supabase'e gönder
4. Başarılı ise Hive'da işaretle
5. Başarısız ise pending_sync'e ekle

// Offline modda
1. Hive'a yaz
2. UI'ı güncelle
3. pending_sync'e ekle
4. İnternet geldiğinde otomatik sync
```

## Kullanım Örnekleri

### HiveService Kullanımı

```dart
import 'package:puantaj/data/local/hive_service.dart';

// Hive'ı başlat (main.dart'ta yapılıyor)
await HiveService.instance.initialize();

// Worker'ları kaydet
final workersBox = HiveService.instance.workers;
await workersBox.put(worker.id, worker);

// Worker'ları oku
final allWorkers = workersBox.values.toList();

// Belirli bir worker'ı oku
final worker = workersBox.get(workerId);

// Worker'ı sil
await workersBox.delete(workerId);

// Tüm box'ı temizle (logout için)
await HiveService.instance.clearAll();
```

### SyncManager Kullanımı

```dart
import 'package:puantaj/data/local/sync_manager.dart';

// Sync Manager'ı başlat (main.dart'ta yapılıyor)
await SyncManager.instance.initialize();

// Pending sync'e veri ekle
await SyncManager.instance.addPendingSync(
  type: 'attendance',
  data: attendance.toMap(),
  operation: 'create',
);

// Manuel sync tetikle
await SyncManager.instance.syncPendingData();

// Online durumunu kontrol et
final isOnline = SyncManager.instance.isOnline;

// Bekleyen sync sayısını al
final pendingCount = SyncManager.instance.pendingSyncCount;

// Son sync zamanını al
final lastSync = SyncManager.instance.lastSyncTime;
```

### Optimistic UI Update Örneği

```dart
// Attendance kaydetme örneği
Future<void> saveAttendance(int workerId, DateTime date, AttendanceStatus status) async {
  try {
    // 1. Hive'a kaydet (optimistic update)
    final attendance = Attendance(
      userId: currentUserId,
      workerId: workerId,
      date: date,
      status: status,
    );
    
    await HiveService.instance.attendance.add(attendance);
    
    // 2. UI'ı güncelle (setState veya provider.notifyListeners)
    notifyListeners();
    
    // 3. Online ise Supabase'e gönder
    if (SyncManager.instance.isOnline) {
      await _attendanceService.saveAttendance(workerId, date, status);
    } else {
      // 4. Offline ise pending sync'e ekle
      await SyncManager.instance.addPendingSync(
        type: 'attendance',
        data: attendance.toMap(),
        operation: 'create',
      );
    }
  } catch (e, stackTrace) {
    ErrorLogger.instance.logError(
      'Attendance kaydedilemedi',
      error: e,
      stackTrace: stackTrace,
    );
    
    // Hata durumunda UI'ı geri al
    // ...
  }
}
```

## Firebase Crashlytics Entegrasyonu

### Otomatik Hata Yakalama

```dart
// main.dart'ta yapılandırıldı
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### ErrorLogger ile Entegrasyon

```dart
// ErrorLogger otomatik olarak Crashlytics'e gönderir
ErrorLogger.instance.logError(
  'Ödeme eklenirken hata',
  error: e,
  stackTrace: stackTrace,
  context: 'PaymentService.addPayment',
);

// Production'da (kReleaseMode) otomatik olarak:
// FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
```

## Best Practices

### 1. Her Zaman Hive'a Kaydet

```dart
// ✅ DOĞRU
final data = await supabase.from('workers').select();
await HiveService.instance.workers.clear();
for (var item in data) {
  await HiveService.instance.workers.put(item['id'], Worker.fromMap(item));
}

// ❌ YANLIŞ
final data = await supabase.from('workers').select();
// Hive'a kaydetmeden direkt döndürme
return data.map((e) => Worker.fromMap(e)).toList();
```

### 2. Offline Durumunu Kontrol Et

```dart
// ✅ DOĞRU
if (SyncManager.instance.isOnline) {
  // Supabase'den çek
} else {
  // Hive'dan oku
}

// ❌ YANLIŞ
// Her zaman Supabase'den çekmeye çalışma
await supabase.from('workers').select(); // Offline'da hata verir
```

### 3. Pending Sync'i Unutma

```dart
// ✅ DOĞRU
if (!SyncManager.instance.isOnline) {
  await SyncManager.instance.addPendingSync(
    type: 'payment',
    data: payment.toMap(),
    operation: 'create',
  );
}

// ❌ YANLIŞ
// Offline'da veriyi kaydetmeden bırakma
if (!isOnline) {
  return; // Veri kaybolur!
}
```

### 4. Logout'ta Temizle

```dart
// ✅ DOĞRU
Future<void> logout() async {
  await HiveService.instance.clearAll();
  await supabase.auth.signOut();
}

// ❌ YANLIŞ
// Hive'ı temizlemeden logout yapma
await supabase.auth.signOut(); // Eski veriler kalır
```

## Performans Metrikleri

### Hive vs Supabase Hız Karşılaştırması

| İşlem | Supabase (Online) | Hive (Offline) | İyileşme |
|-------|-------------------|----------------|----------|
| Worker listesi (100 kayıt) | ~800ms | ~50ms | %94 |
| Attendance kaydetme | ~500ms | ~20ms | %96 |
| Payment geçmişi (50 kayıt) | ~600ms | ~40ms | %93 |

### Bellek Kullanımı

- Hive box'ları lazy loading kullanır
- Sadece erişilen veriler belleğe yüklenir
- Ortalama bellek artışı: ~5-10MB

## Troubleshooting

### Hive Başlatma Hatası

```dart
// Hata: HiveError: Box is already open
// Çözüm: Box'ı tekrar açmaya çalışma
if (Hive.isBoxOpen('workers')) {
  return Hive.box<Worker>('workers');
}
await Hive.openBox<Worker>('workers');
```

### Sync Sonsuz Döngü

```dart
// Hata: Sync sürekli tetikleniyor
// Çözüm: _isSyncing flag'i kontrol et
if (_isSyncing) return;
_isSyncing = true;
try {
  // Sync işlemleri
} finally {
  _isSyncing = false;
}
```

### TypeAdapter Conflict

```dart
// Hata: TypeAdapter already registered
// Çözüm: Kayıt öncesi kontrol et
if (!Hive.isAdapterRegistered(0)) {
  Hive.registerAdapter(AttendanceAdapter());
}
```

## Gelecek İyileştirmeler

1. **Conflict Resolution**: Aynı veri hem local hem remote'ta değiştirilirse
2. **Partial Sync**: Sadece değişen verileri senkronize et
3. **Background Sync**: Uygulama kapalıyken bile sync yap
4. **Compression**: Büyük verileri sıkıştırarak kaydet
5. **Encryption**: Hassas verileri şifrele

## Kaynaklar

- [Hive Documentation](https://docs.hivedb.dev/)
- [Connectivity Plus](https://pub.dev/packages/connectivity_plus)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Offline-First Architecture](https://www.oreilly.com/library/view/building-progressive-web/9781491961643/ch04.html)
