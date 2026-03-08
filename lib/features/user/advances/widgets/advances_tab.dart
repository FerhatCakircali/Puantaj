import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/advance.dart';
import '../../../../models/employee.dart';
import '../controllers/advance_controller.dart';
import 'advance_summary_cards.dart';
import 'advance_list_tile.dart';
import 'advance_empty_state.dart';
import '../dialogs/add_advance_dialog.dart';
import '../dialogs/advance_detail_dialog.dart';

/// Avanslar tab widget'ı
class AdvancesTab extends StatefulWidget {
  const AdvancesTab({super.key});

  @override
  State<AdvancesTab> createState() => _AdvancesTabState();
}

class _AdvancesTabState extends State<AdvancesTab> {
  final AdvanceController _controller = AdvanceController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Advance> _advances = [];
  List<Advance> _filteredAdvances = [];
  List<Employee> _employees = [];
  double _monthlyTotal = 0;
  double _overallTotal = 0;
  int _workerCount = 0;
  double _averageAdvance = 0;
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _searchController.clear();

    try {
      final data = await _controller.loadAdvanceData();

      if (!mounted) return;

      setState(() {
        _advances = data.advances;
        _filteredAdvances = data.advances;
        _employees = data.employees;
        _monthlyTotal = data.monthlyTotal;
        _overallTotal = data.overallTotal;
        _workerCount = data.workerCount;
        _averageAdvance = data.averageAdvance;
        _isLoading = false;
      });

      debugPrint('✅ Avans verileri yüklendi: ${_advances.length} avans');
    } catch (e) {
      debugPrint('⚠️ Avans verileri yükleme hatası: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterAdvances(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filteredAdvances = _controller.filterAdvances(
            _advances,
            _employees,
            query,
          );
        });
      }
    });
  }

  String _getWorkerName(int workerId) {
    return _controller.getWorkerName(workerId, _employees);
  }

  void _showAddAdvanceDialog() {
    AddAdvanceDialog.show(
      context,
      employees: _employees,
      onAdvanceAdded: _loadData,
    );
  }

  void _showAdvanceDetails(Advance advance) {
    final workerName = _getWorkerName(advance.workerId);
    AdvanceDetailDialog.show(
      context,
      advance: advance,
      workerName: workerName,
      onAdvanceUpdated: _loadData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.02),
                    // Özet kartları
                    AdvanceSummaryCards(
                      monthlyTotal: _monthlyTotal,
                      overallTotal: _overallTotal,
                      workerCount: _workerCount,
                      averageAdvance: _averageAdvance,
                    ),
                    SizedBox(height: h * 0.02),
                    // Arama çubuğu
                    _buildSearchBar(theme),
                    SizedBox(height: h * 0.02),
                    // Liste
                    Expanded(
                      child: _advances.isEmpty
                          ? const AdvanceEmptyState()
                          : _filteredAdvances.isEmpty
                          ? const AdvanceNoSearchResults()
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: h * 0.02),
                              itemCount: _filteredAdvances.length,
                              cacheExtent: h * 0.5,
                              itemBuilder: (context, index) {
                                final advance = _filteredAdvances[index];
                                final workerName = _getWorkerName(
                                  advance.workerId,
                                );
                                return RepaintBoundary(
                                  child: AdvanceListTile(
                                    advance: advance,
                                    workerName: workerName,
                                    onTap: () => _showAdvanceDetails(advance),
                                    primaryColor: primaryColor,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdvanceDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: TextField(
        controller: _searchController,
        onChanged: _filterAdvances,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Çalışan ara...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.shade700,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade700,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterAdvances('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
