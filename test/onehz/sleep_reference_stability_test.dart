import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:openstrap_analytics/onehz.dart';

void main() {
  test('later waking HR cannot erase a night with a fixed detection reference',
      () {
    final start = DateTime.utc(2026, 9, 10, 12).millisecondsSinceEpoch ~/ 1000;
    final gravity = <GravTs>[];
    final hr = <HrTs>[];
    for (var i = 0; i < 40 * 3600; i++) {
      final hour = i / 3600;
      final asleep = hour >= 12 && hour < 18;
      gravity
          .add(GravTs(start + i, asleep ? 0 : 0.3 * math.sin(i * 0.5), 0, 1));
      hr.add(HrTs(start + i, hour < 12 ? 100 : (asleep ? 95 : 55)));
    }
    List<SleepSession> detect(int hours, {double? reference}) =>
        AdvancedSleepStager.detectSleep(
          gravity.sublist(0, hours * 3600),
          hr.sublist(0, hours * 3600),
          detectionHrBaseline: reference,
        );
    final early = detect(19, reference: 100);
    final late = detect(40, reference: 100);
    expect(early, isNotEmpty);
    expect(late.map((s) => (s.start, s.end)).toList(),
        early.map((s) => (s.start, s.end)).toList());
    // This is the failure mechanism: the same observed night is rejected
    // once a low-HR waking tail changes the whole-stream median.
    expect(detect(40), isEmpty);
  });
}
