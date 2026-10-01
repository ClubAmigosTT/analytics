import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:openstrap_analytics/onehz.dart';

void main() {
  test('later waking HR cannot erase a night with a fixed detection reference',
      () {
    final start = DateTime.utc(2026, 9, 10, 12).millisecondsSinceEpoch ~/ 1000;
    final gravity = <GravTs>[];
    final hr = <HrTs>[];
    final rr = <RrTs>[];
    for (var i = 0; i < 40 * 3600; i++) {
      final hour = i / 3600;
      final asleep = hour >= 12 && hour < 18;
      gravity
          .add(GravTs(start + i, asleep ? 0 : 0.3 * math.sin(i * 0.5), 0, 1));
      hr.add(HrTs(start + i, hour < 12 ? 100 : (asleep ? 95 : 55)));
      // Timestamp rounding produces ties; beat order is still meaningful.
      rr.add(RrTs(start + i, 650 + 60 * math.sin(i * 0.13)));
      rr.add(RrTs(start + i, 690 + 50 * math.sin(i * 0.17)));
    }
    List<SleepSession> detect(int hours, {double? reference}) =>
        AdvancedSleepStager.detectSleep(
          gravity.sublist(0, hours * 3600),
          hr.sublist(0, hours * 3600),
          rr: rr.sublist(0, hours * 7200),
          detectionHrBaseline: reference,
        );
    final early = detect(19, reference: 100);
    final late = detect(40, reference: 100);
    expect(early, isNotEmpty);
    expect(late.map((s) => (s.start, s.end)).toList(),
        early.map((s) => (s.start, s.end)).toList());
    expect([
      for (final s in late)
        for (final e in s.stages) (e.start, e.end, e.stage)
    ], [
      for (final s in early)
        for (final e in s.stages) (e.start, e.end, e.stage)
    ], reason: 'Appending daytime beats must not reorder tied nighttime RR');
    // This is the failure mechanism: the same observed night is rejected
    // once a low-HR waking tail changes the whole-stream median.
    expect(detect(40), isEmpty);
  });
}
