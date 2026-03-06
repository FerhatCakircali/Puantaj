import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseQueryBuilder utility sınıfı - Standartlaştırılmış Supabase sorguları.
///
/// Bu utility, Supabase sorgu pattern'lerini merkezi bir noktada toplar ve
/// kod tekrarını önler. Güvenli ve tutarlı sorgu oluşturma metodları sağlar.
///
/// **Özellikler:**
/// - User ID bazlı filtreleme
/// - Tarih aralığı sorguları
/// - Pagination desteği
/// - Güvenli null kontrolleri
///
/// **Kullanım Örnekleri:**
/// ```dart
/// // User ID ile filtreleme
/// final query = SupabaseQueryBuilder.forUser(
///   supabase.from('workers'),
///   userId,
/// );
///
/// // Tarih aralığı sorgusu
/// final query = SupabaseQueryBuilder.dateRange(
///   supabase.from('payments'),
///   'payment_date',
///   startDate,
///   endDate,
/// );
/// ```
///
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class SupabaseQueryBuilder {
  SupabaseQueryBuilder._();

  /// Belirtilen tablo için user_id bazlı sorgu oluşturur.
  ///
  /// Bu metod, user_id ile filtreleme yapan standart bir sorgu pattern'i sağlar.
  /// Null userId kontrolü yapar ve güvenli sorgu oluşturur.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder (örn: supabase.from('workers'))
  /// - [userId]: Filtrelenecek kullanıcı ID'si
  /// - [additionalSelect]: Ek select alanları (opsiyonel, varsayılan: '*')
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.forUser(
  ///   supabase.from('workers'),
  ///   userId,
  ///   additionalSelect: '*, username',
  /// );
  /// final results = await query.order('full_name');
  /// ```
  ///
  /// Throws [ArgumentError] eğer userId null ise.
  static PostgrestFilterBuilder forUser(
    PostgrestQueryBuilder queryBuilder,
    String? userId, {
    String additionalSelect = '*',
  }) {
    if (userId == null) {
      throw ArgumentError('userId null olamaz');
    }

    return queryBuilder.select(additionalSelect).eq('user_id', userId);
  }

  /// Tarih aralığı sorgusu oluşturur (gte ve lte kullanarak).
  ///
  /// Bu metod, belirtilen tarih alanı için başlangıç ve bitiş tarihleri
  /// arasında filtreleme yapar. ISO 8601 formatı (YYYY-MM-DD) kullanır.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [dateField]: Tarih alanının adı (örn: 'payment_date', 'expense_date')
  /// - [startDate]: Başlangıç tarihi (ISO 8601 formatı)
  /// - [endDate]: Bitiş tarihi (ISO 8601 formatı)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.dateRange(
  ///   supabase.from('payments').select().eq('user_id', userId),
  ///   'payment_date',
  ///   '2024-01-01',
  ///   '2024-12-31',
  /// );
  /// final results = await query;
  /// ```
  static PostgrestFilterBuilder dateRange(
    PostgrestFilterBuilder queryBuilder,
    String dateField,
    String startDate,
    String endDate,
  ) {
    return queryBuilder.gte(dateField, startDate).lte(dateField, endDate);
  }

  /// Tarih aralığı sorgusu oluşturur (DateTime nesneleri ile).
  ///
  /// Bu metod, DateTime nesnelerini otomatik olarak ISO 8601 formatına
  /// çevirir ve tarih aralığı sorgusu oluşturur.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [dateField]: Tarih alanının adı
  /// - [startDate]: Başlangıç tarihi (DateTime)
  /// - [endDate]: Bitiş tarihi (DateTime)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.dateRangeFromDateTime(
  ///   supabase.from('payments').select().eq('user_id', userId),
  ///   'payment_date',
  ///   DateTime(2024, 1, 1),
  ///   DateTime(2024, 12, 31),
  /// );
  /// ```
  static PostgrestFilterBuilder dateRangeFromDateTime(
    PostgrestFilterBuilder queryBuilder,
    String dateField,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startDateStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDateStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    return dateRange(queryBuilder, dateField, startDateStr, endDateStr);
  }

  /// Pagination desteği ile sorgu oluşturur.
  ///
  /// Bu metod, sayfalama için limit ve offset parametreleri ekler.
  /// Büyük veri setlerinde performans için kullanışlıdır.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [page]: Sayfa numarası (0'dan başlar)
  /// - [pageSize]: Sayfa başına kayıt sayısı (varsayılan: 20)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.paginate(
  ///   supabase.from('workers').select().eq('user_id', userId),
  ///   page: 0,
  ///   pageSize: 50,
  /// );
  /// final results = await query.order('full_name');
  /// ```
  static PostgrestTransformBuilder paginate(
    PostgrestFilterBuilder queryBuilder, {
    required int page,
    int pageSize = 20,
  }) {
    final offset = page * pageSize;
    return queryBuilder.range(offset, offset + pageSize - 1);
  }

  /// Belirli bir tarihten önceki kayıtları sorgular.
  ///
  /// Bu metod, belirtilen tarih alanı için verilen tarihten önceki
  /// kayıtları filtreler (lt - less than).
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [dateField]: Tarih alanının adı
  /// - [date]: Referans tarihi (ISO 8601 formatı)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.beforeDate(
  ///   supabase.from('attendance').select().eq('user_id', userId),
  ///   'date',
  ///   '2024-01-01',
  /// );
  /// ```
  static PostgrestFilterBuilder beforeDate(
    PostgrestFilterBuilder queryBuilder,
    String dateField,
    String date,
  ) {
    return queryBuilder.lt(dateField, date);
  }

  /// Belirli bir tarihten sonraki kayıtları sorgular.
  ///
  /// Bu metod, belirtilen tarih alanı için verilen tarihten sonraki
  /// kayıtları filtreler (gt - greater than).
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [dateField]: Tarih alanının adı
  /// - [date]: Referans tarihi (ISO 8601 formatı)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.afterDate(
  ///   supabase.from('attendance').select().eq('user_id', userId),
  ///   'date',
  ///   '2024-01-01',
  /// );
  /// ```
  static PostgrestFilterBuilder afterDate(
    PostgrestFilterBuilder queryBuilder,
    String dateField,
    String date,
  ) {
    return queryBuilder.gt(dateField, date);
  }

  /// Worker ID ile filtreleme yapar.
  ///
  /// Bu metod, worker_id alanı ile filtreleme yapan standart pattern sağlar.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [workerId]: Filtrelenecek worker ID'si
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.forWorker(
  ///   supabase.from('attendance').select().eq('user_id', userId),
  ///   workerId,
  /// );
  /// ```
  ///
  /// Throws [ArgumentError] eğer workerId null ise.
  static PostgrestFilterBuilder forWorker(
    PostgrestFilterBuilder queryBuilder,
    int? workerId,
  ) {
    if (workerId == null) {
      throw ArgumentError('workerId null olamaz');
    }

    return queryBuilder.eq('worker_id', workerId);
  }

  /// Arama sorgusu oluşturur (case-insensitive).
  ///
  /// Bu metod, belirtilen alanda case-insensitive arama yapar.
  /// ILIKE operatörü kullanır (PostgreSQL).
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [field]: Aranacak alan adı
  /// - [searchTerm]: Arama terimi
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.search(
  ///   supabase.from('workers').select().eq('user_id', userId),
  ///   'full_name',
  ///   'ahmet',
  /// );
  /// ```
  static PostgrestFilterBuilder search(
    PostgrestFilterBuilder queryBuilder,
    String field,
    String searchTerm,
  ) {
    return queryBuilder.ilike(field, '%$searchTerm%');
  }

  /// Sıralama ekler.
  ///
  /// Bu metod, sonuçları belirtilen alana göre sıralar.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [field]: Sıralanacak alan adı
  /// - [ascending]: Artan sıralama (varsayılan: true)
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.orderBy(
  ///   supabase.from('workers').select().eq('user_id', userId),
  ///   'full_name',
  ///   ascending: true,
  /// );
  /// ```
  static PostgrestTransformBuilder orderBy(
    PostgrestFilterBuilder queryBuilder,
    String field, {
    bool ascending = true,
  }) {
    return queryBuilder.order(field, ascending: ascending);
  }

  /// Limit ekler (maksimum kayıt sayısı).
  ///
  /// Bu metod, döndürülecek maksimum kayıt sayısını belirler.
  ///
  /// Parametreler:
  /// - [queryBuilder]: Supabase query builder
  /// - [count]: Maksimum kayıt sayısı
  ///
  /// Örnek:
  /// ```dart
  /// final query = SupabaseQueryBuilder.limit(
  ///   supabase.from('workers').select().eq('user_id', userId),
  ///   10,
  /// );
  /// ```
  static PostgrestTransformBuilder limit(
    PostgrestFilterBuilder queryBuilder,
    int count,
  ) {
    return queryBuilder.limit(count);
  }
}
