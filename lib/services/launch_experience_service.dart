class LaunchExperienceService {
  LaunchExperienceService._();

  static bool shouldShowIntro({
    required bool introCompleted,
    required bool introPending,
    required bool existingInstall,
  }) => !introCompleted && (introPending || !existingInstall);
}
