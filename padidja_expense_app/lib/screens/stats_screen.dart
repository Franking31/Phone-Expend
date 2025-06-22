import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../widgets/main_drawer_wrapper.dart';


class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool isBarChart = true; // true pour barres, false pour camembert

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6074F9);

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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Le bouton menu est maintenant géré par MainDrawerWrapper
                        const SizedBox(width: 48), // Espace pour le bouton menu du wrapper
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
                        buildNotificationAction(context), // Remplacement par buildNotificationAction
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Budget",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Daily", style: TextStyle(color: Colors.grey)),
                            Text("Weekly", style: TextStyle(color: Colors.grey)),
                            Text("Monthly", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text("Yearly", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: isBarChart ? _buildBarChart() : _buildPieChart(),
                        ),
                        if (isBarChart) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.circle, color: Colors.blue, size: 12),
                              const SizedBox(width: 5),
                              const Text("Budget"),
                              const SizedBox(width: 10),
                              Icon(Icons.circle, color: Colors.blue.shade200, size: 12),
                              const SizedBox(width: 5),
                              const Text("Cost"),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "February",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              _detailItem("Budget", "\$3,850"),
                              _detailItem("Cost", "\$1,235"),
                              _detailItem("Save", "\$2,615"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Monthly Goal"),
                              SizedBox(width: 10),
                              Text("Achieved Successfully", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 10),
                              Icon(Icons.circle, color: Colors.grey, size: 12),
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

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 4000,
        barTouchData: const BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const labels = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(
                    labels[value.toInt()], 
                    style: const TextStyle(color: Colors.grey)
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
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: 1000, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 1500, color: Colors.blue, width: 20),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: 1200, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 1800, color: Colors.blue, width: 20),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(toY: 800, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 2000, color: Colors.blue, width: 20),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(toY: 900, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 2200, color: Colors.blue, width: 20),
            ],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [
              BarChartRodData(toY: 1100, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 2500, color: Colors.blue, width: 20),
            ],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [
              BarChartRodData(toY: 1235, color: Colors.blue.shade200, width: 20),
              BarChartRodData(toY: 3850, color: Colors.blue, width: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.blue,
            value: 3850,
            title: 'Budget\n\$3,850',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blue.shade200,
            value: 1235,
            title: 'Cost\n\$1,235',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 2615,
            title: 'Save\n\$2,615',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}