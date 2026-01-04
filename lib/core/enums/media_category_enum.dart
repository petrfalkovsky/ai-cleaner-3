import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/material.dart';

enum PhotoCategory {
  similar,
  series,
  screenshots,
  blurry,
  livePhotos;

  String get title {
    switch (this) {
      case PhotoCategory.similar:
        return Locales.current.similar;
      case PhotoCategory.series:
        return Locales.current.photo_bursts;
      case PhotoCategory.screenshots:
        return Locales.current.screenshots;
      case PhotoCategory.blurry:
        return Locales.current.blurry;
      case PhotoCategory.livePhotos:
        return Locales.current.live_photos;
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
      case PhotoCategory.livePhotos:
        return Locales.current.live_photos_description;
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
      case PhotoCategory.livePhotos:
        return Icons.album;
    }
  }

  /// Проверяет, требует ли категория Premium подписку
  /// Бесплатно доступны только: similar и screenshots
  bool get requiresPremium {
    switch (this) {
      case PhotoCategory.similar:
      case PhotoCategory.screenshots:
        return false; // Доступны бесплатно
      case PhotoCategory.series:
      case PhotoCategory.blurry:
      case PhotoCategory.livePhotos:
        return true; // Требуют Premium
    }
  }
}

enum VideoCategory {
  duplicates,
  screenRecordings,
  shortVideos,
  largeVideos;

  String get title {
    switch (this) {
      case VideoCategory.duplicates:
        return Locales.current.duplicates;
      case VideoCategory.screenRecordings:
        return Locales.current.screen_recordings;
      case VideoCategory.shortVideos:
        return Locales.current.short_recordings;
      case VideoCategory.largeVideos:
        return Locales.current.large_videos;
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
      case VideoCategory.largeVideos:
        return Locales.current.large_videos_description;
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
      case VideoCategory.largeVideos:
        return Icons.folder;
    }
  }

  /// Проверяет, требует ли категория Premium подписку
  /// Все видео категории требуют Premium
  bool get requiresPremium {
    return true; // Все видео категории требуют Premium
  }
}

// Категория приложений (WhatsApp, Instagram, и т.д.)
enum AppCategory {
  whatsapp,
  instagram,
  telegram,
  messenger,
  snapchat;

  String get title {
    switch (this) {
      case AppCategory.whatsapp:
        return 'WhatsApp';
      case AppCategory.instagram:
        return 'Instagram';
      case AppCategory.telegram:
        return 'Telegram';
      case AppCategory.messenger:
        return 'Messenger';
      case AppCategory.snapchat:
        return 'Snapchat';
    }
  }

  String get description {
    switch (this) {
      case AppCategory.whatsapp:
        return Locales.current.whatsapp_media;
      case AppCategory.instagram:
        return Locales.current.instagram_media;
      case AppCategory.telegram:
        return Locales.current.telegram_media;
      case AppCategory.messenger:
        return Locales.current.messenger_media;
      case AppCategory.snapchat:
        return Locales.current.snapchat_media;
    }
  }

  IconData get icon {
    switch (this) {
      case AppCategory.whatsapp:
        return Icons.chat;
      case AppCategory.instagram:
        return Icons.photo_camera;
      case AppCategory.telegram:
        return Icons.send;
      case AppCategory.messenger:
        return Icons.messenger;
      case AppCategory.snapchat:
        return Icons.camera_alt;
    }
  }
}
