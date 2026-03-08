# Store Deployment Guide - Puantaj App

Bu döküman, Puantaj uygulamasını Google Play Store ve Apple App Store'a yüklemek için gereken adımları içerir.

## 📱 Genel Bilgiler

- **Uygulama Adı**: Puantaj
- **Bundle ID (iOS)**: com.example.puantaj
- **Application ID (Android)**: com.example.puantaj
- **Versiyon**: 1.0.0
- **Build Number**: 1

## 🤖 Android - Google Play Store

### 1. Keystore Oluşturma

Eğer keystore dosyanız yoksa, aşağıdaki komutla oluşturun:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**ÖNEMLİ**: 
- Şifreleri güvenli bir yerde saklayın
- Keystore dosyasını yedekleyin (kaybederseniz uygulama güncelleyemezsiniz)

### 2. key.properties Dosyası Oluşturma

`android/key.properties` dosyası oluşturun:

```properties
storePassword=KEYSTORE_ŞİFRENİZ
keyPassword=KEY_ŞİFRENİZ
keyAlias=upload
storeFile=/Users/KULLANICI_ADINIZ/upload-keystore.jks
```

**NOT**: Bu dosya `.gitignore`'da olmalı (zaten ekli)

### 3. Application ID Değiştirme

`android/app/build.gradle.kts` dosyasında:

```kotlin
applicationId = "com.yourcompany.puantaj"  // Kendi domain'inizi kullanın
```

### 4. Release Build Oluşturma

```bash
# APK oluşturma
flutter build apk --release

# App Bundle oluşturma (Play Store için önerilen)
flutter build appbundle --release
```

Build dosyaları:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 5. Google Play Console'da Yükleme

1. [Google Play Console](https://play.google.com/console)'a gidin
2. Yeni uygulama oluşturun
3. **Production** > **Create new release**
4. `app-release.aab` dosyasını yükleyin
5. Store listing bilgilerini doldurun:
   - Uygulama adı
   - Kısa açıklama
   - Tam açıklama
   - Ekran görüntüleri (en az 2 adet)
   - Uygulama ikonu
   - Feature graphic
6. İçerik derecelendirmesi yapın
7. Hedef kitle ve içerik seçin
8. Gizlilik politikası URL'i ekleyin
9. Yayınlamak için gönder

### 6. Gerekli Ekran Görüntüleri

- **Telefon**: 2-8 adet (1080x1920 veya 1080x2340)
- **7-inch Tablet**: 1-8 adet (1200x1920)
- **10-inch Tablet**: 1-8 adet (1600x2560)

## 🍎 iOS - Apple App Store

### 1. Apple Developer Hesabı

- [Apple Developer Program](https://developer.apple.com/programs/) üyeliği gerekli ($99/yıl)
- Hesabınızı aktif edin

### 2. Bundle Identifier Değiştirme

Xcode'da:
1. `ios/Runner.xcworkspace` dosyasını açın
2. Runner > Signing & Capabilities
3. Bundle Identifier'ı değiştirin: `com.yourcompany.puantaj`
4. Team seçin (Apple Developer hesabınız)

### 3. App Store Connect'te Uygulama Oluşturma

1. [App Store Connect](https://appstoreconnect.apple.com)'e gidin
2. **My Apps** > **+** > **New App**
3. Bilgileri doldurun:
   - Platform: iOS
   - Name: Puantaj
   - Primary Language: Turkish
   - Bundle ID: Seçin
   - SKU: Benzersiz bir ID (örn: puantaj-2025)

### 4. Info.plist Güncellemeleri

`ios/Runner/Info.plist` dosyası zaten güncellenmiş durumda:
- ✅ Display Name
- ✅ Version
- ✅ Build Number
- ✅ Permissions (bildirimler için)

### 5. Archive ve Upload

```bash
# iOS build oluşturma
flutter build ios --release

# Xcode'da:
# 1. Product > Archive
# 2. Organizer'da Archive'ı seçin
# 3. Distribute App > App Store Connect
# 4. Upload
```

### 6. App Store Connect'te Yayınlama

1. **App Information** sekmesinde:
   - Kategori seçin (Business)
   - İçerik hakları bilgisi
   
2. **Pricing and Availability**:
   - Fiyat: Ücretsiz
   - Ülkeler seçin

3. **App Privacy**:
   - Gizlilik politikası URL'i
   - Veri toplama bilgileri

4. **Prepare for Submission**:
   - Ekran görüntüleri (6.5", 5.5" iPhone)
   - Uygulama önizleme videosu (opsiyonel)
   - Açıklama
   - Anahtar kelimeler
   - Support URL
   - Marketing URL (opsiyonel)

5. **Submit for Review**

### 7. Gerekli Ekran Görüntüleri

- **6.7" Display (iPhone 14 Pro Max)**: 1290x2796
- **6.5" Display (iPhone 11 Pro Max)**: 1242x2688
- **5.5" Display (iPhone 8 Plus)**: 1242x2208
- **12.9" iPad Pro**: 2048x2732

## 📋 Store Listing İçeriği

### Uygulama Açıklaması (Türkçe)

**Kısa Açıklama** (80 karakter):
```
İşçi puantaj takibi ve ödeme yönetimi için profesyonel çözüm
```

**Tam Açıklama**:
```
Puantaj - İşçi Takip ve Ödeme Yönetimi

İşletmenizin işçi puantaj takibini ve ödeme yönetimini kolaylaştıran profesyonel mobil uygulama.

ÖZELLİKLER:

📊 Puantaj Yönetimi
• Günlük çalışma saatlerini kaydedin
• Tam gün, yarım gün ve saat bazlı kayıt
• Geçmiş kayıtları görüntüleyin ve düzenleyin

💰 Ödeme Takibi
• Günlük ücret hesaplama
• Avans ve ödeme kayıtları
• Detaylı ödeme geçmişi

👥 Çalışan Yönetimi
• Çalışan profilleri
• İletişim bilgileri
• Performans takibi

📈 Raporlama
• Aylık çalışma raporları
• Ödeme özetleri
• Excel export

🔔 Hatırlatıcılar
• Günlük puantaj hatırlatıcıları
• Ödeme hatırlatmaları
• Özelleştirilebilir bildirimler

🔒 Güvenlik
• Şifreli veri saklama
• Kullanıcı yetkilendirme
• Veri yedekleme

İşletmenizi dijitalleştirin, zaman kazanın!
```

### Anahtar Kelimeler (iOS - 100 karakter)

```
puantaj,işçi,takip,ödeme,maaş,çalışan,yönetim,rapor,avans,mesai
```

### Kategori

- **Primary**: Business
- **Secondary**: Productivity

## 🔐 Gizlilik Politikası

Gizlilik politikası URL'i gereklidir. Örnek içerik için `PRIVACY_POLICY.md` dosyasına bakın.

## 📸 Ekran Görüntüleri Oluşturma

```bash
# iOS Simulator'da ekran görüntüsü alma
# Cmd + S

# Android Emulator'da ekran görüntüsü alma
# Emulator toolbar > Camera icon
```

**Önerilen Ekranlar**:
1. Ana sayfa / Dashboard
2. Puantaj kayıt ekranı
3. Çalışan listesi
4. Ödeme geçmişi
5. Raporlar
6. Bildirim ayarları

## 🚀 Yayınlama Öncesi Kontrol Listesi

### Android
- [ ] Application ID değiştirildi
- [ ] Keystore oluşturuldu ve güvenli yerde saklandı
- [ ] key.properties dosyası oluşturuldu
- [ ] Release build test edildi
- [ ] App Bundle oluşturuldu
- [ ] Ekran görüntüleri hazırlandı
- [ ] Gizlilik politikası hazırlandı
- [ ] Store listing metinleri hazırlandı

### iOS
- [ ] Bundle Identifier değiştirildi
- [ ] Apple Developer hesabı aktif
- [ ] Signing & Capabilities yapılandırıldı
- [ ] Archive oluşturuldu
- [ ] TestFlight'ta test edildi
- [ ] Ekran görüntüleri hazırlandı
- [ ] Gizlilik politikası hazırlandı
- [ ] Store listing metinleri hazırlandı

## 📞 Destek

Sorun yaşarsanız:
- Email: ferhatcakircali@gmail.com
- GitHub Issues: [Proje Repository]

## 📝 Notlar

1. **İlk Yayınlama**: İnceleme süreci 1-7 gün sürebilir
2. **Güncellemeler**: Daha hızlı onaylanır (1-3 gün)
3. **Red Durumu**: İnceleme notlarını dikkatlice okuyun ve gerekli düzeltmeleri yapın
4. **Test**: Her iki platformda da yayınlamadan önce mutlaka test edin

## 🔄 Güncelleme Yayınlama

### Versiyon Numarası Güncelleme

`pubspec.yaml` dosyasında:
```yaml
version: 1.0.1+2  # 1.0.1 = version name, 2 = build number
```

### Android Güncelleme
```bash
flutter build appbundle --release
# Play Console > Production > Create new release
```

### iOS Güncelleme
```bash
flutter build ios --release
# Xcode > Product > Archive > Upload
# App Store Connect > New Version
```

---

**Son Güncelleme**: Mart 2025
**Hazırlayan**: Puantaj Development Team
