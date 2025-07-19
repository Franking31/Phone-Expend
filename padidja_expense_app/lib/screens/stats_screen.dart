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
  List<Map<String, dynamic>> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // Charger les transactions (uniquement pour cohérence, à retirer si non utilisé)
      final tx = await WalletDatabase.instance.getLatestTransactions(1000);
      // Charger les lignes de dépenses
      final spends = await SpendLineDatabase.instance.getAll();
      // Charger tous les budgets
      final budgetsList = await WalletDatabase.instance.getAllBudgets();
      
      setState(() {
        transactions = tx;
        spendLines = spends;
        budgets = budgetsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

  List<Map<String, dynamic>> _getFilteredBudgets() {
    switch (selectedPeriod) {
      case 'Daily':
        final now = DateTime.now();
        return budgets.where((budget) {
          if (budget['date'] == null) return false;
          final budgetDate = DateTime.parse(budget['date']);
          return budgetDate.year == now.year &&
              budgetDate.month == now.month &&
              budgetDate.day == now.day;
        }).toList();
      case 'Weekly':
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1 + (7 * selectedWeekOffset)));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return budgets.where((budget) {
          if (budget['date'] == null) return false;
          final budgetDate = DateTime.parse(budget['date']);
          return budgetDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              budgetDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
      case 'Monthly':
        final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final startDay = (selectedWeek - 1) * 7 + 1;
        final endDay = startDay + 6 > daysInMonth ? daysInMonth : startDay + 6;
        return budgets.where((budget) {
          if (budget['date'] == null) return false;
          final budgetDate = DateTime.parse(budget['date']);
          return budgetDate.year == selectedYear &&
              budgetDate.month == selectedMonth &&
              budgetDate.day >= startDay &&
              budgetDate.day <= endDay;
        }).toList();
      case 'Yearly':
        return budgets.where((budget) {
          if (budget['date'] == null) return false;
          final budgetDate = DateTime.parse(budget['date']);
          return budgetDate.year == selectedYear;
        }).toList();
      default:
        return [];
    }
  }

  Map<String, double> _calculateTotals() {
    final filteredSpends = _getFilteredSpendLines();
    final filteredBudgets = _getFilteredBudgets();
    final Map<String, double> totals = {'budgetAllocated': 0.0, 'cost': 0.0, 'budgetSpent': 0.0};

    // Ajouter les budgets alloués
    for (var budget in filteredBudgets) {
      totals['budgetAllocated'] = totals['budgetAllocated']! + (budget['amount'] ?? 0.0);
    }

    // Ajouter les coûts des lignes de dépenses
    for (var spend in filteredSpends) {
      totals['cost'] = totals['cost']! + spend.budget;
    }

    // Calculer l'économie : budget alloué - dépenses
    totals['save'] = totals['budgetAllocated']! - totals['cost']!;
    return totals;
  }

  List<BarChartGroupData> _buildBarChartData() {
    final labels = _getPeriodLabels();
    final List<BarChartGroupData> barGroups = [];
    final filteredSpends = _getFilteredSpendLines();
    final filteredBudgets = _getFilteredBudgets();

    for (int i = 0; i < labels.length; i++) {
      double budgetAllocated = 0.0;
      double cost = 0.0;
      
      // Ajouter les données des budgets
      for (var budgetData in filteredBudgets) {
        if (budgetData['date'] == null) continue;
        final budgetDate = DateTime.parse(budgetData['date']);
        bool include = false;
        
        switch (selectedPeriod) {
          case 'Daily':
            include = budgetDate.hour == i;
            break;
          case 'Weekly':
            final dayIndex = i + 1;
            final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + (7 * selectedWeekOffset)));
            include = budgetDate.weekday == dayIndex && 
                      budgetDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                      budgetDate.isBefore(weekStart.add(const Duration(days: 7)));
            break;
          case 'Monthly':
            include = budgetDate.day == (i + 1) + ((selectedWeek - 1) * 7);
            break;
          case 'Yearly':
            include = budgetDate.month == i + 1;
            break;
        }
        
        if (include) {
          budgetAllocated += budgetData['amount'] ?? 0.0;
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
            toY: budgetAllocated, 
            color: Colors.orange, 
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
        return 6;
      case 'Weekly':
        return 10;
      case 'Monthly':
        return 4;
      case 'Yearly':
        return 8;
      default:
        return 6;
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
    final totalAmount = totals['budgetAllocated']! + totals['cost']!;

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
    
    if (totals['budgetAllocated']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange,
        value: totals['budgetAllocated'],
        title: 'Budget alloué\n${totals['budgetAllocated']!.toStringAsFixed(0)} FCFA',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    
    if (totals['cost']! > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red.shade300,
        value: totals['cost']!,
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
    final maxValue = [totals['budgetAllocated']!, totals['cost']!].reduce((a, b) => a > b ? a : b);
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
                                  _buildLegendItem(Colors.orange, "Budget alloué"),
                                  const SizedBox(width: 15),
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
                                  _buildDetailItem("Budget alloué", "${totals['budgetAllocated']!.toStringAsFixed(0)} FCFA", Icons.account_balance_wallet),
                                  _buildDetailItem("Dépenses", "${totals['cost']!.toStringAsFixed(0)} FCFA", Icons.trending_down),
                                  const Divider(color: Colors.white54, height: 20),
                                  _buildDetailItem("Économie", "${totals['save']!.toStringAsFixed(0)} FCFA", Icons.savings, isTotal: true),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: totals['save']! >= 0 ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    totals['save']! >= 0 ? Icons.check_circle : Icons.info,
                                    color: totals['save']! >= 0 ? Colors.green : Colors.orange,
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
                                          totals['save']! >= 0 
                                            ? "Objectif atteint avec succès !" 
                                            : "Attention, dépassement de budget !",
                                          style: TextStyle(
                                            color: totals['save']! >= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Nouvelle section pour afficher les budgets par catégorie
                            if (_getFilteredBudgets().isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                "Budgets par catégorie",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: _buildBudgetCategoryList(),
                                ),
                              ),
                            ],
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

  List<Widget> _buildBudgetCategoryList() {
    final filteredBudgets = _getFilteredBudgets();
    final filteredSpends = _getFilteredSpendLines();
    final Map<String, Map<String, double>> categoryTotals = {};
    
    // Grouper les budgets par catégorie
    for (var budget in filteredBudgets) {
      final category = budget['category'] ?? 'Non catégorisé';
      if (!categoryTotals.containsKey(category)) {
        categoryTotals[category] = {'allocated': 0.0, 'spent': 0.0};
      }
      categoryTotals[category]!['allocated'] = 
          (categoryTotals[category]!['allocated'] ?? 0.0) + (budget['amount'] ?? 0.0);
    }
    
    // Ajouter les dépenses des SpendLine par catégorie
    for (var spend in filteredSpends) {
      final category = spend.category ?? 'Non catégorisé';
      if (!categoryTotals.containsKey(category)) {
        categoryTotals[category] = {'allocated': 0.0, 'spent': 0.0};
      }
      categoryTotals[category]!['spent'] = 
          (categoryTotals[category]!['spent'] ?? 0.0) + spend.budget;
    }
    
    if (categoryTotals.isEmpty) {
      return [
        const Center(
          child: Text(
            'Aucun budget ou dépense pour cette période',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }
    
    List<Widget> categoryWidgets = [];
    
    categoryTotals.forEach((category, totals) {
      final allocated = totals['allocated']!;
      final spent = totals['spent']!;
      final remaining = allocated - spent;
      final percentage = allocated > 0 ? (spent / allocated) * 100 : 0.0;
      
      categoryWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: percentage > 90 
                          ? Colors.red.shade100 
                          : percentage > 70 
                              ? Colors.orange.shade100 
                              : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: percentage > 90 
                            ? Colors.red.shade700 
                            : percentage > 70 
                                ? Colors.orange.shade700 
                                : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Barre de progression
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: percentage > 90 
                              ? Colors.red 
                              : percentage > 70 
                                  ? Colors.orange 
                                  : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Détails des montants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alloué: ${allocated.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Dépensé: ${spent.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Restant: ${remaining.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          color: remaining >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (remaining < 0)
                        Text(
                          'Dépassement!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
    
    return categoryWidgets;
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = period;
          selectedWeekOffset = 0;
          selectedWeek = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6074F9) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = _buildBarChartData();
    final labels = _getPeriodLabels();
    
    return BarChart(
      BarChartData(
        maxY: _getMaxYValue(),
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(
                    labels[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxYValue() / 5,
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final sections = _buildPieChartData();
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodTitle() {
    switch (selectedPeriod) {
      case 'Daily':
        return 'Résumé du jour';
      case 'Weekly':
        return selectedWeekOffset == 0 
            ? 'Résumé de la semaine actuelle' 
            : selectedWeekOffset > 0 
                ? 'Résumé de la semaine future' 
                : 'Résumé de la semaine passée';
      case 'Monthly':
        return 'Résumé de ${_getMonthName(selectedMonth)} $selectedYear - Semaine $selectedWeek';
      case 'Yearly':
        return 'Résumé de l\'année $selectedYear';
      default:
        return 'Résumé';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}