import 'package:photo_manager/photo_manager.dart';
class MediaFile {
  final AssetEntity entity;
  final bool isSelected;
  final List<String> groups;
  final String? category;
  MediaFile({required this.entity, this.isSelected = false, this.groups = const [], this.category});
  MediaFile copyWith({
    AssetEntity? entity,
    bool? isSelected,
    List<String>? groups,
    String? category,
  }) {
    return MediaFile(
      entity: entity ?? this.entity,
      isSelected: isSelected ?? this.isSelected,
      groups: groups ?? this.groups,
      category: category ?? this.category,
    );
  }
  bool get isImage => entity.type == AssetType.image;
  bool get isVideo => entity.type == AssetType.video;
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