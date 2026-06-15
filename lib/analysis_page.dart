import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Health Analytics")),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/my_user/logs').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Log symptoms to see insights!"));
          }

          Map logs = snapshot.data!.snapshot.value as Map;
          Map<String, int> counts = {"Cramps": 0, "Headache": 0, "Mood Swing": 0};
          
          for (var log in logs.values) {
            if (counts.containsKey(log['symptom'])) {
              counts[log['symptom']] = counts[log['symptom']]! + 1;
            }
          }

          final entries = counts.entries.toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Symptom Frequency", style: theme.textTheme.titleLarge),
                    const SizedBox(height: 40),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: entries.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [BarChartRodData(toY: e.value.value.toDouble(), color: theme.colorScheme.primary, width: 20)],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(entries[value.toInt()].key, style: theme.textTheme.bodyMedium),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
