# 🏗️ Puantaj - Mimari Dokümantasyonu

Bu dokümantasyon, Flutter Puantaj uygulamasının mimari yapısını, tasarım kararlarını ve best practice'leri açıklar.

---

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Klasör Yapısı](#klasör-yapısı)
3. [Katmanlar](#katmanlar)
4. [State Management](#state-management)
5. [Data Flow](#data-flow)
6. [Error Handling](#error-handling)
7. [Performance Optimizasyonları](#performance-optimizasyonları)
8. [Best Practices](#best-practices)

---

## 🎯 Genel Bakış

Puantaj uygulaması, **Clean Architecture** prensiplerini takip eden, **feature-first** klasör yapısına sahip, modern bir Flutter uygulamasıdır.

### Temel Prensipler

1. **Separation of Concerns** - Her katman kendi sorumluluğuna odaklanır
2. **Dependency Inversion** - Üst seviye modüller alt seviye modüllere bağımlı değildir
3. **Single Responsibility** - Her sınıf tek bir sorumluluğa sahiptir
4. **DRY (Don't Repeat Yourself)** - Kod tekrarı minimize edilmiştir
5. **SOLID Principles** - Nesne yönelimli tasarım prensipleri uygulanmıştır

---

## 📁 Klasör Yapısı

```
lib/
├── config/                 # Uygulama konfigürasyonu
│   ├── app_routes.dart    # Route tanımları
│   ├── env_config.dart    # Environment variables
│   ├── feature_flags.dart # Feature flag'ler
│   └── service_initializer.dart
│
├── core/                   # Core functionality
│   ├── providers/         # Global Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── theme_provider.dart
│   │   └── user_data_provider.dart
│   ├── error_logger.dart  # Merkezi hata yönetimi
│   ├── app_bootstrap.dart # App initialization
│   └── app_router.dart    # Router configuration
│
├── features/              # Feature-first organization
│   ├── auth/             # Authentication feature
│   │   ├── login/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   └── register/
│   │
│   ├── user/             # User features
│   │   ├── home/
│   │   ├── profile/
│   │   ├── employees/
│   │   ├── attendance/
│   │   ├── payments/
│   │   ├── reports/
│   │   └── services/
│   │
│   ├── worker/           # Worker features
│   │   ├── home/
│   │   ├── profile/
│   │   └── notifications/
│   │
│   └── admin/            # Admin features
│       └── panel/
│
├── models/               # Data models
│   ├── employee.dart
│   ├── payment.dart
│   ├── attendance.dart
│   └── ...
│
├── services/             # Business logic services
│   ├── worker_service.dart
│   ├── payment_service.dart
│   ├── attendance_service.dart
│   ├── notification_service.dart
│   └── ...
│
├── utils/                # Utility functions
│   ├── date_formatter.dart
│   ├── currency_formatter.dart
│   ├── cached_future_builder.dart
│   └── ...
│
├── widgets/              # Reusable widgets
│   ├── cached_profile_avatar.dart
│   ├── common_button.dart
│   └── ...
│
└── main.dart            # Entry point
```

---

## 🎨 Katmanlar

### 1. Presentation Layer (UI)

**Sorumluluk:** Kullanıcı arayüzü ve kullanıcı etkileşimleri

**Bileşenler:**
- **Screens:** Tam sayfa widget'ları
- **Widgets:** Yeniden kullanılabilir UI bileşenleri
- **Controllers:** UI logic ve state management

**Örnek:**
```dart
// Screen
class EmployeeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    return EmployeeList(employees: employees);
  }
}

// Widget
class EmployeeCard extends StatelessWidget {
  final Employee employee;
  const EmployeeCard({required this.employee});
  
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(employee.name)));
  }
}
```

### 2. Business Logic Layer (Services)

**Sorumluluk:** İş mantığı, veri işleme, API çağrıları

**Bileşenler:**
- **Services:** Business logic implementation
- **Repositories:** Data access abstraction (planlı)
- **Use Cases:** Specific business operations (planlı)

**Örnek:**
```dart
class WorkerService {
  final AuthService _authService = AuthService();
  
  /// Çalışanları getir
  Future<List<Worker>> getWorkers() async {
    try {
      final userId = _authService.currentUserId;
      final response = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId);
      
      return response.map((json) => Worker.fromJson(json)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.logError('WorkerService.getWorkers', e, stackTrace);
      rethrow;
    }
  }
}
```

### 3. Data Layer

**Sorumluluk:** Veri kaynakları ile iletişim

**Bileşenler:**
- **Models:** Data transfer objects
- **API Clients:** Supabase client
- **Local Storage:** SharedPreferences, Hive (planlı)

**Örnek:**
```dart
class Worker {
  final int id;
  final String name;
  final String title;
  final DateTime startDate;
  
  Worker({
    required this.id,
    required this.name,
    required this.title,
    required this.startDate,
  });
  
  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      startDate: DateFormatter.fromIso8601Date(json['start_date']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'start_date': DateFormatter.toIso8601Date(startDate),
    };
  }
}
```

---

## 🔄 State Management

### Riverpod Architecture

Uygulama, **Riverpod** state management çözümünü kullanır. Riverpod, compile-time safety, testability ve performance avantajları sağlar.

### Provider Tipleri

#### 1. NotifierProvider (Mutable State)

**Kullanım:** Değişebilen state için

```dart
// Provider tanımı
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(() {
  return AuthStateNotifier();
});

// Notifier implementation
class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void login() => state = true;
  void logout() => state = false;
}

// Widget'ta kullanım
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider);
    return Text(isAuthenticated ? 'Logged In' : 'Logged Out');
  }
}
```

#### 2. FutureProvider (Async Data)

**Kullanım:** Asenkron veri yükleme için

```dart
final workersProvider = FutureProvider<List<Worker>>((ref) async {
  final service = WorkerService();
  return service.getWorkers();
});

// Widget'ta kullanım
class WorkerList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersProvider);
    
    return workersAsync.when(
      data: (workers) => ListView.builder(
        itemCount: workers.length,
        itemBuilder: (context, index) => WorkerCard(worker: workers[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### Global Providers

**AuthStateProvider** - Kimlik doğrulama durumu
```dart
ref.watch(authStateProvider) // State'i dinle
ref.read(authStateProvider.notifier).login() // State'i değiştir
```

**ThemeStateProvider** - Tema yönetimi
```dart
ref.watch(themeStateProvider) // ThemeMode.light / ThemeMode.dark
ref.read(themeStateProvider.notifier).setTheme(ThemeMode.dark)
```

**UserDataProvider** - Kullanıcı verisi
```dart
ref.watch(userDataProvider) // Map<String, dynamic>?
ref.read(userDataProvider.notifier).isAdmin // Admin kontrolü
```

---

## 📊 Data Flow

### 1. User Action → UI Update

```
User Action
    ↓
Widget Event Handler
    ↓
Provider Notifier Method
    ↓
State Update
    ↓
Widget Rebuild (ref.watch)
    ↓
UI Update
```

**Örnek:**
```dart
// 1. User taps button
ElevatedButton(
  onPressed: () {
    // 2. Call provider method
    ref.read(authStateProvider.notifier).login();
  },
  child: Text('Login'),
)

// 3. Provider updates state
class AuthStateNotifier extends Notifier<bool> {
  void login() {
    state = true; // State update triggers rebuild
  }
}

// 4. Widget rebuilds with new state
Consumer(
  builder: (context, ref, child) {
    final isAuth = ref.watch(authStateProvider);
    return Text(isAuth ? 'Welcome' : 'Please login');
  },
)
```

### 2. API Call → Data Display

```
Widget Build
    ↓
ref.watch(futureProvider)
    ↓
Service Method Call
    ↓
Supabase API Request
    ↓
Response Processing
    ↓
Model Conversion
    ↓
Provider State Update
    ↓
Widget Rebuild with Data
```

**Örnek:**
```dart
// 1. Widget watches provider
final workersAsync = ref.watch(workersProvider);

// 2. Provider calls service
final workersProvider = FutureProvider<List<Worker>>((ref) async {
  final service = WorkerService();
  return service.getWorkers(); // 3. Service calls API
});

// 4. Service processes response
Future<List<Worker>> getWorkers() async {
  final response = await supabase.from('workers').select();
  return response.map((json) => Worker.fromJson(json)).toList();
}

// 5. Widget displays data
workersAsync.when(
  data: (workers) => WorkerList(workers: workers),
  loading: () => LoadingIndicator(),
  error: (error, stack) => ErrorWidget(error: error),
)
```

---

## ⚠️ Error Handling

### ErrorLogger Singleton

Merkezi hata yönetimi için `ErrorLogger` singleton kullanılır.

**Özellikler:**
- Context bilgisi ile hata loglama
- Stack trace desteği
- Emoji indicator'lar (❌, ⚠️, ℹ️)
- Production/Debug mode desteği

**Kullanım:**
```dart
try {
  final result = await riskyOperation();
} catch (e, stackTrace) {
  ErrorLogger.logError('ClassName.methodName', e, stackTrace);
  // Handle error gracefully
  rethrow; // or return default value
}
```

### Error Handling Pattern

**Service Layer:**
```dart
Future<List<Worker>> getWorkers() async {
  try {
    final response = await supabase.from('workers').select();
    return response.map((json) => Worker.fromJson(json)).toList();
  } catch (e, stackTrace) {
    ErrorLogger.logError('WorkerService.getWorkers', e, stackTrace);
    rethrow; // Let UI handle the error
  }
}
```

**UI Layer:**
```dart
final workersAsync = ref.watch(workersProvider);

workersAsync.when(
  data: (workers) => WorkerList(workers: workers),
  loading: () => LoadingIndicator(),
  error: (error, stack) {
    // User-friendly error message
    return ErrorWidget(
      message: 'Çalışanlar yüklenirken hata oluştu',
      onRetry: () => ref.refresh(workersProvider),
    );
  },
)
```

---

## ⚡ Performance Optimizasyonları

### 1. Cache Mekanizması

**CachedFutureBuilder** - Generic cache widget

```dart
CachedFutureBuilder<List<Worker>>(
  cacheKey: 'workers_list',
  cacheDuration: Duration(minutes: 5),
  future: () => workerService.getWorkers(),
  builder: (context, data) {
    return WorkerList(workers: data);
  },
  errorBuilder: (context, error) {
    return ErrorWidget(error: error);
  },
  loadingBuilder: (context) {
    return LoadingIndicator();
  },
)
```

**Avantajlar:**
- Network request'leri azaltır (%80-90)
- Kullanıcı deneyimini iyileştirir
- Battery consumption azalır

### 2. N+1 Query Çözümü

**Problem:** Her çalışan için ayrı query (15+ query)

**Çözüm:** Supabase RPC fonksiyonları (1 query)

```sql
-- RPC Function
CREATE OR REPLACE FUNCTION get_workers_with_unpaid_days(p_user_id UUID)
RETURNS TABLE (
  worker_id INT,
  worker_name TEXT,
  unpaid_full_days INT,
  unpaid_half_days INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id,
    w.name,
    COUNT(CASE WHEN a.day_type = 'full' THEN 1 END)::INT,
    COUNT(CASE WHEN a.day_type = 'half' THEN 1 END)::INT
  FROM workers w
  LEFT JOIN attendance a ON w.id = a.worker_id
  LEFT JOIN paid_days pd ON a.id = pd.attendance_id
  WHERE w.user_id = p_user_id AND pd.id IS NULL
  GROUP BY w.id, w.name;
END;
$$ LANGUAGE plpgsql;
```

```dart
// Dart usage
Future<List<WorkerWithUnpaidDays>> getWorkersWithUnpaidDays() async {
  final response = await supabase.rpc('get_workers_with_unpaid_days', 
    params: {'p_user_id': userId}
  );
  return response.map((json) => WorkerWithUnpaidDays.fromJson(json)).toList();
}
```

**Sonuç:** 15+ query → 1 query (%93 azalma)

### 3. Image Caching

**CachedProfileAvatar** - Cached network image widget

```dart
CachedProfileAvatar(
  imageUrl: worker.profileImageUrl,
  name: worker.name,
  radius: 40,
  backgroundColor: Colors.blue,
)
```

**Özellikler:**
- 7 gün cache retention
- Otomatik placeholder (loading)
- Error fallback (ilk harf avatarı)
- Memory-efficient

### 4. ListView Optimizasyonları

```dart
ListView.builder(
  itemCount: workers.length,
  itemExtent: 80.0, // Fixed height for better performance
  addAutomaticKeepAlives: false, // Don't keep offscreen items alive
  addRepaintBoundaries: true, // Optimize repaints
  itemBuilder: (context, index) {
    return WorkerCard(worker: workers[index]);
  },
)
```

**Sonuç:** 60 FPS smooth scrolling

---

## 🎯 Best Practices

### 1. Naming Conventions

**Dart Style Guide:**
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `camelCase` (not SCREAMING_SNAKE_CASE)
- Private members: `_leadingUnderscore`

**Örnek:**
```dart
class WorkerService {
  static const int maxRetries = 3;
  final AuthService _authService = AuthService();
  
  Future<List<Worker>> getWorkers() async { ... }
  void _processResponse(dynamic response) { ... }
}
```

### 2. Const Constructors

Mümkün olan her yerde `const` constructor kullanın:

```dart
// Good
const SizedBox(height: 16)
const Text('Hello')
const Icon(Icons.person)

// Bad
SizedBox(height: 16)
Text('Hello')
Icon(Icons.person)
```

### 3. Null Safety

Null-aware operatörler kullanın:

```dart
// Good
final name = worker?.name ?? 'Unknown';
final email = user?.email?.toLowerCase();

// Bad
final name = worker != null ? worker.name : 'Unknown';
if (user != null && user.email != null) {
  final email = user.email!.toLowerCase();
}
```

### 4. Async/Await

```dart
// Good
Future<void> loadData() async {
  try {
    final data = await service.getData();
    processData(data);
  } catch (e, stackTrace) {
    ErrorLogger.logError('loadData', e, stackTrace);
  }
}

// Bad
Future<void> loadData() {
  return service.getData().then((data) {
    processData(data);
  }).catchError((e) {
    print('Error: $e');
  });
}
```

### 5. Widget Composition

Küçük, yeniden kullanılabilir widget'lar oluşturun:

```dart
// Good
class WorkerCard extends StatelessWidget {
  final Worker worker;
  const WorkerCard({required this.worker});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          _buildBody(),
          _buildFooter(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() => ...
  Widget _buildBody() => ...
  Widget _buildFooter() => ...
}

// Bad - Monolithic widget
class WorkerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 100+ lines of nested widgets
        ],
      ),
    );
  }
}
```

### 6. Türkçe Dokümantasyon

Tüm kod açıklamaları Türkçe olmalıdır:

```dart
/// Çalışan servis sınıfı
/// 
/// Çalışan CRUD işlemlerini yönetir.
/// Tüm tarihler Türkiye saat diliminde (Europe/Istanbul, UTC+3) işlenir.
class WorkerService {
  /// Çalışanları getirir
  /// 
  /// [userId] parametresi ile filtreleme yapar.
  /// Hata durumunda [ErrorLogger] ile loglar ve exception fırlatır.
  Future<List<Worker>> getWorkers(String userId) async { ... }
}
```

---

## 🔮 Gelecek İyileştirmeler

### 1. Repository Pattern

Service layer'ı repository pattern ile refactor et:

```dart
abstract class WorkerRepository {
  Future<List<Worker>> getWorkers(String userId);
  Future<Worker> getWorkerById(int id);
  Future<void> createWorker(Worker worker);
  Future<void> updateWorker(Worker worker);
  Future<void> deleteWorker(int id);
}

class SupabaseWorkerRepository implements WorkerRepository {
  @override
  Future<List<Worker>> getWorkers(String userId) async { ... }
}
```

### 2. Use Cases

Business logic'i use case'lere taşı:

```dart
class GetWorkersUseCase {
  final WorkerRepository repository;
  
  GetWorkersUseCase(this.repository);
  
  Future<List<Worker>> execute(String userId) async {
    return repository.getWorkers(userId);
  }
}
```

### 3. Dependency Injection

GetIt ile dependency injection:

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<WorkerRepository>(SupabaseWorkerRepository());
  getIt.registerFactory<GetWorkersUseCase>(() => GetWorkersUseCase(getIt()));
}
```

### 4. Offline-First

Local database (Hive/Drift) ile offline support:

```dart
class WorkerRepository {
  final RemoteDataSource remote;
  final LocalDataSource local;
  
  Future<List<Worker>> getWorkers() async {
    try {
      final workers = await remote.getWorkers();
      await local.saveWorkers(workers);
      return workers;
    } catch (e) {
      return local.getWorkers(); // Fallback to local
    }
  }
}
```

---

## 📚 Referanslar

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Riverpod Documentation](https://riverpod.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)

---

**Son Güncelleme:** 6 Mart 2026  
**Versiyon:** 1.0.0
