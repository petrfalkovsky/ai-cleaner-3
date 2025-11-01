import 'package:photo_manager/photo_manager.dart';

class MediaFile {
  final AssetEntity entity;
  final bool isSelected;
  final List<String> groups;
  final String? category;
  final Map<String, dynamic>? metadata; // Метаданные из нативного iOS кода

  MediaFile({
    required this.entity,
    this.isSelected = false,
    this.groups = const [],
    this.category,
    this.metadata,
  });

  MediaFile copyWith({
    AssetEntity? entity,
    bool? isSelected,
    List<String>? groups,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return MediaFile(
      entity: entity ?? this.entity,
      isSelected: isSelected ?? this.isSelected,
      groups: groups ?? this.groups,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isImage => entity.type == AssetType.image;
  bool get isVideo => entity.type == AssetType.video;

  /// Является ли видео записью экрана (из iOS метаданных)
  bool get isScreenRecording {
    if (!isVideo) return false;
    return metadata?['isScreenRecording'] == true;
  }
}

class MediaGroup {
  final String id;
  final String name;
  final List<MediaFile> files;

  MediaGroup({required this.id, required this.name, required this.files});

  bool get allSelected => files.every((file) => file.isSelected);
  bool get anySelected => files.any((file) => file.isSelected);
  int get selectedCount => files.where((file) => file.isSelected).length;

  MediaGroup copyWith({String? id, String? name, List<MediaFile>? files}) {
    return MediaGroup(id: id ?? this.id, name: name ?? this.name, files: files ?? this.files);
  }
}
