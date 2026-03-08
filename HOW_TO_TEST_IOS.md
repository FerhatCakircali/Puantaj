# iOS Test - Mac/iPhone Olmadan

## 🎯 Ne Yapacaksın:

### 1. GitHub'da Workflow Oluştur
1. GitHub.com > Projen > **Actions** sekmesi
2. **New workflow** > **set up a workflow yourself**
3. Dosya adı: `ios-build.yml`
4. Aşağıdaki kodu yapıştır:

```yaml
name: iOS Build

on:
  push:
    branches: [ main, feature/optimization-phase-3 ]
  workflow_dispatch:

jobs:
  build-ios:
    name: Build iOS App
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: 'stable'
      
      - name: Create .env
        run: |
          cp .env.example .env || echo "SUPABASE_URL=dummy" > .env
          echo "SUPABASE_ANON_KEY=dummy" >> .env
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Create IPA
        run: |
          cd build/ios/iphoneos
          mkdir Payload
          cp -r Runner.app Payload/
          zip -r ios-app.zip Payload
      
      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          name: ios-app
          path: build/ios/iphoneos/ios-app.zip
```

5. **Commit changes** > **Commit directly to feature/optimization-phase-3**

### 2. Build Başlayacak (10 dakika)
- Actions sekmesinde otomatik başlar
- Bekle

### 3. Build'i İndir
- Build bitince **ios-app** artifact'ı indir

### 4. Appetize.io'da Test Et
- https://appetize.io > **Try Demo**
- ZIP'i yükle
- iPhone 14 Pro seç
- Test et!

## 💰 Ücretsiz mi?
Evet. Ayda 100 dakika.

---

**Özet**: Workflow oluştur, bekle, indir, test et.
