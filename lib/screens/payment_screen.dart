import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../services/worker_service.dart';
import '../services/payment_service.dart';
import '../widgets/payment_dialog.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  Map<int, Map<String, int>> _unpaidDays = {};
  Map<int, double> _unpaidScores =
      {}; // Toplam ödenmemiş gün skoru (Tam + Yarım*0.5)
  bool _isLoading = true;
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Önceki aramayı temizle
    _searchController.clear();

    final employees = await WorkerService().getEmployees();
    final paymentService = PaymentService();
    final unpaidDaysMap = <int, Map<String, int>>{};
    final unpaidScoresMap = <int, double>{};

    for (var emp in employees) {
      final unpaidDays = await paymentService.getUnpaidDays(emp.id);
      if (unpaidDays['fullDays']! > 0 || unpaidDays['halfDays']! > 0) {
        unpaidDaysMap[emp.id] = unpaidDays;

        // Skoru hesapla: Tam gün 1 puan, yarım gün 0.5 puan
        final score =
            unpaidDays['fullDays']!.toDouble() +
            (unpaidDays['halfDays']!.toDouble() * 0.5);
        unpaidScoresMap[emp.id] = score;
      }
    }

    final filteredEmployees =
        employees.where((emp) => unpaidDaysMap.containsKey(emp.id)).toList();

    // Çalışanları ödenmemiş gün skorlarına göre büyükten küçüğe sırala
    filteredEmployees.sort((a, b) {
      final scoreA = unpaidScoresMap[a.id] ?? 0;
      final scoreB = unpaidScoresMap[b.id] ?? 0;
      // Büyükten küçüğe sıralama için B'den A'yı çıkarıyoruz
      return scoreB.compareTo(scoreA);
    });

    setState(() {
      _employees = filteredEmployees;
      _filteredEmployees = filteredEmployees;
      _unpaidDays = unpaidDaysMap;
      _unpaidScores = unpaidScoresMap;
      _isLoading = false;
    });
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

  void _showPaymentDialog(Employee employee) {
    showDialog(
      context: context,
      builder:
          (context) =>
              PaymentDialog(employee: employee, onPaymentComplete: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Ödenmemiş günü olan çalışan bulunmuyor.',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                : LayoutBuilder(
                  builder:
                      (context, constraints) => Column(
                        children: [
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          Flexible(
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.4),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Arama sonucu bulunamadı.',
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
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
                                        final emp = _filteredEmployees[index];
                                        final unpaidDays = _unpaidDays[emp.id]!;
                                        final score =
                                            _unpaidScores[emp.id] ?? 0;

                                        return Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            onTap:
                                                () => _showPaymentDialog(emp),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 16,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 24,
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
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 18),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          emp.name,
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
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
                                                                    0.92,
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
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 6,
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .warning_amber_rounded,
                                                                    color:
                                                                        Theme.of(
                                                                          context,
                                                                        ).colorScheme.error,
                                                                    size: 18,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    'Ödenmemiş Gün:',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          fontSize *
                                                                          0.92,
                                                                      color:
                                                                          Theme.of(
                                                                            context,
                                                                          ).colorScheme.error,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${unpaidDays['fullDays']} Tam | ${unpaidDays['halfDays']} Yarım',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          fontSize *
                                                                          0.92,
                                                                      color:
                                                                          Theme.of(
                                                                            context,
                                                                          ).colorScheme.error,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    '(${score.toStringAsFixed(1)} gün)',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          fontSize *
                                                                          0.85,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          Theme.of(
                                                                            context,
                                                                          ).colorScheme.error,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Colors.grey[400],
                                                    size: 32,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                ),
      ),
    );
  }
}
