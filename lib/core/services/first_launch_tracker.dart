/// Отслеживает первый запуск приложения в текущей сессии
/// Используется для показа loading при первом открытии категории
class FirstLaunchTracker {
  FirstLaunchTracker._();

  static final FirstLaunchTracker instance = FirstLaunchTracker._();

  bool _isFirstLaunchInSession = false;
  bool _hasOpenedCategoryOnce = false;

  /// Вызывается из SplashScreen чтобы отметить что приложение только запустилось
  void markAppJustLaunched() {
    _isFirstLaunchInSession = true;
    _hasOpenedCategoryOnce = false;
  }

  /// Проверяет, нужно ли показывать loading при открытии категории
  bool shouldShowFirstCategoryLoading() {
    return _isFirstLaunchInSession && !_hasOpenedCategoryOnce;
  }

  /// Вызывается после показа loading в категории
  void markCategoryOpened() {
    _hasOpenedCategoryOnce = true;
  }
}
