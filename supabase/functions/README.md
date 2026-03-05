# Supabase Edge Functions - Email Servisi

Bu klasör Supabase Edge Function'larını içerir.

## Kurulum

### 1. Supabase CLI Kurulumu

```bash
# Windows (PowerShell)
scoop install supabase

# veya npm ile
npm install -g supabase
```

### 2. Supabase'e Login

```bash
supabase login
```

### 3. Projeyi Bağla

```bash
supabase link --project-ref YOUR_PROJECT_REF
```

Project ref'i Supabase dashboard'dan alabilirsiniz:
- https://supabase.com/dashboard
- Projenizi seçin
- Settings > General > Reference ID

### 4. Environment Variables Ayarla

Supabase dashboard'da:
1. Settings > Edge Functions
2. Add secret: `RESEND_API_KEY` = `your_resend_api_key`

### 5. Function'ı Deploy Et

```bash
supabase functions deploy send-email
```

### 6. Test Et

```bash
curl -i --location --request POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-email' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"to":"test@example.com","subject":"Test","html":"<p>Test email</p>"}'
```

## Alternatif: Resend Olmadan (Ücretsiz)

Eğer Resend API kullanmak istemiyorsanız, Brevo (Sendinblue) kullanabilirsiniz:

1. https://www.brevo.com/ adresine git
2. Ücretsiz hesap oluştur
3. API key al
4. `supabase/functions/send-email/index.ts` dosyasında Resend yerine Brevo API'sini kullan

### Brevo API Örneği:

```typescript
const res = await fetch('https://api.brevo.com/v3/smtp/email', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'api-key': BREVO_API_KEY,
  },
  body: JSON.stringify({
    sender: { name: 'Puantaj Sistemi', email: 'noreply@yourdomain.com' },
    to: [{ email: to }],
    subject: subject,
    htmlContent: html,
  }),
})
```

## Notlar

- Edge Function ücretsizdir (500,000 istek/ay)
- Resend API test modunda sadece kayıtlı email'e gönderir
- Production için domain doğrulaması veya Brevo kullanın
