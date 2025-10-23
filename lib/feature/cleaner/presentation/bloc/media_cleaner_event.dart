part of 'media_cleaner_bloc.dart';

@immutable
abstract class MediaCleanerEvent extends Equatable {
  const MediaCleanerEvent();

  @override
  List<Object> get props => [];
}

class LoadMediaFiles extends MediaCleanerEvent {}

class ScanForProblematicFiles extends MediaCleanerEvent {}

class ToggleFileSelection extends MediaCleanerEvent {
  final String fileId;

  const ToggleFileSelection(this.fileId);

  @override
  List<Object> get props => [fileId];
}

class SelectAllInCategory extends MediaCleanerEvent {
  final String category;
  final bool isPhoto;

  const SelectAllInCategory(this.category, {this.isPhoto = true});

  @override
  List<Object> get props => [category, isPhoto];
}

class UnselectAllFiles extends MediaCleanerEvent {}

class DeleteSelectedFiles extends MediaCleanerEvent {}

class ToggleFileSelectionById extends MediaCleanerEvent {
  final String fileId;

  const ToggleFileSelectionById(this.fileId);

  @override
  List<Object> get props => [fileId];
}

class SelectAllFiles extends MediaCleanerEvent {}

class SelectAllInGroup extends MediaCleanerEvent {
  final String groupId;

  const SelectAllInGroup(this.groupId);

  @override
  List<Object> get props => [groupId];
}

class PauseScanningEvent extends MediaCleanerEvent {}

class ResumeScanningEvent extends MediaCleanerEvent {}
