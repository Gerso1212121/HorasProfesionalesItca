class TimerState {
  int remainingTime;
  bool isRunning;
  bool isCompleted;
  bool hasStarted;
  double currentFill;

  TimerState({
    required this.remainingTime,
    this.isRunning = false,
    this.isCompleted = false,
    this.hasStarted = false,
    this.currentFill = 0.0,
  });

  TimerState copyWith({
    int? remainingTime,
    bool? isRunning,
    bool? isCompleted,
    bool? hasStarted,
    double? currentFill,
  }) {
    return TimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      hasStarted: hasStarted ?? this.hasStarted,
      currentFill: currentFill ?? this.currentFill,
    );
  }
}