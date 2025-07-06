import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart';
import '../services/spend_line_database.dart';
import '../models/transaction.dart' as trans;
import '../models/spend_line.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool isBarChart = true;
  String selectedPeriod = 'Weekly';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int selectedWeekOffset = 0;
  int selectedWeek = 1;
  List<trans.Transaction> transactions = [];
  List<SpendLine> spendLines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // Charger les transactions (revenus)
      final tx = await WalletDatabase.instance.getLatestTransactions(1000);
      // Charger les lignes de dépenses
      final spends = await SpendLineDatabase.instance.getAll();
      
      setState(() {
        transactions = tx;
        spendLines = spends;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<trans.Transaction> _getFilteredTransactions() {
    switch (selectedPeriod) {
      case 'Daily':
        final now = DateTime.now();
        return transactions.where((tx) =>
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day).toList();
      case 'Weekly':
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1 + (7 * selectedWeekOffset)));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return transactions.where((tx) =>
            tx.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(weekEnd.add(const Duration(days: 1)))).toList();
      case 'Monthly':
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final startDay = (selectedWeek - 1) * 7 + 1;
        final endDay = startDay + 6 > daysInMonth ? daysInMonth : startDay + 6;
        return transactions.where((tx) =>
            tx.date.year == selectedYear &&
            tx.date.month == selectedMonth &&
            tx.date.day >= startDay &&
            tx.date.day <= endDay).toList();
      case 'Yearly':
        return transactions.where((tx) => tx.date.year == selectedYear).toList();
      default:
        return [];
    }
  }

  List<SpendLine> _getFilteredSpendLines() {
    switch (selectedPeriod) {
      case 'Daily':
        final now = DateTime.now();
        return spendLines.where((spend) =>
            spend.date.year == now.year &&
            spend.date.month == now.month &&
            spend.date.day == now.day).toList();
      case 'Weekly':
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1 + (7 * selectedWeekOffset)));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return spendLines.where((spend) =>
            spend.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            spend.date.isBefore(weekEnd.add(const Duration(days: 1)))).toList();
      case 'Monthly':
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final startDay = (selectedWeek - 1) * 7 + 1;
        final endDay = startDay + 6 > daysInMonth ? daysInMonth : startDay + 6;
        return spendLines.where((spend) =>
            spend.date.year == selectedYear &&
            spend.date.month == selectedMonth &&
            spend.date.day >= startDay &&
            spend.date.day <= endDay).toList();
      case 'Yearly':
        return spendLines.where((spend) => spend.date.year == selectedYear).toList();
      default:
        return [];
    }
  }

  Map<String, double> _calculateTotals() {
    final filteredTx = _getFilteredTransactions();
    final filteredSpends = _getFilteredSpendLines();
    final Map<String, double> totals = {'budget': 0.0, 'cost': 0.0};

    // Calculer le budget à partir des transactions (revenus)
    for (var tx in filteredTx) {
      if (tx.type == 'income') {
        totals['budget'] = totals['budget']! + tx.amount;
      } else if (tx.type == 'outcome') {
        totals['cost'] = totals['cost']! + tx.amount;
      }
    }

    // Ajouter les coûts des lignes de dépenses
    for (var spend in filteredSpends) {
      totals['cost'] = totals['cost']! + spend.budget;
    }

    totals['save'] = totals['budget']! - totals['cost']!;
    return totals;
  }

  List<BarChartGroupData> _buildBarChartData() {
    final labels = _getPeriodLabels();
    final List<BarChartGroupData> barGroups = [];
    final filteredTx = _getFilteredTransactions();
    final filteredSpends = _getFilteredSpendLines();

    for (int i = 0; i < labels.length; i++) {
      double budget = 0.0;
      double cost = 0.0;
      
      // Calculer le budget et les coûts des transactions
      for (var tx in filteredTx) {
        final txDate = tx.date;
        bool include = false;
        
        switch (selectedPeriod) {
          case 'Daily':
            include = txDate.hour == i;
            break;
          case 'Weekly':
            final dayIndex = i + 1;
            final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + (7 * selectedWeekOffset)));
            include = txDate.weekday == dayIndex && 
                      txDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                      txDate.isBefore(weekStart.add(const Duration(days: 7)));
            break;
          case 'Monthly':
            include = txDate.day == (i + 1) + ((selectedWeek - 1) * 7);
            break;
          case 'Yearly':
            include = txDate.month == i + 1;
            break;
        }
        
        if (include) {
          if (tx.type == 'income') budget += tx.amount;
          if (tx.type == 'outcome') cost += tx.amount;
        }
      }
      
      // Ajouter les coûts des lignes de dépenses
      for (var spend in filteredSpends) {
        final spendDate = spend.date;
        bool include = false;
        
        switch (selectedPeriod) {
          case 'Daily':
            include = spendDate.hour == i;
            break;
          case 'Weekly':
            final dayIndex = i + 1;
            final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + (7 * selectedWeekOffset)));
            include = spendDate.weekday == dayIndex && 
                      spendDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                      spendDate.isBefore(weekStart.add(const Duration(days: 7)));
            break;
          case 'Monthly':
            include = spendDate.day == (i + 1) + ((selectedWeek - 1) * 7);
            break;
          case 'Yearly':
            include = spendDate.month == i + 1;
            break;
        }
        
        if (include) {
          cost += spend.budget;
        }
      }
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: budget, 
            color: Colors.blue, 
            width: _getBarWidth(),
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: cost, 
            color: Colors.red.shade300, 
            width: _getBarWidth(),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return barGroups;
  }

  double _getBarWidth() {
    switch (selectedPeriod) {
      case 'Daily':
        return 8; // Réduit de 15 à 8
      case 'Weekly':
        return 12; // Réduit de 25 à 12
      case 'Monthly':
        return 6; // Réduit de 12 à 6
      case 'Yearly':
        return 10; // Réduit de 20 à 10
      default:
        return 8; // Réduit de 20 à 8
    }
  }

  List<String> _getPeriodLabels() {
    switch (selectedPeriod) {
      case 'Daily':
        return List.generate(24, (i) => '${i}h');
      case 'Weekly':
        return ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      case 'Monthly':
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final startDay = (selectedWeek - 1) * 7 + 1;
        final endDay = startDay + 6 > daysInMonth ? daysInMonth : startDay + 6;
        return List.generate(endDay - startDay + 1, (i) => '${startDay + i}');
      case 'Yearly':
        return [
          'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
          'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
        ];
      default:
        return [];
    }
  }

  List<PieChartSectionData> _buildPieChartData() {
    final totals = _calculateTotals();
    final totalAmount = totals['budget']! + totals['cost']!;
    
    if (totalAmount == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: 'Aucune donnée',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ];
    }

    List<PieChartSectionData> sections = [];
    
    if (totals['budget']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue,
        value: totals['budget'],
        title: 'Budget\n${totals['budget']!.toStringAsFixed(0)} FCFA',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    
    if (totals['cost']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red.shade300,
        value: totals['cost'],
        title: 'Dépenses\n${totals['cost']!.toStringAsFixed(0)} FCFA',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    
    if (totals['save']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green,
        value: totals['save'],
        title: 'Économie\n${totals['save']!.toStringAsFixed(0)} FCFA',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return sections;
  }

  double _getMaxYValue() {
    final totals = _calculateTotals();
    final maxValue = [totals['budget']!, totals['cost']!].reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue * 1.2 : 100;
  }

  void _changeWeek(int delta) {
    setState(() {
      if (selectedPeriod == 'Weekly') {
        selectedWeekOffset += delta;
      } else if (selectedPeriod == 'Monthly') {
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final maxWeeks = (daysInMonth / 7).ceil();
        selectedWeek = (selectedWeek + delta).clamp(1, maxWeeks);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6074F9);
    final totals = _calculateTotals();
    final screenHeight = MediaQuery.of(context).size.height;
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final maxWeeks = (daysInMonth / 7).ceil();

    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6074F9),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.bar_chart,
                                  color: isBarChart ? Colors.white : Colors.white60,
                                  size: 24,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isBarChart = true;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.pie_chart,
                                  color: !isBarChart ? Colors.white : Colors.white60,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isBarChart = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          buildNotificationAction(context),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Budget et Dépenses",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPeriodButton('Daily', 'Jour'),
                                _buildPeriodButton('Weekly', 'Semaine'),
                                _buildPeriodButton('Monthly', 'Mois'),
                                _buildPeriodButton('Yearly', 'Année'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                if (selectedPeriod == 'Monthly' || selectedPeriod == 'Yearly')
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: selectedPeriod == 'Monthly' ? selectedMonth : selectedYear,
                                          isExpanded: true,
                                          items: selectedPeriod == 'Monthly'
                                            ? List.generate(12, (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: Text('${_getMonthName(i + 1)} $selectedYear'),
                                              ))
                                            : List.generate(5, (i) => DropdownMenuItem(
                                                value: DateTime.now().year - 2 + i,
                                                child: Text('${DateTime.now().year - 2 + i}'),
                                              )),
                                          onChanged: (value) {
                                            setState(() {
                                              if (selectedPeriod == 'Monthly') {
                                                selectedMonth = value!;
                                                selectedWeek = 1;
                                              } else {
                                                selectedYear = value!;
                                                selectedWeekOffset = 0;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                if (selectedPeriod == 'Weekly' || selectedPeriod == 'Monthly')
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                                        onPressed: () => _changeWeek(-1),
                                        color: primaryColor,
                                      ),
                                      Text(
                                        selectedPeriod == 'Weekly'
                                          ? 'Semaine ${selectedWeekOffset == 0 ? 'actuelle' : selectedWeekOffset > 0 ? 'future +$selectedWeekOffset' : 'passée ${selectedWeekOffset.abs()}'}'
                                          : 'Semaine $selectedWeek / $maxWeeks',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onPressed: () => _changeWeek(1),
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            Container(
                              height: screenHeight * 0.3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: isBarChart
                                  ? _buildBarChart()
                                  : _buildPieChart(),
                            ),
                            
                            if (isBarChart) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendItem(Colors.blue, "Budget"),
                                  const SizedBox(width: 20),
                                  _buildLegendItem(Colors.red.shade300, "Dépenses"),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getPeriodTitle(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _detailItem("Budget", "${totals['budget']!.toStringAsFixed(0)} FCFA", Icons.trending_up),
                                  _detailItem("Dépenses", "${totals['cost']!.toStringAsFixed(0)} FCFA", Icons.trending_down),
                                  const Divider(color: Colors.white54, height: 20),
                                  _detailItem("Économie", "${totals['save']!.toStringAsFixed(0)} FCFA", Icons.savings, isTotal: true),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: totals['save']! > 0 ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    totals['save']! > 0 ? Icons.check_circle : Icons.info,
                                    color: totals['save']! > 0 ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Objectif budgétaire",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          totals['save']! > 0 
                                            ? "Objectif atteint avec succès !" 
                                            : "Attention aux dépenses !",
                                          style: TextStyle(
                                            color: totals['save']! > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6074F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getPeriodTitle() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + (7 * selectedWeekOffset)));
    switch (selectedPeriod) {
      case 'Daily':
        return 'Aujourd\'hui';
      case 'Weekly':
        return 'Semaine du ${weekStart.day}/${weekStart.month}/${weekStart.year}';
      case 'Monthly':
        return 'Semaine $selectedWeek - ${_getMonthName(selectedMonth)}';
      case 'Yearly':
        return 'Année $selectedYear';
      default:
        return selectedPeriod;
    }
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxYValue(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Budget' : 'Dépenses';
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(0)} FCFA',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final labels = _getPeriodLabels();
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: _buildBarChartData(),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: _buildPieChartData(),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        startDegreeOffset: -90,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Optionnel : ajouter des interactions
          },
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, IconData icon, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}