import 'dart:math';

class FpsStats {
  const FpsStats({required this.average, required this.sd, required this.es});

  final double average;
  final double sd;
  final double es;
}

FpsStats? computeFpsStats(List<double> shots, {bool sampleSd = true}) {
  if (shots.isEmpty) {
    return null;
  }

  final total = shots.fold<double>(0, (sum, value) => sum + value);
  final average = total / shots.length;
  final minValue = shots.reduce(min);
  final maxValue = shots.reduce(max);
  final es = maxValue - minValue;

  double sd = 0;
  if (shots.length > 1) {
    final varianceSum = shots
        .map((value) => pow(value - average, 2))
        .fold<double>(0, (sum, value) => sum + value.toDouble());
    final divisor = sampleSd ? shots.length - 1 : shots.length;
    sd = sqrt(varianceSum / divisor);
  }

  return FpsStats(average: average, sd: sd, es: es);
}
