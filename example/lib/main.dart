import 'package:flutter/material.dart';
import 'pages/basic_kline_page.dart';
import 'pages/realtime_kline_page.dart';
import 'pages/indicators_page.dart';
import 'pages/trend_chart_page.dart';

void main() {
  runApp(const FluxKlineExampleApp());
}

class FluxKlineExampleApp extends StatelessWidget {
  const FluxKlineExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluxKline Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFF0B90B),
          surface: const Color(0xFF131722),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    BasicKLinePage(),
    RealtimeKLinePage(),
    IndicatorsPage(),
    TrendChartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E222D),
        selectedItemColor: const Color(0xFFF0B90B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart), label: 'Basic'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Realtime'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Indicators'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trend'),
        ],
      ),
    );
  }
}
