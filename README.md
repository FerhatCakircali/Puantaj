## Puantaj Uygulaması

### Genel Bakış
Bu proje, çalışanların puantaj kayıtlarını, ödemelerini ve ilgili bildirimleri yönetmek için tasarlanmış bir mobil uygulamadır. Hem yöneticilerin hem de çalışanların günlük katılım ve ödeme süreçlerini kolaylaştırmayı hedefler. Uygulama, Flutter ile geliştirilmiştir ve Supabase üzerinde bir backend kullanmaktadır.

### Özellikler
- **Kullanıcı Yönetimi**: Yönetici ve çalışan rolleriyle kullanıcı kaydı ve oturum açma.
- **Çalışan Takibi**: Çalışan ekleme, düzenleme ve listeleme.
- **Katılım Takibi**: Çalışanların günlük katılım durumlarını (tam gün, yarım gün, devamsız) kaydetme.
- **Ödeme Yönetimi**: Çalışanlara yapılan ödemeleri kaydetme ve geçmiş ödemeleri takip etme.
- **Hatırlatıcılar ve Bildirimler**: Çalışanlara özel hatırlatıcılar ve genel bildirim ayarları.
- **Veri Raporlama**: Ödeme ve katılım verileri üzerinde raporlama ve özetleme.
- **PDF Raporlama**: Oluşturulan raporları PDF olarak dışa aktarma.

### Teknolojiler
Uygulama aşağıdaki ana teknolojileri ve kütüphaneleri kullanmaktadır:

- **Flutter**: Mobil uygulama geliştirme çerçevesi.
- **Supabase**: Backend hizmetleri (kimlik doğrulama, veritabanı, depolama).
- **GoRouter**: Uygulama içi navigasyon yönetimi.
- **shared_preferences**: Yerel veri depolama.
- **intl**: Uluslararasılaştırma ve yerelleştirme.
- **flutter_local_notifications**: Yerel bildirimler.
- **table_calendar**: Takvim görünümü.
- **google_fonts**: Özel yazı tipleri.
- **responsive_framework**: Duyarlı UI tasarımı.
- **uuid**: Benzersiz ID oluşturma.
- **pdf & open_file & path_provider**: PDF oluşturma ve açma.
- **permission_handler**: İzin yönetimi.
- **share_plus**: İçerik paylaşımı.
- **device_info_plus**: Cihaz bilgileri.
- **google_sign_in**: Google ile oturum açma.
- **googleapis & googleapis_auth & http**: Google API entegrasyonu.
- **bcrypt**: Şifre hashleme.
- **url_launcher**: URL açma.
- **credential_manager**: Kimlik bilgisi yönetimi.

### Kurulum
Projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin:

#### Önkoşullar
- Flutter SDK yüklü ve güncel olmalı. ([Flutter Kurulum Rehberi](https://flutter.dev/docs/get-started/install))
- Supabase CLI yüklü olmalı veya Supabase hesabınız olmalı.

#### Proje Kurulumu
1.  Depoyu klonlayın:
    ```bash
    git clone <depo-url>
    cd puantaj
    ```
2.  Gerekli Flutter bağımlılıklarını yükleyin:
    ```bash
    flutter pub get
    ```

#### Supabase Kurulumu
1.  Yeni bir Supabase projesi oluşturun.
2.  `supabase_tables.sql` dosyasındaki SQL şemasını Supabase projenizin SQL Editoründe çalıştırarak veritabanı tablolarını ve fonksiyonlarını oluşturun.
3.  Supabase projenizin API URL'sini ve `anon` anahtarını alın. Bu bilgileri projenizin ilgili yapılandırma dosyasına (örneğin, bir `.env` dosyası veya `lib/core/constants.dart` gibi bir dosya) eklemeniz gerekecektir.
    ```dart
    // Örnek: lib/core/constants.dart
    const String supabaseUrl = 'YOUR_SUPABASE_URL';
    const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
    ```

#### Uygulamayı Çalıştırma
1.  Uygulamayı bir emülatörde veya fiziksel cihazda çalıştırın:
    ```bash
    flutter run
    ```

### Proje Yapısı
`lib` dizini altında projenin temel yapısı şu şekildedir:

-   `core/`: Çekirdek işlevsellik, sabitler, bağımlılık enjeksiyonu ve tema gibi genel uygulama katmanları.
-   `models/`: Veritabanı tablolarıyla veya API yanıtlarıyla eşleşen veri modelleri (genellikle `freezed` ile oluşturulur).
-   `screens/`: Uygulamanın farklı ekranlarını içeren widget'lar ve ilgili state yönetimi.
-   `services/`: Supabase entegrasyonu gibi harici servislerle iletişim kuran sınıflar (örneğin, `AuthService`, `DatabaseService`).
-   `utils/`: Yardımcı fonksiyonlar, formatlayıcılar ve genel kullanıma açık araçlar.
-   `widgets/`: Uygulama genelinde yeniden kullanılabilir UI bileşenleri.
-   `main.dart`: Uygulamanın ana giriş noktası ve router yapılandırması.
