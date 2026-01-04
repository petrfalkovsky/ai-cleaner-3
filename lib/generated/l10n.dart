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
    assert(_current != null,
        'No instance of Locales was loaded. Try to initialize the Locales delegate before accessing Locales.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<Locales> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
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
    assert(instance != null,
        'No instance of Locales present in the widget tree. Did you add Locales.delegate in localizationsDelegates?');
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
    return Intl.message(
      'Select',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Keep`
  String get keep {
    return Intl.message(
      'Keep',
      name: 'keep',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get select_all {
    return Intl.message(
      'Select all',
      name: 'select_all',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `AI Cleaner`
  String get ai_cleaner {
    return Intl.message(
      'AI Cleaner',
      name: 'ai_cleaner',
      desc: '',
      args: [],
    );
  }

  /// `Photos`
  String get photos {
    return Intl.message(
      'Photos',
      name: 'photos',
      desc: '',
      args: [],
    );
  }

  /// `Videos`
  String get videos {
    return Intl.message(
      'Videos',
      name: 'videos',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Updated:',
      name: 'updated',
      desc: '',
      args: [],
    );
  }

  /// `Rescan`
  String get rescan {
    return Intl.message(
      'Rescan',
      name: 'rescan',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'View',
      name: 'view',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Start scan',
      name: 'start_scan',
      desc: '',
      args: [],
    );
  }

  /// `Scanning...`
  String get scanning {
    return Intl.message(
      'Scanning...',
      name: 'scanning',
      desc: '',
      args: [],
    );
  }

  /// `from`
  String get from {
    return Intl.message(
      'from',
      name: 'from',
      desc: '',
      args: [],
    );
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

  /// `Please wait until the scan is complete`
  String get please_wait {
    return Intl.message(
      'Please wait until the scan is complete',
      name: 'please_wait',
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
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Not found`
  String get not_found {
    return Intl.message(
      'Not found',
      name: 'not_found',
      desc: '',
      args: [],
    );
  }

  /// `Tra again`
  String get try_again {
    return Intl.message(
      'Tra again',
      name: 'try_again',
      desc: '',
      args: [],
    );
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

  /// `Permission required to access gallery`
  String get gallery_permission_required {
    return Intl.message(
      'Permission required to access gallery',
      name: 'gallery_permission_required',
      desc: '',
      args: [],
    );
  }

  /// `Файл`
  String get file {
    return Intl.message(
      'Файл',
      name: 'file',
      desc: '',
      args: [],
    );
  }

  /// `Файлов`
  String get files {
    return Intl.message(
      'Файлов',
      name: 'files',
      desc: '',
      args: [],
    );
  }

  /// `Файла`
  String get a_file {
    return Intl.message(
      'Файла',
      name: 'a_file',
      desc: '',
      args: [],
    );
  }

  /// `Similar`
  String get similar {
    return Intl.message(
      'Similar',
      name: 'similar',
      desc: '',
      args: [],
    );
  }

  /// `Photo bursts`
  String get photo_bursts {
    return Intl.message(
      'Photo bursts',
      name: 'photo_bursts',
      desc: '',
      args: [],
    );
  }

  /// `Screenshots`
  String get screenshots {
    return Intl.message(
      'Screenshots',
      name: 'screenshots',
      desc: '',
      args: [],
    );
  }

  /// `Blurry`
  String get blurry {
    return Intl.message(
      'Blurry',
      name: 'blurry',
      desc: '',
      args: [],
    );
  }

  /// `Similar photos`
  String get similar_photos {
    return Intl.message(
      'Similar photos',
      name: 'similar_photos',
      desc: '',
      args: [],
    );
  }

  /// `Photo series`
  String get photo_series {
    return Intl.message(
      'Photo series',
      name: 'photo_series',
      desc: '',
      args: [],
    );
  }

  /// `Device screenshots`
  String get device_screenshots {
    return Intl.message(
      'Device screenshots',
      name: 'device_screenshots',
      desc: '',
      args: [],
    );
  }

  /// `Blurry and unclear photos`
  String get blurry_not_clear_photos {
    return Intl.message(
      'Blurry and unclear photos',
      name: 'blurry_not_clear_photos',
      desc: '',
      args: [],
    );
  }

  /// `Duplicates`
  String get duplicates {
    return Intl.message(
      'Duplicates',
      name: 'duplicates',
      desc: '',
      args: [],
    );
  }

  /// `Screen recordings`
  String get screen_recordings {
    return Intl.message(
      'Screen recordings',
      name: 'screen_recordings',
      desc: '',
      args: [],
    );
  }

  /// `Short recordings`
  String get short_recordings {
    return Intl.message(
      'Short recordings',
      name: 'short_recordings',
      desc: '',
      args: [],
    );
  }

  /// `Identical video files`
  String get identical_videos {
    return Intl.message(
      'Identical video files',
      name: 'identical_videos',
      desc: '',
      args: [],
    );
  }

  /// `Device screen recordings`
  String get device_screen_recordings {
    return Intl.message(
      'Device screen recordings',
      name: 'device_screen_recordings',
      desc: '',
      args: [],
    );
  }

  /// `Short video clips`
  String get short_video_clips {
    return Intl.message(
      'Short video clips',
      name: 'short_video_clips',
      desc: '',
      args: [],
    );
  }

  /// `Short video clips`
  String get short_video_clips_ {
    return Intl.message(
      'Short video clips',
      name: 'short_video_clips_',
      desc: '',
      args: [],
    );
  }

  /// `AI model is searching for screenshots...`
  String get ai_model_searching_screenshots {
    return Intl.message(
      'AI model is searching for screenshots...',
      name: 'ai_model_searching_screenshots',
      desc: '',
      args: [],
    );
  }

  /// `AI model is grouping similar photos...`
  String get ai_model_grouping_similar_photos {
    return Intl.message(
      'AI model is grouping similar photos...',
      name: 'ai_model_grouping_similar_photos',
      desc: '',
      args: [],
    );
  }

  /// `Found`
  String get found {
    return Intl.message(
      'Found',
      name: 'found',
      desc: '',
      args: [],
    );
  }

  /// `Screenshots`
  String get screenshots_count {
    return Intl.message(
      'Screenshots',
      name: 'screenshots_count',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate photo groups`
  String get duplicate_photo_groups {
    return Intl.message(
      'Duplicate photo groups',
      name: 'duplicate_photo_groups',
      desc: '',
      args: [],
    );
  }

  /// `Searching duplicate photos (processed`
  String get searching_duplicate_photos_processed {
    return Intl.message(
      'Searching duplicate photos (processed',
      name: 'searching_duplicate_photos_processed',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate groups`
  String get duplicate_groups {
    return Intl.message(
      'Duplicate groups',
      name: 'duplicate_groups',
      desc: '',
      args: [],
    );
  }

  /// `Groups of similar photos`
  String get similar_photo_groups_multiline {
    return Intl.message(
      'Groups of similar photos',
      name: 'similar_photo_groups_multiline',
      desc: '',
      args: [],
    );
  }

  /// `Searching similar photos (processed`
  String get searching_similar_photos_processed {
    return Intl.message(
      'Searching similar photos (processed',
      name: 'searching_similar_photos_processed',
      desc: '',
      args: [],
    );
  }

  /// `AI model is searching for blurry photos...`
  String get ai_model_searching_blurry_photos {
    return Intl.message(
      'AI model is searching for blurry photos...',
      name: 'ai_model_searching_blurry_photos',
      desc: '',
      args: [],
    );
  }

  /// `New`
  String get new_word {
    return Intl.message(
      'New',
      name: 'new_word',
      desc: '',
      args: [],
    );
  }

  /// `Screen recordings`
  String get screen_recordings_2 {
    return Intl.message(
      'Screen recordings',
      name: 'screen_recordings_2',
      desc: '',
      args: [],
    );
  }

  /// `Blurry photos`
  String get blurry_photos {
    return Intl.message(
      'Blurry photos',
      name: 'blurry_photos',
      desc: '',
      args: [],
    );
  }

  /// `AI model is analyzing videos...`
  String get ai_model_analyzing_videos {
    return Intl.message(
      'AI model is analyzing videos...',
      name: 'ai_model_analyzing_videos',
      desc: '',
      args: [],
    );
  }

  /// `Analyzing videos (processed`
  String get analyzing_videos_processed {
    return Intl.message(
      'Analyzing videos (processed',
      name: 'analyzing_videos_processed',
      desc: '',
      args: [],
    );
  }

  /// `Short videos`
  String get short_videos {
    return Intl.message(
      'Short videos',
      name: 'short_videos',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
      desc: '',
      args: [],
    );
  }

  /// `Restore purchases`
  String get restore_purchases {
    return Intl.message(
      'Restore purchases',
      name: 'restore_purchases',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get feedback {
    return Intl.message(
      'Feedback',
      name: 'feedback',
      desc: '',
      args: [],
    );
  }

  /// `Contact & Feedback`
  String get contact_and_feedback {
    return Intl.message(
      'Contact & Feedback',
      name: 'contact_and_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Rate app`
  String get rate_app {
    return Intl.message(
      'Rate app',
      name: 'rate_app',
      desc: '',
      args: [],
    );
  }

  /// `Share app`
  String get share_app {
    return Intl.message(
      'Share app',
      name: 'share_app',
      desc: '',
      args: [],
    );
  }

  /// `Policy`
  String get policy {
    return Intl.message(
      'Policy',
      name: 'policy',
      desc: '',
      args: [],
    );
  }

  /// `Terms & Privacy`
  String get terms_and_privacy {
    return Intl.message(
      'Terms & Privacy',
      name: 'terms_and_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacy_policy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacy_policy',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `No purchases to restore`
  String get no_purchases_to_restore {
    return Intl.message(
      'No purchases to restore',
      name: 'no_purchases_to_restore',
      desc: '',
      args: [],
    );
  }

  /// `Products are not loaded yet. Please try again in a moment.`
  String get products_not_loaded {
    return Intl.message(
      'Products are not loaded yet. Please try again in a moment.',
      name: 'products_not_loaded',
      desc: '',
      args: [],
    );
  }

  /// `We'd love to hear from you!`
  String get we_love_to_hear_from_you {
    return Intl.message(
      'We\'d love to hear from you!',
      name: 'we_love_to_hear_from_you',
      desc: '',
      args: [],
    );
  }

  /// `Send us your feedback or questions`
  String get send_us_your_feedback {
    return Intl.message(
      'Send us your feedback or questions',
      name: 'send_us_your_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Enter your name`
  String get enter_your_name {
    return Intl.message(
      'Enter your name',
      name: 'enter_your_name',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get enter_your_email {
    return Intl.message(
      'Enter your email',
      name: 'enter_your_email',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get message {
    return Intl.message(
      'Message',
      name: 'message',
      desc: '',
      args: [],
    );
  }

  /// `Enter your message`
  String get enter_your_message {
    return Intl.message(
      'Enter your message',
      name: 'enter_your_message',
      desc: '',
      args: [],
    );
  }

  /// `Send Feedback`
  String get send_feedback {
    return Intl.message(
      'Send Feedback',
      name: 'send_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Please fill in all fields`
  String get please_fill_all_fields {
    return Intl.message(
      'Please fill in all fields',
      name: 'please_fill_all_fields',
      desc: '',
      args: [],
    );
  }

  /// `Failed to send feedback. Please try again.`
  String get failed_to_send_feedback {
    return Intl.message(
      'Failed to send feedback. Please try again.',
      name: 'failed_to_send_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Thank You!`
  String get thank_you {
    return Intl.message(
      'Thank You!',
      name: 'thank_you',
      desc: '',
      args: [],
    );
  }

  /// `Your feedback has been sent successfully. We'll get back to you soon!`
  String get feedback_sent_successfully {
    return Intl.message(
      'Your feedback has been sent successfully. We\'ll get back to you soon!',
      name: 'feedback_sent_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Back to Home`
  String get back_to_home {
    return Intl.message(
      'Back to Home',
      name: 'back_to_home',
      desc: '',
      args: [],
    );
  }

  /// `iPhone Storage Full`
  String get iphone_storage_full {
    return Intl.message(
      'iPhone Storage Full',
      name: 'iphone_storage_full',
      desc: '',
      args: [],
    );
  }

  /// `Storage`
  String get storage {
    return Intl.message(
      'Storage',
      name: 'storage',
      desc: '',
      args: [],
    );
  }

  /// `Trial version enabled`
  String get trial_enabled {
    return Intl.message(
      'Trial version enabled',
      name: 'trial_enabled',
      desc: '',
      args: [],
    );
  }

  /// `Start Free Trial`
  String get start_trial {
    return Intl.message(
      'Start Free Trial',
      name: 'start_trial',
      desc: '',
      args: [],
    );
  }

  /// `Cancel anytime. Payment will be charged to your iTunes account. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.`
  String get subscription_terms {
    return Intl.message(
      'Cancel anytime. Payment will be charged to your iTunes account. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.',
      name: 'subscription_terms',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get success {
    return Intl.message(
      'Success',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `Your trial has been activated successfully!`
  String get trial_activated {
    return Intl.message(
      'Your trial has been activated successfully!',
      name: 'trial_activated',
      desc: '',
      args: [],
    );
  }

  /// `then`
  String get then {
    return Intl.message(
      'then',
      name: 'then',
      desc: '',
      args: [],
    );
  }

  /// `on`
  String get on {
    return Intl.message(
      'on',
      name: 'on',
      desc: '',
      args: [],
    );
  }

  /// `freed`
  String get freed {
    return Intl.message(
      'freed',
      name: 'freed',
      desc: '',
      args: [],
    );
  }

  /// `of`
  String get of_1 {
    return Intl.message(
      'of',
      name: 'of_1',
      desc: '',
      args: [],
    );
  }

  /// `free`
  String get free {
    return Intl.message(
      'free',
      name: 'free',
      desc: '',
      args: [],
    );
  }

  /// `used`
  String get used {
    return Intl.message(
      'used',
      name: 'used',
      desc: '',
      args: [],
    );
  }

  /// `Live Photos`
  String get live_photos {
    return Intl.message(
      'Live Photos',
      name: 'live_photos',
      desc: '',
      args: [],
    );
  }

  /// `Photos with Live Photo video effect`
  String get live_photos_description {
    return Intl.message(
      'Photos with Live Photo video effect',
      name: 'live_photos_description',
      desc: '',
      args: [],
    );
  }

  /// `Large Videos`
  String get large_videos {
    return Intl.message(
      'Large Videos',
      name: 'large_videos',
      desc: '',
      args: [],
    );
  }

  /// `Videos larger than 180 MB`
  String get large_videos_description {
    return Intl.message(
      'Videos larger than 180 MB',
      name: 'large_videos_description',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp Media`
  String get whatsapp_media {
    return Intl.message(
      'WhatsApp Media',
      name: 'whatsapp_media',
      desc: '',
      args: [],
    );
  }

  /// `Instagram Media`
  String get instagram_media {
    return Intl.message(
      'Instagram Media',
      name: 'instagram_media',
      desc: '',
      args: [],
    );
  }

  /// `Telegram Media`
  String get telegram_media {
    return Intl.message(
      'Telegram Media',
      name: 'telegram_media',
      desc: '',
      args: [],
    );
  }

  /// `Messenger Media`
  String get messenger_media {
    return Intl.message(
      'Messenger Media',
      name: 'messenger_media',
      desc: '',
      args: [],
    );
  }

  /// `Snapchat Media`
  String get snapchat_media {
    return Intl.message(
      'Snapchat Media',
      name: 'snapchat_media',
      desc: '',
      args: [],
    );
  }

  /// `From Apps`
  String get app_media {
    return Intl.message(
      'From Apps',
      name: 'app_media',
      desc: '',
      args: [],
    );
  }

  /// `Purchased`
  String get purchased {
    return Intl.message(
      'Purchased',
      name: 'purchased',
      desc: '',
      args: [],
    );
  }

  /// `Scanning media files...`
  String get scanning_media_files {
    return Intl.message(
      'Scanning media files...',
      name: 'scanning_media_files',
      desc: '',
      args: [],
    );
  }

  /// `Scanning already in progress...`
  String get scanning_already_in_progress {
    return Intl.message(
      'Scanning already in progress...',
      name: 'scanning_already_in_progress',
      desc: '',
      args: [],
    );
  }

  /// `Scan completed`
  String get scan_completed {
    return Intl.message(
      'Scan completed',
      name: 'scan_completed',
      desc: '',
      args: [],
    );
  }

  /// `Pro`
  String get pro {
    return Intl.message(
      'Pro',
      name: 'pro',
      desc: '',
      args: [],
    );
  }

  /// `Scan completed!`
  String get scan_completed_exclamation {
    return Intl.message(
      'Scan completed!',
      name: 'scan_completed_exclamation',
      desc: '',
      args: [],
    );
  }

  /// `Searching for Live Photos...`
  String get searching_live_photos {
    return Intl.message(
      'Searching for Live Photos...',
      name: 'searching_live_photos',
      desc: '',
      args: [],
    );
  }

  /// `Searching for large videos (>180MB)...`
  String get searching_large_videos {
    return Intl.message(
      'Searching for large videos (>180MB)...',
      name: 'searching_large_videos',
      desc: '',
      args: [],
    );
  }

  /// `Searching for app media...`
  String get searching_app_media {
    return Intl.message(
      'Searching for app media...',
      name: 'searching_app_media',
      desc: '',
      args: [],
    );
  }

  /// `Files from apps`
  String get files_from_apps {
    return Intl.message(
      'Files from apps',
      name: 'files_from_apps',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get weekly {
    return Intl.message(
      'Weekly',
      name: 'weekly',
      desc: '',
      args: [],
    );
  }

  /// `Yearly`
  String get yearly {
    return Intl.message(
      'Yearly',
      name: 'yearly',
      desc: '',
      args: [],
    );
  }

  /// `Lifetime`
  String get lifetime {
    return Intl.message(
      'Lifetime',
      name: 'lifetime',
      desc: '',
      args: [],
    );
  }

  /// `MOST POPULAR`
  String get most_popular {
    return Intl.message(
      'MOST POPULAR',
      name: 'most_popular',
      desc: '',
      args: [],
    );
  }

  /// `BEST VALUE`
  String get best_value {
    return Intl.message(
      'BEST VALUE',
      name: 'best_value',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continue_action {
    return Intl.message(
      'Continue',
      name: 'continue_action',
      desc: '',
      args: [],
    );
  }

  /// `/week`
  String get per_week {
    return Intl.message(
      '/week',
      name: 'per_week',
      desc: '',
      args: [],
    );
  }

  /// `/year`
  String get per_year {
    return Intl.message(
      '/year',
      name: 'per_year',
      desc: '',
      args: [],
    );
  }

  /// `one-time`
  String get one_time_purchase {
    return Intl.message(
      'one-time',
      name: 'one_time_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Billed weekly`
  String get billed_weekly {
    return Intl.message(
      'Billed weekly',
      name: 'billed_weekly',
      desc: '',
      args: [],
    );
  }

  /// `Save 35% vs weekly`
  String get save_vs_weekly {
    return Intl.message(
      'Save 35% vs weekly',
      name: 'save_vs_weekly',
      desc: '',
      args: [],
    );
  }

  /// `Unlock forever`
  String get unlock_forever {
    return Intl.message(
      'Unlock forever',
      name: 'unlock_forever',
      desc: '',
      args: [],
    );
  }

  /// `Selected`
  String get selected {
    return Intl.message(
      'Selected',
      name: 'selected',
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
