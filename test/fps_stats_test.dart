import 'package:flutter_test/flutter_test.dart';
import 'package:loadintel/core/utils/fps_stats.dart';

void main() {
  test('computeFpsStats uses sample SD by default', () {
    final stats = computeFpsStats([100, 110, 120]);
    expect(stats, isNotNull);
    expect(stats!.average, closeTo(110, 0.0001));
    expect(stats.es, closeTo(20, 0.0001));
    expect(stats.sd, closeTo(10, 0.0001));
  });
}
