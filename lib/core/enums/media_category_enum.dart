import 'package:flutter/material.dart';
enum PhotoCategory {
  similar,
  series,
  screenshots,
  blurry;
  String get name {
    switch (this) {
      case PhotoCategory.similar:
        return 'Похожие';
      case PhotoCategory.series:
        return 'Серии снимков';
      case PhotoCategory.screenshots:
        return 'Снимки экрана';
      case PhotoCategory.blurry:
        return 'Размытые';
    }
  }
  String get description {
    switch (this) {
      case PhotoCategory.similar:
        return 'Похожие фотографии';
      case PhotoCategory.series:
        return 'Серии фото';
      case PhotoCategory.screenshots:
        return 'Снимки экрана устройства';
      case PhotoCategory.blurry:
        return 'Нечеткие и размытые фотографии';
    }
  }
  IconData get icon {
    switch (this) {
      case PhotoCategory.similar:
        return Icons.image_search;
      case PhotoCategory.series:
        return Icons.content_copy;
      case PhotoCategory.screenshots:
        return Icons.screenshot;
      case PhotoCategory.blurry:
        return Icons.blur_on;
    }
  }
}
enum VideoCategory {
  duplicates,
  screenRecordings,
  shortVideos;
  String get name {
    switch (this) {
      case VideoCategory.duplicates:
        return 'Дубликаты';
      case VideoCategory.screenRecordings:
        return 'Записи экрана';
      case VideoCategory.shortVideos:
        return 'Короткие записи';
    }
  }
  String get description {
    switch (this) {
      case VideoCategory.duplicates:
        return 'Идентичные видеофайлы';
      case VideoCategory.screenRecordings:
        return 'Записи с экрана устройства';
      case VideoCategory.shortVideos:
        return 'Короткие видеофрагменты';
    }
  }
  IconData get icon {
    switch (this) {
      case VideoCategory.duplicates:
        return Icons.content_copy;
      case VideoCategory.screenRecordings:
        return Icons.video_camera_front;
      case VideoCategory.shortVideos:
        return Icons.timelapse;
    }
  }
}