import 'dart:async';

import 'package:flutter/material.dart';

/// Live countdown to [endTime].
///
/// This is the one place setState is correct: the Timer belongs to this
/// widget only, so nothing else in the tree rebuilds when it ticks.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.endTime,
    this.style,
    this.endedText = 'Ended',
  });

  final DateTime endTime;
  final TextStyle? style;
  final String endedText;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(CountdownText old) {
    super.didUpdateWidget(old);
    if (old.endTime != widget.endTime) _remaining = _compute();
  }

  Duration _compute() => widget.endTime.difference(DateTime.now());

  void _tick() {
    if (!mounted) return;
    setState(() => _remaining = _compute());
    if (_remaining.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel(); // otherwise every scrolled-past card leaks a timer
    super.dispose();
  }

  static String format(Duration d, String endedText) {
    if (d.isNegative || d == Duration.zero) return endedText;
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(format(_remaining, widget.endedText), style: widget.style);
  }
}
