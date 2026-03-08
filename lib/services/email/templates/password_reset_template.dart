/// Şifre sıfırlama email HTML template'i
class PasswordResetTemplate {
  /// Şifre sıfırlama email HTML'ini oluşturur
  static String build(String username, String code) {
    return '''
<!DOCTYPE html>
<html lang="tr" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Puantaj | Şifre Sıfırlama</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@600;800&display=swap');
    :root { color-scheme: light dark; }
    body { margin: 0; padding: 0; width: 100% !important; background-color: #F4F4F5; font-family: 'Inter', sans-serif; -webkit-font-smoothing: antialiased; }
    .wrapper { width: 100%; background-color: #F4F4F5; padding: 60px 0; }
    .ticket-card { max-width: 500px; margin: 0 auto; background: #FFFFFF; border: 1px solid #E4E4E7; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
    .card-body { padding: 48px 40px; }
    
    .logo-container {
      width: 64px; height: 64px;
      border-radius: 16px;
      overflow: hidden;
      border: 1px solid #E4E4E7;
      box-shadow: 0 4px 10px rgba(0,0,0,0.05);
    }
    .brand-logo { width: 64px; height: 64px; display: block; border: 0; }

    .brand-title { font-size: 22px; font-weight: 700; color: #18181B; margin: 0; line-height: 1.2; }
    .brand-subtitle { font-size: 14px; color: #71717A; margin: 0; }
    .h1 { font-size: 28px; font-weight: 700; color: #09090B; letter-spacing: -0.5px; margin: 32px 0 16px 0; }
    .p { font-size: 15px; color: #52525B; line-height: 1.6; margin-bottom: 32px; }
    
    .code-box { background: #F8FAFC; border: 1px solid #E2E8F0; border-left: 4px solid #4F46E5; border-radius: 16px; padding: 32px; margin-bottom: 32px; text-align: center; }
    .code-number { font-family: 'JetBrains Mono', monospace; font-size: 42px; font-weight: 800; color: #4F46E5; letter-spacing: 10px; margin: 0; }

    @media (prefers-color-scheme: dark) {
      body, .wrapper { background-color: #000000 !important; }
      .ticket-card { background: #09090B !important; border-color: #27272A !important; }
      .brand-title, .h1 { color: #FAFAFA !important; }
      .p { color: #A1A1AA !important; }
      .code-box { background: #18181B !important; border-color: #27272A !important; }
      .code-number { color: #818CF8 !important; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" role="presentation">
      <tr>
        <td align="center">
          <div class="ticket-card">
            <div class="card-body">
              <table border="0" cellspacing="0" cellpadding="0" role="presentation">
                <tr>
                  <td style="vertical-align: middle;">
                    <div class="logo-container">
                      <img src="https://uvdcefauzxordqgvvweq.supabase.co/storage/v1/object/public/app-assets/icon.png" class="brand-logo" alt="Puantaj">
                    </div>
                  </td>
                  <td style="padding-left: 16px; vertical-align: middle;">
                    <h2 class="brand-title">Puantaj</h2>
                    <p class="brand-subtitle">Yönetim Sistemi</p>
                  </td>
                </tr>
              </table>

              <h1 class="h1">Şifre Sıfırlama Talebi</h1>
              <p class="p">
                Merhaba <strong>$username</strong>,<br><br>
                Puantaj hesabınız için bir şifre sıfırlama talebi aldık. İşleminize devam etmek için aşağıdaki doğrulama kodunu kullanabilirsiniz:
              </p>

              <div class="code-box">
                <div style="font-size: 11px; font-weight: 700; color: #64748B; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px;">Doğrulama Kodu</div>
                <h2 class="code-number">$code</h2>
              </div>

              <p style="font-size: 13px; color: #71717A; border-top: 1px solid #F4F4F5; padding-top: 24px;">
                Eğer bu talebi siz yapmadıysanız, bu e-postayı güvenle görmezden gelebilirsiniz. 
              </p>
            </div>
          </div>
          <p style="text-align: center; font-size: 12px; color: #A1A1AA; margin-top: 24px;">
            © 2026 Puantaj. Tüm hakları saklıdır.
          </p>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>
''';
  }
}
