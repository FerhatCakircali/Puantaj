import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart' as attendance;
import '../models/employee.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import '../services/payment_service.dart';
import '../services/attendance_check.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  Map<int, attendance.Attendance> _attendanceMap = {};
  Map<int, attendance.AttendanceStatus> _pendingChanges = {};
  bool _isLoading = true;
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int collateTurkish(String a, String b) {
    const turkishAlphabet = [
      'a',
      'b',
      'c',
      'ç',
      'd',
      'e',
      'f',
      'g',
      'ğ',
      'h',
      'ı',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'ö',
      'p',
      'r',
      's',
      'ş',
      't',
      'u',
      'ü',
      'v',
      'y',
      'z',
    ];
    final Map<String, int> alphabetOrder = {
      for (var i = 0; i < turkishAlphabet.length; i++) turkishAlphabet[i]: i,
    };

    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');

    final na = normalize(a);
    final nb = normalize(b);

    final minLen = na.length < nb.length ? na.length : nb.length;
    for (var i = 0; i < minLen; i++) {
      final ca = na[i];
      final cb = nb[i];
      final ia = alphabetOrder[ca] ?? -1;
      final ib = alphabetOrder[cb] ?? -1;
      if (ia != ib) {
        return ia.compareTo(ib);
      }
    }
    return na.length.compareTo(nb.length);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Tüm çalışanları al
      final allEmployees = await EmployeeService().getEmployees();

      // Seçili tarihe ait devam kayıtlarını al
      final allAttendance = await AttendanceService().getAttendanceByDate(
        _selectedDate,
      );

      // Çalışanları isme göre A'dan Z'ye sırala
      allEmployees.sort((a, b) => collateTurkish(a.name, b.name));

      // Sadece seçili tarihte veya daha önce işe başlamış olanları filtrele
      final filteredEmployees =
          allEmployees
              .where((e) => !e.startDate.isAfter(_selectedDate))
              .toList();

      if (mounted) {
        setState(() {
          _employees = filteredEmployees;
          _filteredEmployees = filteredEmployees;
          _attendanceMap = {
            for (var record in allAttendance) record.workerId: record,
          };
          _pendingChanges.clear();
          _isLoading = false;
        });
      }

      print('Tarih: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
      print('Toplam çalışan sayısı: ${allEmployees.length}');
      print(
        'İşe başlama tarihine göre filtrelenmiş çalışan sayısı: ${filteredEmployees.length}',
      );
      print('Devam kaydı sayısı: ${allAttendance.length}');
    } catch (e, stackTrace) {
      print('Çalışan verileri yüklenirken hata oluştu: $e');
      print('Hata ayrıntıları: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees =
            _employees
                .where(
                  (employee) =>
                      employee.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (pickedDate != null) {
      // Aynı tarih seçilmiş olsa bile yeniden yükle
      setState(() {
        _selectedDate = pickedDate;
        _isLoading = true;
        _pendingChanges.clear();
        _searchController.clear(); // Tarih değiştiğinde aramayı temizle
      });
      await _loadData();
    }
  }

  // Önceki güne gitme metodu
  void _goToPreviousDay() async {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = newDate;
      _isLoading = true;
      _pendingChanges.clear();
      _searchController.clear(); // Aramayı temizle
    });
    await _loadData();
  }

  // Sonraki güne gitme metodu
  void _goToNextDay() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_selectedDate.isBefore(todayDate)) {
      final newDate = _selectedDate.add(const Duration(days: 1));
      setState(() {
        _selectedDate = newDate;
        _isLoading = true;
        _pendingChanges.clear();
        _searchController.clear(); // Aramayı temizle
      });
      await _loadData();
    } else if (_selectedDate.isAtSameMomentAs(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugünden sonraki tarihlere geçilemez'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      for (final entry in _pendingChanges.entries) {
        await AttendanceService().markAttendance(
          workerId: entry.key,
          date: _selectedDate,
          status: entry.value,
        );
      }

      // Bugün için yevmiye girişi yapıldığını işaretle
      final today = DateTime.now();
      final selectedToday = DateTime(today.year, today.month, today.day);
      final selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      // Eğer bugünün yevmiye kaydı yapılıyorsa, bildirim durumunu güncelle
      if (selectedDate.isAtSameMomentAs(selectedToday)) {
        print('Bugünün yevmiye kaydı yapıldı, bildirim durumunu güncelliyorum');

        // Bugünün bildirim durumunu güncelle
        await AttendanceCheck.markAttendanceDone();

        // Bildirim servisinden de bildirim durumunu temizle
        final notificationService = NotificationService();
        await notificationService.clearAllNotifications();

        // Kullanıcıya özel yevmiye durumunu SharedPreferences'a da kaydet
        final userId = await notificationService.getCurrentUserId();
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          final userAttendanceKey = 'attendance_date_user_$userId';
          await prefs.setString(userAttendanceKey, today.toIso8601String());
          print(
            'Kullanıcıya özel yevmiye durumu kaydedildi: $userAttendanceKey',
          );
        }

        print('Bildirim durumu güncellendi');
      }

      await _loadData();
    } catch (e) {
      print('Yevmiye kaydetme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeStatus(
    int workerId,
    attendance.AttendanceStatus value,
  ) async {
    // Çalışanı bul
    final employee = _employees.firstWhere((e) => e.id == workerId);

    // İşe başlama tarihinden önceki tarihlerde değişiklik yapılmasını engelle
    if (_selectedDate.isBefore(employee.startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name} işe başlama tarihinden (${DateFormat('dd/MM/yyyy').format(employee.startDate)}) önceki tarihlerde yevmiye girişi yapılamaz.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mevcut durumu al
    final currentStatus =
        _pendingChanges[workerId] ??
        _attendanceMap[workerId]?.status ??
        attendance.AttendanceStatus.absent;

    // Eğer durum değişiyorsa ve mevcut durum ödenmişse, uyarı göster
    if (currentStatus != value) {
      final isPaid = await _paymentService.isDayPaid(
        workerId,
        _selectedDate,
        currentStatus,
      );

      if (isPaid) {
        // Durum değişikliğine izin verme ve kullanıcıya uyarı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu gün için ödeme yapılmış, durum değiştirilemez!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Durum değişikliğini kaydet
    setState(() {
      _pendingChanges[workerId] = value;
    });

    // Bugünün yevmiyesinin değiştiğini kontrol et
    final today = DateTime.now();
    final selectedToday = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // Eğer bugünün yevmiye kaydı yapılıyorsa, hemen bildirim durumunu güncelle
    if (selectedDate.isAtSameMomentAs(selectedToday)) {
      print(
        'Bugünün yevmiye durumu değiştirildi, bildirim durumunu hemen güncelliyorum',
      );

      try {
        // 1. Bugünün bildirim durumunu güncelle (herhangi bir çalışan değiştirildiğinde)
        await AttendanceCheck.markAttendanceDone();
        print('AttendanceCheck.markAttendanceDone() başarıyla çalıştı');

        // 2. Bildirim servisinden bildirim durumunu temizle
        final notificationService = NotificationService();
        await notificationService.clearAllNotifications();
        print('notificationService.clearAllNotifications() başarıyla çalıştı');

        // 3. Doğrudan SharedPreferences üzerinden bugün için bildirim gönderildi olarak işaretle
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String todayKey =
            'notification_sent_${today.year}_${today.month}_${today.day}';
        await prefs.setBool(todayKey, true);
        print('SharedPreferences üzerinde $todayKey = true olarak ayarlandı');

        // 4. Kullanıcıya özel yevmiye durumunu güncelle
        final userId = await notificationService.getCurrentUserId();
        if (userId != null) {
          final userAttendanceKey = 'attendance_date_user_$userId';
          await prefs.setString(userAttendanceKey, today.toIso8601String());
          print(
            'Kullanıcıya özel yevmiye durumu güncellendi: $userAttendanceKey',
          );
        }

        // 5. Tüm zamanlanmış bildirimleri iptal et
        await notificationService.flutterLocalNotificationsPlugin.cancelAll();
        print('Tüm zamanlanmış bildirimler iptal edildi');

        print(
          'Bildirim durumu başarıyla güncellendi (çalışan durumu değiştirme)',
        );

        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bugünün yevmiye girişi yapıldı olarak işaretlendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Bildirim durumu güncellenirken hata: $e');
        // Hata olursa da kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim durumu güncellenirken hata: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 22.0 : 16.0;
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      // Tarih gösterimi - her zaman gösterilecek
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Sol taraf - önceki gün butonu ve takvim ikonu
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _goToPreviousDay,
                                      tooltip: 'Önceki Gün',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 22,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.calendar_today,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),

                                // Orta - tarih seçici
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: fontSize * 0.85,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Sağ taraf - sonraki gün butonu ve kaydet butonu
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: _goToNextDay,
                                      tooltip: 'Sonraki Gün',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 22,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (_pendingChanges.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.save),
                                        tooltip: 'Değişiklikleri Kaydet',
                                        onPressed: _saveChanges,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 22,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Çalışan yoksa mesaj göster
                      if (_employees.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz çalışan eklenmemiş.',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Çalışanlar varsa liste göster
                      else
                        Expanded(
                          child: Column(
                            children: [
                              // Arama kutusu
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Çalışan ara...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.7),
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(
                                      0xFFF5F6FA,
                                    ), // Raporlar sayfası ile aynı arka plan rengi
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                                _filterEmployees('');
                                              },
                                            )
                                            : null,
                                  ),
                                  style: const TextStyle(color: Colors.black),
                                  onChanged: _filterEmployees,
                                ),
                              ),
                              Expanded(
                                child:
                                    _filteredEmployees.isEmpty
                                        ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.search_off,
                                                size: 56,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Arama sonucu bulunamadı.',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        : ListView.separated(
                                          itemCount: _filteredEmployees.length,
                                          separatorBuilder:
                                              (context, i) =>
                                                  const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final emp =
                                                _filteredEmployees[index];
                                            final currentStatus =
                                                _pendingChanges[emp.id] ??
                                                _attendanceMap[emp.id]
                                                    ?.status ??
                                                attendance
                                                    .AttendanceStatus
                                                    .absent;
                                            return Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor: Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                          .withOpacity(
                                                            Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? 0.22
                                                                : 0.12,
                                                          ),
                                                      child: Text(
                                                        emp.name.isNotEmpty
                                                            ? emp.name[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(
                                                                        context,
                                                                      ).brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            emp.name,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  fontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                          if (emp
                                                              .title
                                                              .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 2,
                                                                  ),
                                                              child: Text(
                                                                emp.title,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      fontSize *
                                                                      0.85,
                                                                  color:
                                                                      Theme.of(
                                                                                context,
                                                                              ).brightness ==
                                                                              Brightness.dark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          // İşe başlama tarihinden önce ise uyarı göster
                                                          if (_selectedDate
                                                              .isBefore(
                                                                emp.startDate,
                                                              ))
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .warning_amber_rounded,
                                                                    color:
                                                                        Colors
                                                                            .orange,
                                                                    size: 14,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 2,
                                                                  ),
                                                                  Flexible(
                                                                    child: Text(
                                                                      'İşe başlama: ${DateFormat('dd/MM/yyyy').format(emp.startDate)}',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            fontSize *
                                                                            0.7,
                                                                        color:
                                                                            Colors.orange,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    DropdownButton<
                                                      attendance.AttendanceStatus
                                                    >(
                                                      value: currentStatus,
                                                      onChanged:
                                                          _selectedDate.isBefore(
                                                                emp.startDate,
                                                              )
                                                              ? null // İşe başlama tarihinden önce ise değiştirilemez
                                                              : (
                                                                attendance.AttendanceStatus?
                                                                value,
                                                              ) {
                                                                if (value !=
                                                                    null) {
                                                                  _changeStatus(
                                                                    emp.id,
                                                                    value,
                                                                  );
                                                                }
                                                              },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      isDense: true,
                                                      icon: Icon(
                                                        Icons.arrow_drop_down,
                                                        size: 18,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            fontSize * 0.85,
                                                        color:
                                                            _selectedDate.isBefore(
                                                                  emp.startDate,
                                                                )
                                                                ? Colors
                                                                    .grey // İşe başlama tarihinden önce ise gri renk
                                                                : Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white
                                                                : Colors.black,
                                                      ),
                                                      underline:
                                                          const SizedBox(),
                                                      items: [
                                                        DropdownMenuItem<
                                                          attendance.AttendanceStatus
                                                        >(
                                                          value:
                                                              attendance
                                                                  .AttendanceStatus
                                                                  .absent,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.close,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Gelmedi',
                                                                style: TextStyle(
                                                                  color:
                                                                      Theme.of(
                                                                                context,
                                                                              ).brightness ==
                                                                              Brightness.dark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                  fontSize:
                                                                      fontSize *
                                                                      0.85,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        DropdownMenuItem<
                                                          attendance.AttendanceStatus
                                                        >(
                                                          value:
                                                              attendance
                                                                  .AttendanceStatus
                                                                  .fullDay,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Tam',
                                                                style: TextStyle(
                                                                  color:
                                                                      Theme.of(
                                                                                context,
                                                                              ).brightness ==
                                                                              Brightness.dark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                  fontSize:
                                                                      fontSize *
                                                                      0.85,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        DropdownMenuItem<
                                                          attendance.AttendanceStatus
                                                        >(
                                                          value:
                                                              attendance
                                                                  .AttendanceStatus
                                                                  .halfDay,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.adjust,
                                                                color:
                                                                    Theme.of(
                                                                              context,
                                                                            ).brightness ==
                                                                            Brightness.dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Yarım',
                                                                style: TextStyle(
                                                                  color:
                                                                      Theme.of(
                                                                                context,
                                                                              ).brightness ==
                                                                              Brightness.dark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                  fontSize:
                                                                      fontSize *
                                                                      0.85,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
