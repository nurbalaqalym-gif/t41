import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlashGridApp());
}

class FlashGridApp extends StatelessWidget {
  const FlashGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Сетка вспышек',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFA855F7),
        ),
      ),
      home: const FlashGridScreen(),
    );
  }
}

enum RoundPhase { idle, memorizing, guessing, finished }

class FlashGridScreen extends StatefulWidget {
  const FlashGridScreen({super.key});

  @override
  State<FlashGridScreen> createState() => _FlashGridScreenState();
}

class _FlashGridScreenState extends State<FlashGridScreen> {
  static const int _gridSize = 16; // 4x4
  final Random _random = Random();

  int _level = 1;
  int _bestLevel = 1;
  RoundPhase _phase = RoundPhase.idle;
  String _hint = 'Нажми «Старт», чтобы запомнить узор';

  Set<int> _targetCells = {};
  Set<int> _pickedCells = {};
  int? _wrongCell;

  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  int _cellsCountForLevel(int level) => (level + 2).clamp(3, 10);

  void _startRound() {
    _hideTimer?.cancel();
    final count = _cellsCountForLevel(_level);
    final allIndices = List<int>.generate(_gridSize, (i) => i)
      ..shuffle(_random);

    setState(() {
      _targetCells = allIndices.take(count).toSet();
      _pickedCells = {};
      _wrongCell = null;
      _phase = RoundPhase.memorizing;
      _hint = 'Запоминай клетки ($count шт.)...';
    });

    _hideTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _phase = RoundPhase.guessing;
        _hint = 'Повтори узор по памяти!';
      });
    });
  }

  void _onTileTap(int index) {
    if (_phase != RoundPhase.guessing) return;
    if (_pickedCells.contains(index)) return;

    if (_targetCells.contains(index)) {
      setState(() {
        _pickedCells.add(index);
      });

      if (_pickedCells.length == _targetCells.length) {
        setState(() {
          _phase = RoundPhase.finished;
          _level++;
          if (_level > _bestLevel) _bestLevel = _level;
          _hint = 'Точно! Готов к уровню $_level?';
        });
      }
    } else {
      setState(() {
        _wrongCell = index;
        _phase = RoundPhase.finished;
        _hint = 'Ошибка! Правильный узор подсвечен. Начни заново с 1 уровня.';
        _level = 1;
      });
    }
  }

  Color _tileColor(int index) {
    if (_phase == RoundPhase.memorizing && _targetCells.contains(index)) {
      return const Color(0xFF38BDF8);
    }
    if (_wrongCell == index) {
      return const Color(0xFFEF4444);
    }
    if (_pickedCells.contains(index)) {
      return const Color(0xFF22C55E);
    }
    if (_phase == RoundPhase.finished &&
        _wrongCell != null &&
        _targetCells.contains(index)) {
      return const Color(0xFF38BDF8).withOpacity(0.55);
    }
    return const Color(0xFF181E29);
  }

  @override
  Widget build(BuildContext context) {
    final canPressAction =
        _phase == RoundPhase.idle || _phase == RoundPhase.finished;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Сетка вспышек'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Уровень',
                    value: '$_level',
                    color: const Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Рекорд',
                    value: '$_bestLevel',
                    color: const Color(0xFFA855F7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _gridSize,
                    itemBuilder: (context, index) {
                      final color = _tileColor(index);
                      return GestureDetector(
                        onTap: () => _onTileTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: canPressAction ? _startRound : null,
                icon: const Icon(Icons.bolt),
                label: Text(
                  _phase == RoundPhase.idle
                      ? 'Старт'
                      : (_wrongCell != null
                            ? 'Попробовать снова'
                            : 'Следующий уровень'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
