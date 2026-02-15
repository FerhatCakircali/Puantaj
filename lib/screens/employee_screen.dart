import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../services/worker_service.dart';
import '../services/pdf_service.dart';
import '../services/attendance_service.dart';
import '../services/payment_service.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  final WorkerService _workerService = WorkerService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Employee? _selectedEmployee;
  bool _isEditing = false;
  Employee _employee = Employee(
    id: 0,
    name: '',
    title: '',
    phone: '',
    startDate: DateTime.now(),
  );
  final AttendanceService _attendanceService = AttendanceService();
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _searchController = TextEditingController();
  List<Employee> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(() {
      _filterEmployees(_searchController.text);
    });
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

  Future<void> _loadEmployees() async {
    try {
      final employees = await _workerService.getEmployees();
      employees.sort((a, b) => collateTurkish(a.name, b.name));

      // Widget hala ağaçta ise setState çağır
      if (mounted) {
        setState(() {
          _employees = employees;
          _filteredEmployees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Çalışanlar yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterEmployees(String query) {
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where(
              (employee) =>
                  employee.name.toLowerCase().contains(query.toLowerCase()) ||
                  employee.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _showAddEmployeeDialog() {
    final _nameController = TextEditingController();
    final _titleController = TextEditingController();
    final _phoneController = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 16,
            right: 16,
            left: 16,
          ),
          title: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person_add_alt_1,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yeni Çalışan Ekle',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'İsim',
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
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Unvan',
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
                    prefixIcon: Icon(
                      Icons.work_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon',
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
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.02),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giriş Tarihi: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.edit_calendar, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _titleController.text.isEmpty ||
                    _phoneController.text.isEmpty) {
                  return;
                }
                await _workerService.addEmployee(
                  Employee(
                    id: 0,
                    name: _nameController.text.trim(),
                    title: _titleController.text.trim(),
                    phone: _phoneController.text.trim(),
                    startDate: _selectedDate,
                  ),
                );
                await _loadEmployees();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Ekle'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    final _nameController = TextEditingController(text: employee.name);
    final _titleController = TextEditingController(text: employee.title);
    final _phoneController = TextEditingController(text: employee.phone);
    DateTime _selectedDate = employee.startDate;
    bool _isStartDateChanged = false;
    bool _hasRecordsBeforeNewDate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 16,
            right: 16,
            left: 16,
          ),
          title: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.edit,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Çalışan Düzenle',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'İsim',
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
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Unvan',
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
                    prefixIcon: Icon(
                      Icons.work_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon',
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
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      // Eğer seçilen tarih değiştiyse kontrol yapmamız gerekecek
                      final isDateChanged =
                          pickedDate.day != employee.startDate.day ||
                          pickedDate.month != employee.startDate.month ||
                          pickedDate.year != employee.startDate.year;

                      if (isDateChanged) {
                        // Yeni tarih, mevcut tarihten sonra mı kontrol et
                        if (pickedDate.isAfter(employee.startDate)) {
                          final hasRecords = await _workerService
                              .hasRecordsBeforeDate(employee.id, pickedDate);

                          setState(() {
                            _selectedDate = pickedDate;
                            _isStartDateChanged = true;
                            _hasRecordsBeforeNewDate = hasRecords;
                          });

                          if (hasRecords) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'UYARI: Seçilen yeni giriş tarihinden önce bu çalışana ait kayıtlar mevcut. '
                                  'Değişikliği kaydetmeniz veri tutarsızlığına yol açabilir!',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            _selectedDate = pickedDate;
                            _isStartDateChanged = true;
                            _hasRecordsBeforeNewDate = false;
                          });
                        }
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.02),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giriş Tarihi: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.edit_calendar, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (_isStartDateChanged && _hasRecordsBeforeNewDate)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: Text(
                      'UYARI: Seçtiğiniz yeni giriş tarihinden önce bu çalışana ait devam kaydı veya ödeme kaydı bulunmaktadır. Giriş tarihini değiştirdiğinizde veri tutarsızlığı oluşabilir!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _titleController.text.isEmpty ||
                    _phoneController.text.isEmpty) {
                  return;
                }

                // Eğer giriş tarihi değişmişse ve önceki kayıtlar varsa, onay iste
                if (_isStartDateChanged && _hasRecordsBeforeNewDate) {
                  final shouldContinue =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Dikkat! Veri Kaybı Riski'),
                          content: Text(
                            '${employee.name} için seçtiğiniz yeni giriş tarihi (${DateFormat('dd/MM/yyyy').format(_selectedDate)}) öncesinde devam ve/veya ödeme kayıtları mevcut.\n\n'
                            'Devam ederseniz, bu tarihten önceki TÜM devam ve ödeme kayıtları SİLİNECEKTİR!\n\n'
                            'Bu işlem geri alınamaz. Emin misiniz?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Evet, Kayıtları Sil ve Devam Et',
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!shouldContinue) {
                    return; // Kullanıcı iptal etti
                  }

                  // Kullanıcı onayladığında tarihten önceki kayıtları siliyoruz
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                    });
                  }

                  try {
                    // Önce bu tarihten önceki tüm kayıtları sil
                    await _workerService.deleteRecordsBeforeDate(
                      employee.id,
                      _selectedDate,
                    );

                    // Sonra çalışan bilgilerini güncelle
                    await _workerService.updateEmployee(
                      Employee(
                        id: employee.id,
                        name: _nameController.text.trim(),
                        title: _titleController.text.trim(),
                        phone: _phoneController.text.trim(),
                        startDate: _selectedDate,
                      ),
                    );

                    await _loadEmployees();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Çalışan bilgileri güncellendi. ${DateFormat('dd/MM/yyyy').format(_selectedDate)} tarihinden önceki kayıtlar silindi.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('İşlem sırasında bir hata oluştu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                } else {
                  // Normal güncelleme (tarih değişikliği yok veya güvenli bir değişiklik)
                  await _workerService.updateEmployee(
                    Employee(
                      id: employee.id,
                      name: _nameController.text.trim(),
                      title: _titleController.text.trim(),
                      phone: _phoneController.text.trim(),
                      startDate: _selectedDate,
                    ),
                  );
                  await _loadEmployees();
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteEmployeeDialog(Employee employee) {
    final id = employee.id;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${employee.name} Silinecek'),
        content: const Text(
          'Bu çalışanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final pdf = PdfService();

              if (mounted) {
                setState(() => _isLoading = true);
              }
              try {
                // Context'i şimdi kaydedelim
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final attendances = await _attendanceService
                    .getAttendanceBetween(
                      employee.startDate,
                      DateTime.now(),
                      workerId: employee.id,
                    );
                final payments = await _paymentService.getPaymentsByWorkerId(
                  employee.id,
                );
                final pdfFile = await pdf.generateEmployeeTerminatedReport(
                  employee,
                  attendances,
                  payments,
                );

                await _workerService.deleteEmployee(id);

                await _loadEmployees();

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${employee.name} silindi, rapor kaydedildi: ${pdfFile.path}',
                    ),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'RAPORU AÇ',
                      onPressed: () => pdf.openPdf(pdfFile),
                    ),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('İşlem sırasında bir hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet (Raporla ve Sil)'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (mounted) {
                setState(() => _isLoading = true);
              }
              try {
                await _workerService.deleteEmployee(id);

                await _loadEmployees();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${employee.name} silindi.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('İşlem sırasında bir hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sadece Sil'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllEmployeesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Çalışanları Sil'),
        content: const Text(
          'Tüm çalışanları ve ilişkili devam/ödeme kayıtlarını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Context'i şimdi kaydedelim
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (mounted) {
                setState(() => _isLoading = true);
              }
              try {
                await _workerService.deleteAllEmployees();
                await _loadEmployees();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tüm çalışanlar silindi.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('İşlem sırasında bir hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        if (mounted) {
          setState(() => _isLoading = true);
        }

        // Context'i şimdi kaydedelim
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Yeni başlangıç tarihi kontrolü
        if (_isEditing && _selectedEmployee!.startDate != _employee.startDate) {
          // Giriş tarihi değiştirilmiş, veri tutarlılığı kontrolü yapılmalı

          // Eğer yeni tarih eskisinden daha ilerideyse, eski kayıtları silme onayı gerekli
          if (_employee.startDate.isAfter(_selectedEmployee!.startDate)) {
            // Eski tarihten önceki kayıtlar var mı kontrol et
            final hasOldRecords = await _workerService.hasRecordsBeforeDate(
              _selectedEmployee!.id,
              _employee.startDate,
            );

            if (hasOldRecords) {
              final shouldDelete =
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Dikkat!'),
                      content: Text(
                        'Çalışanın başlangıç tarihini ${DateFormat('dd/MM/yyyy').format(_selectedEmployee!.startDate)} '
                        'tarihinden ${DateFormat('dd/MM/yyyy').format(_employee.startDate)} '
                        'tarihine değiştirmek üzeresiniz.\n\n'
                        'Bu değişiklik, yeni başlangıç tarihinden önceki tüm devam ve ödeme kayıtlarını SİLECEKTİR.\n\n'
                        'Eğer silinen kayıtlar paid_days tablosunda referans ediliyorsa, ilişkili ödeme kayıtları da güncellenecektir.\n\n'
                        'Devam etmek istiyor musunuz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Kayıtları Sil ve Devam Et'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (!shouldDelete) {
                // Kullanıcı iptal ettiyse, eski tarihi geri yükle ve işlemi durdur
                if (mounted) {
                  setState(() {
                    _employee = _employee.copyWith(
                      startDate: _selectedEmployee!.startDate,
                    );
                    _isLoading = false;
                  });
                }
                return;
              }
            }
          }
        }

        // Çalışanı kaydet
        if (_isEditing) {
          await _workerService.updateEmployee(_employee);
        } else {
          await _workerService.addEmployee(_employee);
        }

        // Çalışanları yeniden yükle
        await _loadEmployees();

        if (mounted) {
          setState(() {
            _isEditing = false;
            _selectedEmployee = null;
            _isLoading = false;
          });

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                '${_employee.name} ${_isEditing ? 'güncellendi' : 'eklendi'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          setState(() => _isLoading = false);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 22.0 : 16.0;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _employees.isEmpty
            ? Center(
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
                      'Henüz çalışan yok.',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showDeleteAllEmployeesDialog,
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Tüm Çalışanları Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Çalışan ara...',
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
                      style: const TextStyle(color: Colors.black),
                      onChanged: _filterEmployees,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filteredEmployees.length,
                      padding: const EdgeInsets.only(bottom: 80.0),
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final emp = _filteredEmployees[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.22
                                            : 0.12,
                                      ),
                                  child: Text(
                                    emp.name.isNotEmpty
                                        ? emp.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.name,
                                        style: TextStyle(
                                          fontSize: fontSize + 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (emp.title.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            emp.title,
                                            style: TextStyle(
                                              fontSize: fontSize * 0.95,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      if (emp.phone.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                emp.phone,
                                                style: TextStyle(
                                                  fontSize: fontSize * 0.92,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Giriş: ${DateFormat('dd/MM/yyyy').format(emp.startDate)}',
                                              style: TextStyle(
                                                fontSize: fontSize * 0.9,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showEditEmployeeDialog(emp),
                                      tooltip: 'Düzenle',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _showDeleteEmployeeDialog(emp),
                                      tooltip: 'Sil',
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          onPressed: _showAddEmployeeDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.add,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimary,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.16),
        ),
      ),
    );
  }
}
