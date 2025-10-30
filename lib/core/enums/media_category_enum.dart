import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/material.dart';

enum PhotoCategory {
  similar,
  series,
  screenshots,
  blurry;

  String get name {
    switch (this) {
      case PhotoCategory.similar:
        return Locales.current.similar;
      case PhotoCategory.series:
        return Locales.current.photo_bursts;
      case PhotoCategory.screenshots:
        return Locales.current.screenshots;
      case PhotoCategory.blurry:
        return Locales.current.blurry;
    }
  }

  String get description {
    switch (this) {
      case PhotoCategory.similar:
        return Locales.current.similar_photos;
      case PhotoCategory.series:
        return Locales.current.photo_series;
      case PhotoCategory.screenshots:
        return Locales.current.device_screenshots;
      case PhotoCategory.blurry:
        return Locales.current.blurry_not_clear_photos;
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
        return Locales.current.duplicates;
      case VideoCategory.screenRecordings:
        return Locales.current.screen_recordings;
      case VideoCategory.shortVideos:
        return Locales.current.short_recordings;
    }
  }

  String get description {
    switch (this) {
      case VideoCategory.duplicates:
        return Locales.current.identical_videos;
      case VideoCategory.screenRecordings:
        return Locales.current.device_screen_recordings;
      case VideoCategory.shortVideos:
        return Locales.current.short_video_clips;
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
