import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/employee.dart';
import '../models/attendance.dart' as attendance;
import '../services/attendance_service.dart';
import '../services/worker_service.dart';
import '../services/payment_service.dart';
import '../widgets/employee_details_dialog.dart';
import 'package:puantaj/services/report_service.dart';
import 'package:puantaj/services/pdf_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:puantaj/models/payment.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final WorkerService _workerService = WorkerService();
  final AttendanceService _attendanceService = AttendanceService();
  final PaymentService _paymentService = PaymentService();
  final PdfService _pdfService = PdfService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<Employee> _employees = [];
  bool _isLoading = true;

  // Dönemsel rapor parametreleri
  ReportPeriod _selectedPeriodType = ReportPeriod.monthly;
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();
  bool _isEmployeeSpecific = false;
  Employee? _selectedEmployee;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  List<Employee> _filteredEmployees = [];

  // Önceki raporlar için state değişkenleri
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<int, List<attendance.Attendance>> _attendanceMap = {};
  Map<int, Map<String, dynamic>> _statsMap = {};
  final TextEditingController _searchController = TextEditingController();

  // Tab Controller
  late TabController _tabController;

  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadData();
    _tabController = TabController(length: 2, vsync: this);
    _filteredEmployees = _employees;
    _initializeNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _employeeSearchController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);

    try {
      final employees = await _workerService.getEmployees();

      setState(() {
        _employees = employees;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Önceki aramayı temizle
    _searchController.clear();

    final allEmployees = await _workerService.getEmployees();
    final allAttendance = await _attendanceService.getAttendanceBetween(
      _startDate,
      _endDate,
    );

    final attendanceMap = <int, List<attendance.Attendance>>{};
    final activeWorkerIds = <int>{};

    // Devam kayıtlarını işle ve aktif çalışan ID'lerini topla
    for (var record in allAttendance) {
      attendanceMap.putIfAbsent(record.workerId, () => []).add(record);
      activeWorkerIds.add(record.workerId);
    }

    // Sadece seçilen tarih aralığında kaydı olan çalışanları filtrele
    final activeEmployees = allEmployees
        .where((emp) => activeWorkerIds.contains(emp.id))
        .toList();

    final statsMap = <int, Map<String, dynamic>>{};
    for (var emp in activeEmployees) {
      final records = attendanceMap[emp.id] ?? [];
      statsMap[emp.id] = await _calculateAttendanceStats(emp, records);
    }

    // Çalışanları isme göre A'dan Z'ye sırala
    activeEmployees.sort((a, b) => collateTurkish(a.name, b.name));

    setState(() {
      _filteredEmployees = activeEmployees;
      _attendanceMap = attendanceMap;
      _statsMap = statsMap;
      _isLoading = false;
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((employee) {
          if (employee == null) return false;
          final name = employee.name ?? '';
          final title = employee.title ?? '';
          final lowerCaseQuery = query.toLowerCase();

          return name.toLowerCase().contains(lowerCaseQuery) ||
              title.toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }
    });
  }

  Future<Map<String, dynamic>> _calculateAttendanceStats(
    Employee emp,
    List<attendance.Attendance> records,
  ) async {
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;

    // Giriş tarihinden seçili bitiş tarihine kadar olan tüm günleri kontrol et
    DateTime currentDate = emp.startDate.isAfter(_startDate)
        ? emp.startDate
        : _startDate;
    while (!currentDate.isAfter(_endDate)) {
      // O güne ait yevmiye kaydı var mı kontrol et
      final record = records.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse: () => attendance.Attendance(
          userId: 0,
          workerId: emp.id,
          date: currentDate,
          status: attendance.AttendanceStatus.absent,
        ),
      );

      switch (record.status) {
        case attendance.AttendanceStatus.fullDay:
          fullDays++;
          break;
        case attendance.AttendanceStatus.halfDay:
          halfDays++;
          break;
        case attendance.AttendanceStatus.absent:
          absentDays++;
          break;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Ödenmemiş günleri al
    final unpaidDays = await _paymentService.getUnpaidDays(emp.id);

    return {
      'fullDays': fullDays,
      'halfDays': halfDays,
      'absentDays': absentDays,
      'unpaidFullDays': unpaidDays['fullDays'] ?? 0,
      'unpaidHalfDays': unpaidDays['halfDays'] ?? 0,
    };
  }

  void _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _isLoading = true;
        _searchController.clear(); // Tarih aralığı değiştiğinde aramayı temizle
      });
      await _loadData();
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeDetailsDialog(
        employee: employee,
        onPaymentComplete: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _createEmployeeReport() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışanları yüklemek için önce çalışanları yükleyin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _progressNotifier.value = 0;

    try {
      final attendances = await _attendanceService.getAttendanceBetween(
        _employees.first.startDate,
        DateTime.now(),
        workerId: _employees.first.id,
      );
      final payments = await _paymentService.getPaymentsByWorkerId(
        _employees.first.id,
      );
      final file = await (() async {
        final filePath = await compute(_generateEmployeeReportInIsolate, {
          'employee': _employees.first.toMap(),
          'attendances': attendances.map((a) => a.toMap()).toList(),
          'payments': payments.map((p) => p.toMap()).toList(),
        });
        return File(filePath);
      })();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Rapor oluşturuldu: ${file.path}')),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: 'Paylaş',
                  onPressed: () => Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'PDF raporunu paylaşıyorum.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'AÇ',
              onPressed: () => _pdfService.openPdf(file),
            ),
          ),
        );
        await _showReportNotification(file, 'Çalışan Raporu');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor oluşturma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _progressNotifier.value = 1.0;
      }
    }
  }

  static Future<String> _generateEmployeeReportInIsolate(
    Map<String, dynamic> args,
  ) async {
    final employee = Employee.fromMap(
      Map<String, dynamic>.from(args['employee']),
    );
    final attendances = (args['attendances'] as List)
        .map((a) => attendance.Attendance.fromMap(Map<String, dynamic>.from(a)))
        .toList();
    final payments = (args['payments'] as List)
        .map((p) => Payment.fromMap(Map<String, dynamic>.from(p)))
        .toList();
    final file = await PdfService().generateEmployeeReport(
      employee,
      attendances,
      payments,
    );
    return file.path;
  }

  // Dönemsel rapor oluşturma fonksiyonu
  Future<void> _createPeriodReport() async {
    setState(() => _isLoading = true);
    _progressNotifier.value = 0;

    try {
      print(
        "Dönemsel rapor oluşturma başlatıldı: ${_selectedPeriodType.toString()}",
      );

      // Parametreleri logla
      if (_selectedPeriodType == ReportPeriod.custom) {
        print(
          "Özel tarih aralığı: ${DateFormat('dd/MM/yyyy').format(_customStartDate)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate)}",
        );
      }

      // Rapor başlığını oluştur
      String periodTitleText;
      switch (_selectedPeriodType) {
        case ReportPeriod.daily:
          periodTitleText = 'Günlük Rapor';
          break;
        case ReportPeriod.weekly:
          periodTitleText = 'Haftalık Rapor';
          break;
        case ReportPeriod.monthly:
          periodTitleText = 'Aylık Rapor';
          break;
        case ReportPeriod.yearly:
          periodTitleText = 'Yıllık Rapor';
          break;
        case ReportPeriod.custom:
          periodTitleText = 'Özel Dönem Raporu';
          break;
        case ReportPeriod.quarterly:
          periodTitleText = 'Üç Aylık Rapor';
          break;
      }

      // Çalışan adını başlığa ekle
      final periodTitle = _isEmployeeSpecific && _selectedEmployee != null
          ? '${_selectedEmployee!.name} - $periodTitleText'
          : periodTitleText;

      final outputDir = (await getTemporaryDirectory()).path;
      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();
      final file = _isEmployeeSpecific
          ? await (() async {
              _progressNotifier.value = 0;
              final file = await _pdfService
                  .generatePeriodEmployeeReportWithProgress(
                    employee: _selectedEmployee!,
                    periodStart: _customStartDate,
                    periodEnd: _customEndDate,
                    attendances: await _attendanceService.getAttendanceBetween(
                      _selectedEmployee!.startDate,
                      _customEndDate,
                      workerId: _selectedEmployee!.id,
                    ),
                    payments: await _paymentService.getPaymentsByWorkerId(
                      _selectedEmployee!.id,
                    ),
                    periodTitle: periodTitle,
                    progressCallback: (progress) =>
                        _progressNotifier.value = progress,
                    outputDirectory: outputDir,
                  );
              return file;
            })()
          : await (() async {
              final filePath =
                  await compute(_generatePeriodGeneralReportInIsolate, {
                    'periodTitle': periodTitle,
                    'periodStart': _customStartDate.toIso8601String(),
                    'periodEnd': _customEndDate.toIso8601String(),
                    'employees': _employees.map((e) => e.toMap()).toList(),
                    'allAttendances': await Future.wait(
                      _employees.map(
                        (emp) async =>
                            (await _attendanceService.getAttendanceBetween(
                              emp.startDate,
                              _customEndDate,
                              workerId: emp.id,
                            )).map((a) => a.toMap()).toList(),
                      ),
                    ),
                    'allPayments': await Future.wait(
                      _employees.map(
                        (emp) async =>
                            (await _paymentService.getPaymentsByWorkerId(
                              emp.id,
                            )).map((p) => p.toMap()).toList(),
                      ),
                    ),
                    'outputDirectory': outputDir,
                    'robotoFontBytes': robotoFontBytes,
                    'robotoBoldFontBytes': robotoBoldFontBytes,
                  });
              return File(filePath);
            })();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Rapor oluşturuldu')),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: 'Paylaş',
                  onPressed: () => Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'PDF raporunu paylaşıyorum.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'AÇ',
              onPressed: () => _pdfService.openPdf(file),
            ),
          ),
        );
        await _showReportNotification(file, 'Dönemsel Rapor');
      }
    } catch (e, stackTrace) {
      print("Dönemsel rapor oluşturma hatası: $e");
      print("Hata detayı: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rapor oluşturma hatası:\n${e.toString().split('.').first}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'TAMAM',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _progressNotifier.value = 1.0;
      }
    }
  }

  // Özel tarih seçici
  Future<void> _selectCustomDate(bool isStartDate) async {
    final DateTime initialDate = isStartDate
        ? _customStartDate
        : _customEndDate;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = selectedDate;
          // Başlangıç tarihi bitiş tarihinden sonra olamaz
          if (_customStartDate.isAfter(_customEndDate)) {
            _customEndDate = _customStartDate;
          }
        } else {
          _customEndDate = selectedDate;
          // Bitiş tarihi başlangıç tarihinden önce olamaz
          if (_customEndDate.isBefore(_customStartDate)) {
            _customStartDate = _customEndDate;
          }
        }
      });
    }
  }

  void _updatePeriodDates(ReportPeriod period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case ReportPeriod.daily:
        startDate = now;
        break;
      case ReportPeriod.weekly:
        // Bugünden 7 gün öncesini al
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        // Bugünden 30 gün öncesini al
        startDate = now.subtract(const Duration(days: 30));
        break;
      case ReportPeriod.quarterly:
        // Bugünden 90 gün öncesini al
        startDate = now.subtract(const Duration(days: 90));
        break;
      case ReportPeriod.yearly:
        // Bugünden 365 gün öncesini al
        startDate = now.subtract(const Duration(days: 365));
        break;
      case ReportPeriod.custom:
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
    }

    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate;
    });
  }

  Future<void> _showReportNotification(File file, String title) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pdf_report_channel',
          'PDF Raporları',
          channelDescription: 'Oluşturulan PDF raporları için bildirimler',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notifications.show(
      0,
      title,
      'Rapor hazır! Açmak için tıklayın.',
      platformChannelSpecifics,
      payload: file.path,
    );
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          await _pdfService.openPdf(File(payload));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: _progressNotifier,
                    builder: (context, value, child) {
                      if (value == 0 || value == 1.0)
                        return const SizedBox.shrink();
                      return Column(
                        children: [
                          LinearProgressIndicator(value: value),
                          const SizedBox(height: 8),
                          Text(
                            'Rapor hazırlanıyor: %${(value * 100).toStringAsFixed(0)}',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.person), text: 'Çalışan Raporu'),
                    Tab(
                      icon: Icon(Icons.calendar_month),
                      text: 'Dönemsel Rapor',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmployeeReportTab(padding),
                      _buildPeriodReportTab(padding),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Çalışan raporu sekmesi
  Widget _buildEmployeeReportTab(double padding) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedStartDate = dateFormat.format(_startDate);
    final formattedEndDate = dateFormat.format(_endDate);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.people, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Çalışanlar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _selectDateRange,
                  tooltip: 'Tarih Aralığı Seç',
                ),
                const SizedBox(width: 8),
                Text(
                  'Tarih Aralığı: $formattedStartDate - $formattedEndDate',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Çalışan ara...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
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
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterEmployees('');
                        },
                      )
                    : null,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: _filterEmployees,
            ),
            const SizedBox(height: 16),
            if (_filteredEmployees.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 56,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Arama sonucu bulunamadı.',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              )
            else
              Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredEmployees.length,
                  separatorBuilder: (context, i) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final emp = _filteredEmployees[index];
                    final records = _attendanceMap[emp.id] ?? [];
                    final stats = _statsMap[emp.id] ?? {};
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showEmployeeDetails(emp),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.name,
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (emp.title.isNotEmpty)
                                        Text(
                                          emp.title,
                                          style: TextStyle(
                                            fontSize: fontSize * 0.9,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  label: Text(
                                    'Tam Gün: ${stats['fullDays'] ?? 0}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.08),
                                ),
                                Chip(
                                  label: Text(
                                    'Yarım Gün: ${stats['halfDays'] ?? 0}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.08),
                                ),
                                Chip(
                                  label: Text(
                                    'Gelmedi: ${stats['absentDays'] ?? 0}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                ),
                              ],
                            ),
                            if ((stats['unpaidFullDays'] ?? 0) > 0 ||
                                (stats['unpaidHalfDays'] ?? 0) > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      size: 18,
                                    ),
                                    Text(
                                      'Ödenmemiş Maaş Gün Sayısı:',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.9,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${stats['unpaidFullDays'] ?? 0} Tam | ${stats['unpaidHalfDays'] ?? 0} Yarım',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.9,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
    );
  }

  // Dönemsel rapor sekmesi
  Widget _buildPeriodReportTab(double padding) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_month, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Dönemsel Rapor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReportPeriod>(
                      decoration: InputDecoration(
                        labelText: 'Rapor Dönemi',
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
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      value: _selectedPeriodType,
                      items: ReportPeriod.values.map((period) {
                        final labels = {
                          ReportPeriod.daily: 'Günlük',
                          ReportPeriod.weekly: 'Haftalık',
                          ReportPeriod.monthly: 'Aylık',
                          ReportPeriod.quarterly: 'Üç Aylık',
                          ReportPeriod.yearly: 'Yıllık',
                          ReportPeriod.custom: 'Özel Tarih Aralığı',
                        };
                        return DropdownMenuItem(
                          value: period,
                          child: Text(labels[period] ?? period.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPeriodType = value;
                          });
                          _updatePeriodDates(value);
                        }
                      },
                    ),
                    if (_selectedPeriodType == ReportPeriod.custom) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Başlangıç: ${DateFormat('dd/MM/yyyy').format(_customStartDate)}',
                              ),
                              onPressed: () => _selectCustomDate(true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Bitiş: ${DateFormat('dd/MM/yyyy').format(_customEndDate)}',
                              ),
                              onPressed: () => _selectCustomDate(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Çalışan için dönemlik rapor'),
                      value: _isEmployeeSpecific,
                      onChanged: (value) {
                        setState(() {
                          _isEmployeeSpecific = value ?? false;
                          if (!_isEmployeeSpecific) {
                            _selectedEmployee = null;
                          }
                        });
                      },
                    ),
                    if (_isEmployeeSpecific) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _employeeSearchController,
                        decoration: InputDecoration(
                          labelText: 'Çalışan Ara',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                          ),
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
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).inputDecorationTheme.fillColor,
                          suffixIcon: _employeeSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _employeeSearchController.clear();
                                    _filterEmployees('');
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onChanged: _filterEmployees,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = _filteredEmployees[index];
                                return Card(
                                  elevation: 2.0,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    title: Text(employee.name),
                                    subtitle: Text(employee.title),
                                    selected:
                                        _selectedEmployee?.id == employee.id,
                                    onTap: () {
                                      setState(() {
                                        _selectedEmployee = employee;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Dönemsel Rapor Oluştur'),
                        onPressed:
                            _isEmployeeSpecific && _selectedEmployee == null
                            ? null
                            : _createPeriodReport,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String> _generatePeriodGeneralReportInIsolate(
    Map<String, dynamic> args,
  ) async {
    final periodTitle = args['periodTitle'] as String;
    final periodStart = DateTime.parse(args['periodStart'] as String);
    final periodEnd = DateTime.parse(args['periodEnd'] as String);
    final employees = (args['employees'] as List)
        .map((e) => Employee.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final allAttendances = (args['allAttendances'] as List)
        .map(
          (list) => (list as List)
              .map(
                (a) =>
                    attendance.Attendance.fromMap(Map<String, dynamic>.from(a)),
              )
              .toList(),
        )
        .toList();
    final allPayments = (args['allPayments'] as List)
        .map(
          (list) => (list as List)
              .map((p) => Payment.fromMap(Map<String, dynamic>.from(p)))
              .toList(),
        )
        .toList();
    final outputDirectory = args['outputDirectory'] as String?;
    final robotoFontBytes = args['robotoFontBytes'] as Uint8List;
    final robotoBoldFontBytes = args['robotoBoldFontBytes'] as Uint8List;
    final file = await PdfService().generatePeriodGeneralReport(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );
    return file.path;
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
}
