import 'package:flutter_test/flutter_test.dart';
import 'package:spendpad/services/launch_experience_service.dart';

void main() {
  test('fresh installation receives the introduction', () {
    expect(
      LaunchExperienceService.shouldShowIntro(
        introCompleted: false,
        introPending: false,
        existingInstall: false,
      ),
      isTrue,
    );
  });

  test('existing installations skip introduction when upgraded', () {
    expect(
      LaunchExperienceService.shouldShowIntro(
        introCompleted: false,
        introPending: false,
        existingInstall: true,
      ),
      isFalse,
    );
  });

  test('an interrupted fresh launch keeps its pending introduction', () {
    expect(
      LaunchExperienceService.shouldShowIntro(
        introCompleted: false,
        introPending: true,
        existingInstall: true,
      ),
      isTrue,
    );
  });

  test('completed introduction never repeats', () {
    expect(
      LaunchExperienceService.shouldShowIntro(
        introCompleted: true,
        introPending: true,
        existingInstall: false,
      ),
      isFalse,
    );
  });
}
