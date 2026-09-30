import 'package:test/test.dart';
import 'package:openstrap_analytics/onehz.dart';

void main() {
  test('low movement reference uses only measured quiet minutes', () {
    final hr = [...List<double>.filled(120, 85), ...List<double>.filled(60, 125)];
    final mask = [...List<bool>.filled(120, true), ...List<bool>.filled(60, false)];
    expect(lowMotionWakingHrr(hr, mask, restingHr: 60, maxHr: 185),
        closeTo(.2, 1e-9));
    expect(lowMotionWakingHrr(hr, mask.take(20).toList(),
        restingHr: 60, maxHr: 185), isNull);
  });

  test('later quiet minutes do not erase earlier load', () {
    final active = List<double>.filled(60, 125);
    final withRest = [...active, ...List<double>.filled(600, 85)];
    final first = personalStrainScore(active,
        restingHr: 60, maxHr: 185, quietHrr: .2, female: false);
    final last = personalStrainScore(withRest,
        restingHr: 60, maxHr: 185, quietHrr: .2, female: false);
    expect(first, greaterThan(0));
    expect(last, closeTo(first!, 1e-9));
  });

  test('missing or invalid anchors do not become a zero score', () {
    expect(personalStrainScore([125], restingHr: null,
        maxHr: 185, quietHrr: .2, female: false), isNull);
    expect(personalStrainScore([125], restingHr: 60,
        maxHr: 185, quietHrr: null, female: false), isNull);
    expect(personalStrainScore([125], restingHr: 60,
        maxHr: 185, quietHrr: double.nan, female: false), isNull);
  });
}
