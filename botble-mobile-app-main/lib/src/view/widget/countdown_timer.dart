import 'dart:async';
import 'package:flutter/material.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;

  const CountdownTimer({super.key, required this.endTime});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeLeft = const Duration();

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);
    setState(() {
      _timeLeft = difference.isNegative ? const Duration() : difference;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == const Duration()) {
      return Text(
        'Ended',
        style: kAppTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[_TimeBox(value: days), _TimeSeparator()],
        _TimeBox(value: hours),
        _TimeSeparator(),
        _TimeBox(value: minutes),
        _TimeSeparator(),
        _TimeBox(value: seconds),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final int value;

  const _TimeBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.priceColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: kAppTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: kAppTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.priceColor,
        ),
      ),
    );
  }
}
