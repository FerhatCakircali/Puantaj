# 🔐 GitHub Güvenlik Kontrol Listesi

Bu dosya, projeyi GitHub'a yüklemeden önce yapılması gereken güvenlik kontrollerini içerir.

## ✅ Yapılandırma Dosyaları

### .gitignore Kontrolleri

- [x] `.env` dosyası ignore edilmiş
- [x] `google-services.json` ignore edilmiş
- [x] `lib/config/secrets.dart` ignore edilmiş
- [x] `SonAsamaSQL/PuantajAllQuery.sql.local` ignore edilmiş
- [x] `supabase/migrations/*.sql.local` ignore edilmiş

### Placeholder Dosyalar Oluşturuldu

- [x] `.env.example` oluşturuldu
- [x] `lib/config/secrets.dart.example` oluşturuldu
- [x] `android/app/google-services.json.example` oluşturuldu
- [x] `SonAsamaSQL/PuantajAllQuery.sql` (placeholder versiyonu)

### Gerçek Değerler İçeren Dosyalar

- [x] `lib/config/secrets.dart` oluşturuldu (gitignore'da)
- [x] `SonAsamaSQL/PuantajAllQuery.sql.local` oluşturuldu (gitignore'da)
- [x] `android/app/google-services.json` mevcut (gitignore'da)
- [x] `.env` mevcut (gitignore'da)

## 🔍 Hassas Bilgi Kontrolü

### Supabase Bilgileri

- [x] URL placeholder'a çevrildi
- [x] Anon Key placeholder'a çevrildi
- [x] Service Role Key placeholder'a çevrildi

### Firebase Bilgileri

- [x] `google-services.json` gitignore'da
- [x] `google-services.json.example` oluşturuldu

### SQL Dosyaları

- [x] Service Role Key placeholder'a çevrildi
- [x] Supabase URL placeholder'a çevrildi
- [x] Gerçek değerler `.local` dosyasında

## 📝 Kod Değişiklikleri

### service_initializer.dart

- [x] Hardcoded URL kaldırıldı
- [x] Hardcoded Anon Key kaldırıldı
- [x] `Secrets` class'ı import edildi
- [x] `Secrets.supabaseUrl` kullanılıyor
- [x] `Secrets.supabaseAnonKey` kullanılıyor

### env_config.dart

- [x] Environment variables desteği eklendi
- [x] Development/Production ayrımı yapıldı
- [x] Fallback mekanizması eklendi

## 📚 Dokümantasyon

- [x] `SETUP.md` oluşturuldu
- [x] `README.md` oluşturuldu
- [x] `SECURITY_CHECKLIST.md` oluşturuldu (bu dosya)

## 🚀 GitHub'a Yüklemeden Önce

### 1. Git Repository Başlatma

```bash
git init
git add .
git status
```

### 2. Hassas Dosyaların Görünmediğini Kontrol Edin

`git status` çıktısında şunlar OLMAMALI:

- ❌ `.env`
- ❌ `lib/config/secrets.dart`
- ❌ `android/app/google-services.json`
- ❌ `SonAsamaSQL/PuantajAllQuery.sql.local`

### 3. Placeholder Dosyaların Görünmesini Kontrol Edin

`git status` çıktısında şunlar OLMALI:

- ✅ `.env.example`
- ✅ `.gitignore`
- ✅ `lib/config/secrets.dart.example`
- ✅ `lib/config/env_config.dart`
- ✅ `android/app/google-services.json.example`
- ✅ `SonAsamaSQL/PuantajAllQuery.sql`
- ✅ `SETUP.md`
- ✅ `README.md`

### 4. Dosya İçeriklerini Kontrol Edin

```bash
# Placeholder dosyalarda gerçek değer olmamalı
grep -r "uvdcefauzxordqgvvweq" --exclude-dir=.git --exclude="*.local" --exclude=".env"

# Eğer sonuç çıkarsa, o dosyaları kontrol edin!
```

### 5. İlk Commit

```bash
git add .
git commit -m "Initial commit: Secure configuration setup"
```

### 6. GitHub Repository Oluşturma

1. GitHub'da yeni repository oluşturun
2. Repository'yi private yapın (önerilir)
3. README.md ekleyin (zaten var)
4. .gitignore ekleyin (zaten var)

### 7. Remote Ekleme ve Push

```bash
git remote add origin https://github.com/YOUR_USERNAME/puantaj.git
git branch -M main
git push -u origin main
```

## ⚠️ Yanlışlıkla Commit Edilirse

Eğer hassas bir dosyayı yanlışlıkla commit ettiyseniz:

```bash
# Dosyayı git'ten kaldır (disk'ten silmez)
git rm --cached .env
git rm --cached lib/config/secrets.dart
git rm --cached android/app/google-services.json

# Commit et
git commit -m "Remove sensitive files"

# Push et
git push
```

⚠️ **ÖNEMLİ:** Eğer dosya zaten GitHub'a push edildiyse:

1. Dosyayı git'ten kaldırın (yukarıdaki komutlar)
2. GitHub'da repository settings > Secrets'tan yeni key'ler oluşturun
3. Supabase/Firebase'de key'leri yenileyin (rotate)
4. Eski key'ler artık güvenli değildir!

## 🔒 Güvenlik En İyi Uygulamaları

### Service Role Key

- ❌ Asla Flutter kodunda kullanmayın
- ❌ Asla GitHub'a yüklemeyin
- ✅ Sadece SQL/Backend'de kullanın
- ✅ Environment variables ile yönetin

### Anon Key

- ✅ Flutter kodunda kullanılabilir
- ✅ Public key'dir
- ✅ RLS politikaları ile korunur
- ⚠️ Yine de .gitignore'da tutun

### Firebase Config

- ❌ `google-services.json` asla GitHub'a yüklemeyin
- ✅ Her geliştirici kendi dosyasını Firebase'den indirmeli
- ✅ `.example` dosyası ile yapı gösterin

### Environment Variables

- ✅ Production'da environment variables kullanın
- ✅ Development'ta `secrets.dart` kullanın
- ✅ `.env.example` ile şablon sağlayın
- ❌ Gerçek değerleri asla commit etmeyin

## 📊 Güvenlik Skoru

Tüm checkboxlar işaretliyse: ✅ **100/100** - GitHub'a yüklenmeye hazır!

## 📞 Destek

Güvenlik konusunda soru veya endişeleriniz varsa:

1. Bu checklist'i tekrar gözden geçirin
2. `git status` ile dosyaları kontrol edin
3. Hassas bilgilerin placeholder'a çevrildiğinden emin olun

---

**Son Kontrol:** `git status` çalıştırın ve hassas dosyaların görünmediğinden emin olun!
