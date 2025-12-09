  import 'dart:ui';

class TimerMode {
  final String name;
  final int duration;
  final Color color;

  const TimerMode({
    required this.name,
    required this.duration,
    required this.color,
  });

  static const focus = TimerMode(
    name: 'Focus',
    duration: 25 * 60,
    color: Color(0xFFF66B7D),
  );

  static const shortBreak = TimerMode(
    name: 'Short Break',
    duration: 5 * 60,
    color: Color(0xFF4CAF50),
  );

  static const longBreak = TimerMode(
    name: 'Long Break',
    duration: 15 * 60,
    color: Color(0xFF86A8E7),
  );

  static final allModes = [focus, shortBreak, longBreak];
}