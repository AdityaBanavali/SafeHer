
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:developer' as developer;

// Defines the type of event for the calendar
enum EventType { logged, predicted }

class CalendarEvent {
  final EventType type;
  CalendarEvent(this.type);
}

class Symptom {
  final String name;
  final IconData icon;
  bool isSelected;

  Symptom(this.name, this.icon, {this.isSelected = false});
}

class MenstrualCyclePage extends StatefulWidget {
  const MenstrualCyclePage({super.key});

  @override
  State<MenstrualCyclePage> createState() => _MenstrualCyclePageState();
}

class _MenstrualCyclePageState extends State<MenstrualCyclePage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref('cycles');
  late StreamSubscription<DatabaseEvent> _streamSubscription;

  List<Cycle> _cycles = [];
  DateTime? _predictedNextStartDate;
  String _currentPhase = 'Menstrual';
  int _currentDayInCycle = 0;
  double _cycleProgress = 0.0;
  int _averageCycleLength = 28;

  final Map<String, Symptom> _symptoms = {
    'Cramps': Symptom('Cramps', Icons.healing),
    'Fatigue': Symptom('Fatigue', Icons.battery_alert),
    'Mood Swings': Symptom('Mood Swings', Icons.sentiment_very_dissatisfied),
    'Headache': Symptom('Headache', Icons.report_problem),
    'Bloating': Symptom('Bloating', Icons.local_cafe),
  };

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _activateListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  void _activateListeners() {
    _streamSubscription = _databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final cycles = data.values
            .map((e) => Cycle.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        cycles.sort((a, b) => a.startDate.compareTo(b.startDate));
        setState(() {
          _cycles = cycles;
          _predictNextCycle();
          _updateCyclePhase();
        });
      }
    });
  }

  void _predictNextCycle() {
    if (_cycles.length < 2) {
      setState(() {
        _predictedNextStartDate = null;
        _averageCycleLength = 28;
      });
      return;
    }

    int totalCycleLength = 0;
    final recentCycles =
        _cycles.length > 6 ? _cycles.sublist(_cycles.length - 6) : _cycles;

    for (int i = 1; i < recentCycles.length; i++) {
      final difference =
          recentCycles[i].startDate.difference(recentCycles[i - 1].startDate).inDays;
      totalCycleLength += difference;
    }

    if (recentCycles.length > 1) {
        setState(() {
            _averageCycleLength = (totalCycleLength / (recentCycles.length - 1)).round();
            if (_cycles.isNotEmpty) {
                _predictedNextStartDate =
                    _cycles.last.startDate.add(Duration(days: _averageCycleLength));
            }
        });
    }
  }

  void _updateCyclePhase() {
    if (_cycles.isEmpty) return;

    final lastStartDate = _cycles.last.startDate;
    final now = DateTime.now();
    final difference = now.difference(lastStartDate).inDays;

    setState(() {
        _currentDayInCycle = difference + 1;
        _cycleProgress = (_currentDayInCycle / _averageCycleLength).clamp(0.0, 1.0);

        if (_currentDayInCycle <= 5) {
          _currentPhase = 'Menstrual';
        } else if (_currentDayInCycle <= 13) {
          _currentPhase = 'Follicular';
        } else if (_currentDayInCycle <= 15) {
          _currentPhase = 'Ovulation';
        } else {
          _currentPhase = 'Luteal';
        }
    });
  }

  Future<void> _logPeriod() async {
    final today = DateTime.now();
    final newEntryKey = _databaseReference.push().key;

    if (newEntryKey == null) return;

    final selectedSymptoms = _symptoms.values
        .where((symptom) => symptom.isSelected)
        .map((symptom) => symptom.name)
        .toList();

    final newCycle = Cycle(startDate: today, symptoms: selectedSymptoms);

    await _databaseReference.child(newEntryKey).set(newCycle.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period logged successfully!')),
      );
      setState(() {
        for (var symptom in _symptoms.values) {
          symptom.isSelected = false;
        }
      });
    }
  }

  Future<void> _generatePdf() async {
    if (_cycles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No cycle data available to generate a report.')),
        );
      }
      return;
    }

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Menstrual Cycle Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Cycle Statistics',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Average Cycle Length: $_averageCycleLength days'),
                pw.SizedBox(height: 20),
                pw.Text('Recent Cycles',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Table.fromTextArray(
                  headers: ['Start Date', 'Symptoms'],
                  data: _cycles.map((cycle) => [
                            DateFormat.yMMMMd().format(cycle.startDate),
                            cycle.symptoms.join(', '),
                          ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, stackTrace) {
      developer.log('Failed to generate PDF',
          name: 'com.safeher.pdf', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
        );
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    List<CalendarEvent> events = [];
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);

    for (final cycle in _cycles) {
      final startDate = DateTime.utc(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      final periodEnd = startDate.add(const Duration(days: 4));
      if (!normalizedDay.isBefore(startDate) &&
          !normalizedDay.isAfter(periodEnd)) {
        events.add(CalendarEvent(EventType.logged));
        return events;
      }
    }

    if (_predictedNextStartDate != null) {
      for (int i = 0; i < 6; i++) {
        final futureStartDate = DateTime.utc(
            _predictedNextStartDate!.year,
            _predictedNextStartDate!.month,
            _predictedNextStartDate!.day)
            .add(Duration(days: _averageCycleLength * i));
        final futureEndDate = futureStartDate.add(const Duration(days: 4));

        if (!normalizedDay.isBefore(futureStartDate) &&
            !normalizedDay.isAfter(futureEndDate)) {
          events.add(CalendarEvent(EventType.predicted));
          return events;
        }
      }
    }
    return events;
  }
  
  String _getPhaseDescription() {
    switch (_currentPhase) {
      case 'Menstrual':
        return 'The start of your cycle. The uterine lining is shed.';
      case 'Follicular':
        return 'The body prepares for ovulation. Estrogen levels rise.';
      case 'Ovulation':
        return 'A mature egg is released from the ovary. Peak fertility.';
      case 'Luteal':
        return 'The body prepares for a possible pregnancy. Progesterone levels rise.';
      default:
        return 'Your cycle at a glance.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Menstrual Cycle Tracker',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Export to PDF',
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Overview'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewPage(),
            _buildCalendarPage(),
            _buildStatsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCyclePhaseCard(),
          const SizedBox(height: 20),
          _buildPredictionCard(),
          const SizedBox(height: 20),
          _buildLoggingCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders<CalendarEvent>(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(events.first.type),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarker(EventType type) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: type == EventType.logged ? Colors.red[400] : Colors.purple[300],
      ),
      width: 8.0,
      height: 8.0,
    );
  }

  Widget _buildStatsPage() {
    if (_cycles.length < 2) {
      return const Center(child: Text('Not enough data for statistics.'));
    }

    final cycleLengths = <int>[];
    for (int i = 1; i < _cycles.length; i++) {
      cycleLengths.add(_cycles[i].startDate.difference(_cycles[i - 1].startDate).inDays);
    }

    if (cycleLengths.isEmpty) {
      return const Center(child: Text('Not enough data for statistics.'));
    }

    final double averageLength = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final int minLength = cycleLengths.reduce(min);
    final int maxLength = cycleLengths.reduce(max);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatCard('Average Cycle Length', '${averageLength.toStringAsFixed(1)} days', Icons.cached_rounded),
          _buildStatCard('Shortest Cycle', '$minLength days', Icons.trending_down_rounded),
          _buildStatCard('Longest Cycle', '$maxLength days', Icons.trending_up_rounded),
        ],
      ),
    );
  }

  Card _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(value, style: GoogleFonts.oswald(fontSize: 28, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Card _buildCyclePhaseCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 15.0,
              percent: _cycleProgress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Day $_currentDayInCycle', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 32)),
                  Text(_currentPhase, style: GoogleFonts.lato(fontSize: 20, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(51),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 20),
            Text(
              _getPhaseDescription(),
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildPredictionCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Period', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 8),
                  if (_predictedNextStartDate != null)
                    Text('Expected on: ${DateFormat.yMMMMd().format(_predictedNextStartDate!)}', style: GoogleFonts.lato(fontSize: 16))
                  else
                    Text('Not enough data to predict.', style: GoogleFonts.lato(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSymptomCard(Symptom symptom) {
    return GestureDetector(
      onTap: () {
        setState(() {
          symptom.isSelected = !symptom.isSelected;
        });
      },
      child: Card(
        elevation: symptom.isSelected ? 8 : 2,
        color: symptom.isSelected ? Colors.deepPurple[100] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(symptom.icon, size: 40, color: symptom.isSelected ? Colors.deepPurple : Colors.grey),
            const SizedBox(height: 10),
            Text(symptom.name, style: GoogleFonts.lato(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Card _buildLoggingCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log Today\'s Symptoms', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _symptoms.values.map((symptom) => _buildSymptomCard(symptom)).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _logPeriod,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Log Period'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Cycle {
  final DateTime startDate;
  final List<String> symptoms;

  Cycle({required this.startDate, required this.symptoms});

  factory Cycle.fromMap(Map<String, dynamic> map) {
    return Cycle(
      startDate: DateTime.parse(map['start_date'] as String),
      symptoms: List<String>.from(map['symptoms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_date': startDate.toIso8601String(),
      'symptoms': symptoms,
    };
  }
}
