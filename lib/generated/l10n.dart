// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class Locales {
  Locales();

  static Locales? _current;

  static Locales get current {
    assert(
      _current != null,
      'No instance of Locales was loaded. Try to initialize the Locales delegate before accessing Locales.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<Locales> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = Locales();
      Locales._current = instance;

      return instance;
    });
  }

  static Locales of(BuildContext context) {
    final instance = Locales.maybeOf(context);
    assert(
      instance != null,
      'No instance of Locales present in the widget tree. Did you add Locales.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static Locales? maybeOf(BuildContext context) {
    return Localizations.of<Locales>(context, Locales);
  }

  /// `Clean your gallery`
  String get clean_your_gallery {
    return Intl.message(
      'Clean your gallery',
      name: 'clean_your_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Select`
  String get select {
    return Intl.message('Select', name: 'select', desc: '', args: []);
  }

  /// `Keep`
  String get keep {
    return Intl.message('Keep', name: 'keep', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Select all`
  String get select_all {
    return Intl.message('Select all', name: 'select_all', desc: '', args: []);
  }

  /// `No files in this category`
  String get no_files_in_category {
    return Intl.message(
      'No files in this category',
      name: 'no_files_in_category',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `AI Cleaner`
  String get ai_cleaner {
    return Intl.message('AI Cleaner', name: 'ai_cleaner', desc: '', args: []);
  }

  /// `Photos`
  String get photos {
    return Intl.message('Photos', name: 'photos', desc: '', args: []);
  }

  /// `Videos`
  String get videos {
    return Intl.message('Videos', name: 'videos', desc: '', args: []);
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `An error occurred`
  String get error_occurred {
    return Intl.message(
      'An error occurred',
      name: 'error_occurred',
      desc: '',
      args: [],
    );
  }

  /// `Find and delete unnecessary photos to free up space`
  String get find_and_delete_unnecessary_photos {
    return Intl.message(
      'Find and delete unnecessary photos to free up space',
      name: 'find_and_delete_unnecessary_photos',
      desc: '',
      args: [],
    );
  }

  /// `No issues found`
  String get no_issues_found {
    return Intl.message(
      'No issues found',
      name: 'no_issues_found',
      desc: '',
      args: [],
    );
  }

  /// `Your gallery is in great shape!`
  String get gallery_in_good_shape {
    return Intl.message(
      'Your gallery is in great shape!',
      name: 'gallery_in_good_shape',
      desc: '',
      args: [],
    );
  }

  /// `Problem photos`
  String get problem_photos {
    return Intl.message(
      'Problem photos',
      name: 'problem_photos',
      desc: '',
      args: [],
    );
  }

  /// `Updated:`
  String get updated {
    return Intl.message('Updated:', name: 'updated', desc: '', args: []);
  }

  /// `Rescan`
  String get rescan {
    return Intl.message('Rescan', name: 'rescan', desc: '', args: []);
  }

  /// `Clean videos`
  String get clean_videos {
    return Intl.message(
      'Clean videos',
      name: 'clean_videos',
      desc: '',
      args: [],
    );
  }

  /// `Find duplicate and unnecessary videos`
  String get find_duplicate_and_unnecessary_videos {
    return Intl.message(
      'Find duplicate and unnecessary videos',
      name: 'find_duplicate_and_unnecessary_videos',
      desc: '',
      args: [],
    );
  }

  /// `No issues found yet`
  String get no_video_issues_yet {
    return Intl.message(
      'No issues found yet',
      name: 'no_video_issues_yet',
      desc: '',
      args: [],
    );
  }

  /// `All videos are fine!`
  String get all_videos_ok {
    return Intl.message(
      'All videos are fine!',
      name: 'all_videos_ok',
      desc: '',
      args: [],
    );
  }

  /// `Problem videos`
  String get problem_videos {
    return Intl.message(
      'Problem videos',
      name: 'problem_videos',
      desc: '',
      args: [],
    );
  }

  /// `View`
  String get view {
    return Intl.message('View', name: 'view', desc: '', args: []);
  }

  /// `Unnamed file`
  String get unnamed_file {
    return Intl.message(
      'Unnamed file',
      name: 'unnamed_file',
      desc: '',
      args: [],
    );
  }

  /// `Image load error`
  String get image_load_error {
    return Intl.message(
      'Image load error',
      name: 'image_load_error',
      desc: '',
      args: [],
    );
  }

  /// `Preparing for scan...`
  String get preparing_for_scan {
    return Intl.message(
      'Preparing for scan...',
      name: 'preparing_for_scan',
      desc: '',
      args: [],
    );
  }

  /// `Start scan`
  String get start_scan {
    return Intl.message('Start scan', name: 'start_scan', desc: '', args: []);
  }

  /// `Scanning...`
  String get scanning {
    return Intl.message('Scanning...', name: 'scanning', desc: '', args: []);
  }

  /// `from`
  String get from {
    return Intl.message('from', name: 'from', desc: '', args: []);
  }

  /// `Please wait until the scan is complete for stable app performance.\nYour device may heat up. You can pause the scan for charging or cooling (feature in development).`
  String get scan_warning {
    return Intl.message(
      'Please wait until the scan is complete for stable app performance.\nYour device may heat up. You can pause the scan for charging or cooling (feature in development).',
      name: 'scan_warning',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get action_cannot_be_undone {
    return Intl.message(
      'This action cannot be undone.',
      name: 'action_cannot_be_undone',
      desc: '',
      args: [],
    );
  }

  /// `Loading videos...`
  String get loading_videos {
    return Intl.message(
      'Loading videos...',
      name: 'loading_videos',
      desc: '',
      args: [],
    );
  }

  /// `Delete files`
  String get delete_files {
    return Intl.message(
      'Delete files',
      name: 'delete_files',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete`
  String get are_you_sure_delete {
    return Intl.message(
      'Are you sure you want to delete',
      name: 'are_you_sure_delete',
      desc: '',
      args: [],
    );
  }

  /// `Video load error`
  String get video_load_error {
    return Intl.message(
      'Video load error',
      name: 'video_load_error',
      desc: '',
      args: [],
    );
  }

  /// `Files load error`
  String get files_load_error {
    return Intl.message(
      'Files load error',
      name: 'files_load_error',
      desc: '',
      args: [],
    );
  }

  /// `Try swipe mode`
  String get try_swipe_mode {
    return Intl.message(
      'Try swipe mode',
      name: 'try_swipe_mode',
      desc: '',
      args: [],
    );
  }

  /// `Delete or keep files with a simple swipe`
  String get swipe_hint {
    return Intl.message(
      'Delete or keep files with a simple swipe',
      name: 'swipe_hint',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message('Done', name: 'done', desc: '', args: []);
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Not found`
  String get not_found {
    return Intl.message('Not found', name: 'not_found', desc: '', args: []);
  }

  /// `Tra again`
  String get try_again {
    return Intl.message('Tra again', name: 'try_again', desc: '', args: []);
  }

  /// `Give gallery access`
  String get give_gallery_access {
    return Intl.message(
      'Give gallery access',
      name: 'give_gallery_access',
      desc: '',
      args: [],
    );
  }

  /// `AI Cleaner analyzes photos and videos to find duplicates, blurry images, and free up storage space.`
  String get ai_cleaner_description {
    return Intl.message(
      'AI Cleaner analyzes photos and videos to find duplicates, blurry images, and free up storage space.',
      name: 'ai_cleaner_description',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<Locales> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<Locales> load(Locale locale) => Locales.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
