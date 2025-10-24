part of 'media_cleaner_bloc.dart';
class MediaCleanerState extends Equatable {
  const MediaCleanerState();
  @override
  List<Object?> get props => [];
}
class MediaCleanerInitial extends MediaCleanerState {}
class MediaCleanerLoading extends MediaCleanerState {}
class MediaCleanerEmpty extends MediaCleanerState {}
class MediaCleanerError extends MediaCleanerState {
  final String message;
  const MediaCleanerError(this.message);
  @override
  List<Object> get props => [message];
}
class MediaCleanerLoaded extends MediaCleanerState {
  final List<MediaFile> allFiles;
  final List<MediaFile> photoFiles;
  final List<MediaFile> videoFiles;
  final List<MediaFile> selectedFiles;
  final bool isScanningInBackground;
  final String? scanError;
  const MediaCleanerLoaded({
    required this.allFiles,
    required this.photoFiles,
    required this.videoFiles,
    this.selectedFiles = const [],
    this.isScanningInBackground = false,
    this.scanError,
  });
  @override
  List<Object?> get props => [
    allFiles,
    photoFiles,
    videoFiles,
    selectedFiles,
    isScanningInBackground,
    scanError,
  ];
}
class MediaCleanerScanning extends MediaCleanerReady {
  final double scanProgress;
  final String scanMessage;
  final int? processedFiles;
  final int? totalFiles;
  final bool isPaused;
  const MediaCleanerScanning({
    required super.allFiles,
    required super.photoFiles,
    required super.videoFiles,
    super.selectedFiles = const [],
    this.scanProgress = 0.0,
    this.scanMessage = "Сканирование медиафайлов...",
    this.processedFiles,
    this.totalFiles,
    super.similarGroups = const [],
    super.screenshots = const [],
    super.blurry = const [],
    super.photoDuplicateGroups = const [],
    super.videoDuplicateGroups = const [],
    super.screenRecordings = const [],
    super.shortVideos = const [],
    super.lastScanTime,
    super.isScanningInBackground = true,
    super.scanError,
    this.isPaused = false,
  });
  @override
  List<Object?> get props => [
    ...super.props,
    scanProgress,
    scanMessage,
    processedFiles,
    totalFiles,
  ];
  @override
  MediaCleanerScanning copyWith({
    List<MediaFile>? allFiles,
    List<MediaFile>? photoFiles,
    List<MediaFile>? videoFiles,
    List<MediaFile>? selectedFiles,
    double? scanProgress,
    String? scanMessage,
    int? processedFiles,
    int? totalFiles,
    List<MediaGroup>? similarGroups,
    List<MediaFile>? screenshots,
    List<MediaFile>? blurry,
    List<MediaGroup>? photoDuplicateGroups,
    List<MediaGroup>? videoDuplicateGroups,
    List<MediaFile>? screenRecordings,
    List<MediaFile>? shortVideos,
    DateTime? lastScanTime,
    bool? isScanningInBackground,
    String? scanError,
    bool? isPaused,
  }) {
    return MediaCleanerScanning(
      allFiles: allFiles ?? this.allFiles,
      photoFiles: photoFiles ?? this.photoFiles,
      videoFiles: videoFiles ?? this.videoFiles,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      scanProgress: scanProgress ?? this.scanProgress,
      scanMessage: scanMessage ?? this.scanMessage,
      processedFiles: processedFiles ?? this.processedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      similarGroups: similarGroups ?? this.similarGroups,
      screenshots: screenshots ?? this.screenshots,
      blurry: blurry ?? this.blurry,
      photoDuplicateGroups: photoDuplicateGroups ?? this.photoDuplicateGroups,
      videoDuplicateGroups: videoDuplicateGroups ?? this.videoDuplicateGroups,
      screenRecordings: screenRecordings ?? this.screenRecordings,
      shortVideos: shortVideos ?? this.shortVideos,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      isScanningInBackground: isScanningInBackground ?? this.isScanningInBackground,
      scanError: scanError ?? this.scanError,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
class MediaCleanerReady extends MediaCleanerLoaded {
  final List<MediaGroup> similarGroups;
  final List<MediaFile> screenshots;
  final List<MediaFile> blurry;
  final List<MediaGroup> photoDuplicateGroups;
  final List<MediaGroup> videoDuplicateGroups;
  final List<MediaFile> shortVideos;
  final List<MediaFile> screenRecordings;
  final DateTime? lastScanTime;
  const MediaCleanerReady({
    required super.allFiles,
    required super.photoFiles,
    required super.videoFiles,
    super.selectedFiles,
    this.similarGroups = const [],
    this.screenshots = const [],
    this.blurry = const [],
    this.photoDuplicateGroups = const [],
    this.videoDuplicateGroups = const [],
    this.shortVideos = const [],
    this.screenRecordings = const [],
    this.lastScanTime,
    super.isScanningInBackground = false,
    super.scanError,
  });
  @override
  List<Object?> get props => [
    ...super.props,
    similarGroups,
    screenshots,
    blurry,
    photoDuplicateGroups,
    videoDuplicateGroups,
    shortVideos,
    screenRecordings,
    if (lastScanTime != null) lastScanTime!,
  ];
  @override
  MediaCleanerReady copyWith({
    List<MediaFile>? allFiles,
    List<MediaFile>? photoFiles,
    List<MediaFile>? videoFiles,
    List<MediaFile>? selectedFiles,
    List<MediaGroup>? similarGroups,
    List<MediaFile>? screenshots,
    List<MediaFile>? blurry,
    List<MediaGroup>? photoDuplicateGroups,
    List<MediaGroup>? videoDuplicateGroups,
    List<MediaFile>? shortVideos,
    List<MediaFile>? screenRecordings,
    DateTime? lastScanTime,
    bool? isScanningInBackground,
    String? scanError,
  }) {
    return MediaCleanerReady(
      allFiles: allFiles ?? this.allFiles,
      photoFiles: photoFiles ?? this.photoFiles,
      videoFiles: videoFiles ?? this.videoFiles,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      similarGroups: similarGroups ?? this.similarGroups,
      screenshots: screenshots ?? this.screenshots,
      blurry: blurry ?? this.blurry,
      photoDuplicateGroups: photoDuplicateGroups ?? this.photoDuplicateGroups,
      videoDuplicateGroups: videoDuplicateGroups ?? this.videoDuplicateGroups,
      shortVideos: shortVideos ?? this.shortVideos,
      screenRecordings: screenRecordings ?? this.screenRecordings,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      isScanningInBackground: isScanningInBackground ?? this.isScanningInBackground,
      scanError: scanError ?? this.scanError,
    );
  }
  int get similarCount => similarGroups.fold<int>(0, (sum, group) => sum + group.files.length);
  int get screenshotsCount => screenshots.length;
  int get blurryCount => blurry.length;
  int get photoDuplicatesCount =>
      photoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length);
  int get videoDuplicatesCount =>
      videoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length);
  int get shortVideosCount => shortVideos.length;
  int get screenRecordingsCount => screenRecordings.length;
}