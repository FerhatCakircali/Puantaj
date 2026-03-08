# Error Handling Standardization

## Genel Bakış

PHASE 6 kapsamında tüm uygulama genelinde tutarlı error handling altyapısı oluşturuldu.

## Oluşturulan Yapılar

### 1. ErrorHandlerMixin (`error_handler_mixin.dart`)

Service katmanında kullanılan error handling mixin'i.

**Metodlar:**
- `handleError<T>()`: Hata durumunda fallback değer döndürür
- `handleErrorWithThrow<T>()`: Hata durumunda AppException fırlatır
- `handleErrorSync<T>()`: Sync işlemler için error wrapper

**Özellikler:**
- Otomatik ErrorLogger entegrasyonu
- Generic exception'ları AppException'a dönüştürme
- Network, timeout, authorization hatalarını otomatik algılama
- Kullanıcı dostu hata mesajları

**Kullanım:**
```dart
class MyService with ErrorHandlerMixin {
  Future<List<Data>> getData() async {
    return handleError(
      () async => await repository.getData(),
      [],
      context: 'MyService.getData',
    );
  }
}
```

### 2. BaseRepositoryMixin (`base_repository_mixin.dart`)

Repository katmanında kullanılan error handling mixin'i.

**Metodlar:**
- `executeQuery<T>()`: Hata durumunda fallback değer döndürür
- `executeQueryWithThrow<T>()`: Hata durumunda exception fırlatır

**Özellikler:**
- Otomatik ErrorLogger entegrasyonu
- Tutarlı error loglama
- Stack trace yakalama

**Kullanım:**
```dart
class MyRepository with BaseRepositoryMixin {
  Future<List<Data>> getData() async {
    return executeQuery(
      () async => await supabase.from('table').select(),
      [],
      context: 'MyRepository.getData',
    );
  }
}
```

## Güncellenen Servisler

### Service Katmanı
- ✅ AdvanceService
- ✅ ExpenseService
- ✅ AttendanceService
- ✅ ValidationService
- ✅ WorkerService
- ✅ PaymentService
- ✅ ReportService
- ✅ EmailService
- ✅ DatabaseCleanupService
- ✅ CacheManagerService

### Repository Katmanı
- ✅ AdvanceRepository
- ✅ ExpenseRepository
- ✅ WorkerRepository
- ✅ EmployeeRepository
- ✅ PaymentRepository
- ✅ PaidDaysRepository
- ✅ AttendanceRepository

## Error Handling Stratejisi

### Read İşlemleri (GET)
- Hata durumunda boş liste/null döndür
- ErrorLogger ile logla
- Kullanıcıya sessiz hata (silent failure)

### Write İşlemleri (POST/PUT/DELETE)
- Hata durumunda AppException fırlat
- ErrorLogger ile logla
- Kullanıcıya hata mesajı göster

## Hata Tipleri

Mevcut AppException tipleri:
- `AuthenticationException`: Kimlik doğrulama hataları
- `AuthorizationException`: Yetkilendirme hataları
- `ValidationException`: Validasyon hataları
- `NetworkException`: Network hataları
- `DatabaseException`: Veritabanı hataları
- `PermissionException`: İzin hataları
- `NotFoundException`: Kaynak bulunamadı
- `TimeoutException`: Timeout hataları
- `ServerException`: Sunucu hataları
- `BusinessLogicException`: İş mantığı hataları
- `DataFormatException`: Veri formatı hataları
- `StorageException`: Local storage hataları
- `SecurityException`: Güvenlik hataları

## Sonraki Adımlar

1. Kalan servislere ErrorHandlerMixin ekle
2. Kalan repository'lere BaseRepositoryMixin ekle
3. Controller/Notifier katmanında error handling standardize et
4. UI katmanında error display standardize et
5. Error tracking/monitoring entegrasyonu (Sentry, Firebase Crashlytics)

## Best Practices

1. Her catch bloğunda ErrorLogger kullan
2. Context bilgisini her zaman ekle
3. Read işlemlerinde fallback değer döndür
4. Write işlemlerinde exception fırlat
5. Kullanıcı dostu hata mesajları kullan
6. Stack trace'i her zaman logla
7. Generic exception'ları AppException'a dönüştür
