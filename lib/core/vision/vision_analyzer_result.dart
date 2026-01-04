/// Результат анализа Vision Framework для одного медиа-файла
class VisionAnalyzerResult {
  /// ID медиа-файла (AssetEntity.id)
  final String assetId;

  /// Уверенность в результате (0.0 - 1.0)
  /// 0.0 - нет уверенности, 1.0 - полная уверенность
  final double confidence;

  /// Должен ли файл быть включен в результаты
  /// (например, для blur detection: true = размыто, false = четкое)
  final bool shouldInclude;

  /// Анализатор включен и выполнил проверку
  final bool isEnabled;

  /// Дополнительные метаданные от Vision Framework
  final Map<String, dynamic>? metadata;

  /// Ошибка при анализе (если произошла)
  final String? error;

  const VisionAnalyzerResult({
    required this.assetId,
    required this.confidence,
    required this.shouldInclude,
    this.isEnabled = true,
    this.metadata,
    this.error,
  });

  /// Создает результат для отключенного анализатора
  factory VisionAnalyzerResult.disabled(String assetId) {
    return VisionAnalyzerResult(
      assetId: assetId,
      confidence: 0.0,
      shouldInclude: false,
      isEnabled: false,
    );
  }

  /// Создает результат с ошибкой
  factory VisionAnalyzerResult.error(String assetId, String error) {
    return VisionAnalyzerResult(
      assetId: assetId,
      confidence: 0.0,
      shouldInclude: false,
      error: error,
    );
  }

  /// Создает успешный результат
  factory VisionAnalyzerResult.success({
    required String assetId,
    required double confidence,
    required bool shouldInclude,
    Map<String, dynamic>? metadata,
  }) {
    return VisionAnalyzerResult(
      assetId: assetId,
      confidence: confidence,
      shouldInclude: shouldInclude,
      metadata: metadata,
    );
  }

  /// Проверяет, успешно ли выполнен анализ (без ошибок)
  bool get isSuccess => error == null && isEnabled;

  /// Проверяет, достаточно ли высокая уверенность для использования результата
  bool isConfident(double threshold) => confidence >= threshold;

  @override
  String toString() {
    return 'VisionAnalyzerResult('
        'assetId: $assetId, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'shouldInclude: $shouldInclude, '
        'isEnabled: $isEnabled, '
        'error: $error'
        ')';
  }
}
