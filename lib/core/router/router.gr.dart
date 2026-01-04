// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ai_cleaner_2/app/permission_request/permission_request_page.dart'
    as _i17;
import 'package:ai_cleaner_2/app/root/app_root.dart' as _i3;
import 'package:ai_cleaner_2/app/settings/page/settings_shell_page.dart'
    as _i20;
import 'package:ai_cleaner_2/app/settings/sections/about_page.dart' as _i1;
import 'package:ai_cleaner_2/app/settings/sections/privacy_policy_page.dart'
    as _i18;
import 'package:ai_cleaner_2/app/splash_screen/splash_screen.dart' as _i21;
import 'package:ai_cleaner_2/core/widgets/alert_widget.dart' as _i26;
import 'package:ai_cleaner_2/core/widgets/common/date_time_picker.dart' as _i8;
import 'package:ai_cleaner_2/core/widgets/common/widgets/styled_alert_dialog.dart'
    as _i2;
import 'package:ai_cleaner_2/core/widgets/info_modals/error_modal.dart' as _i9;
import 'package:ai_cleaner_2/core/widgets/info_modals/info_modal.dart' as _i14;
import 'package:ai_cleaner_2/feature/categories/presentation/pages/categories_page.dart'
    as _i4;
import 'package:ai_cleaner_2/feature/categories/presentation/pages/categories_swiper_page.dart'
    as _i5;
import 'package:ai_cleaner_2/feature/categories/presentation/pages/category_page.dart'
    as _i7;
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart'
    as _i29;
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/category_page.dart'
    as _i6;
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/home_page.dart'
    as _i12;
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/media_preview_page.dart'
    as _i15;
import 'package:ai_cleaner_2/feature/gallery/presentation/pages/image_full_screen.dart'
    as _i13;
import 'package:ai_cleaner_2/feature/gallery/presentation/pages/video_full_screen.dart'
    as _i23;
import 'package:ai_cleaner_2/feature/premium/presentation/pages/paywall_three_plans_screen.dart'
    as _i16;
import 'package:ai_cleaner_2/feature/settings/presentation/pages/feedback_screen.dart'
    as _i10;
import 'package:ai_cleaner_2/feature/settings/presentation/pages/feedback_success_screen.dart'
    as _i11;
import 'package:ai_cleaner_2/feature/settings/presentation/pages/settings_screen.dart'
    as _i19;
import 'package:ai_cleaner_2/feature/swipe/presentation/pages/swipe_screen.dart'
    as _i22;
import 'package:auto_route/auto_route.dart' as _i24;
import 'package:flutter/cupertino.dart' as _i27;
import 'package:flutter/material.dart' as _i25;
import 'package:photo_manager/photo_manager.dart' as _i28;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i24.PageRouteInfo<void> {
  const AboutRoute({List<_i24.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.AlertDialogPage]
class AlertDialogRoute extends _i24.PageRouteInfo<AlertDialogRouteArgs> {
  AlertDialogRoute({
    _i25.Key? key,
    required String title,
    String? subtitle,
    _i25.Widget? leading,
    _i25.Widget? trailing,
    void Function(_i25.BuildContext)? onAccept,
    void Function(_i25.BuildContext)? onCancel,
    bool withEasterEgg = true,
    _i26.AlertLevel level = _i26.AlertLevel.warning,
    bool autoPop = false,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         AlertDialogRoute.name,
         args: AlertDialogRouteArgs(
           key: key,
           title: title,
           subtitle: subtitle,
           leading: leading,
           trailing: trailing,
           onAccept: onAccept,
           onCancel: onCancel,
           withEasterEgg: withEasterEgg,
           level: level,
           autoPop: autoPop,
         ),
         initialChildren: children,
       );

  static const String name = 'AlertDialogRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AlertDialogRouteArgs>();
      return _i2.AlertDialogPage(
        key: args.key,
        title: args.title,
        subtitle: args.subtitle,
        leading: args.leading,
        trailing: args.trailing,
        onAccept: args.onAccept,
        onCancel: args.onCancel,
        withEasterEgg: args.withEasterEgg,
        level: args.level,
        autoPop: args.autoPop,
      );
    },
  );
}

class AlertDialogRouteArgs {
  const AlertDialogRouteArgs({
    this.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onAccept,
    this.onCancel,
    this.withEasterEgg = true,
    this.level = _i26.AlertLevel.warning,
    this.autoPop = false,
  });

  final _i25.Key? key;

  final String title;

  final String? subtitle;

  final _i25.Widget? leading;

  final _i25.Widget? trailing;

  final void Function(_i25.BuildContext)? onAccept;

  final void Function(_i25.BuildContext)? onCancel;

  final bool withEasterEgg;

  final _i26.AlertLevel level;

  final bool autoPop;

  @override
  String toString() {
    return 'AlertDialogRouteArgs{key: $key, title: $title, subtitle: $subtitle, leading: $leading, trailing: $trailing, onAccept: $onAccept, onCancel: $onCancel, withEasterEgg: $withEasterEgg, level: $level, autoPop: $autoPop}';
  }
}

/// generated route for
/// [_i3.AppRootPage]
class AppRootRoute extends _i24.PageRouteInfo<void> {
  const AppRootRoute({List<_i24.PageRouteInfo>? children})
    : super(AppRootRoute.name, initialChildren: children);

  static const String name = 'AppRootRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i3.AppRootPage();
    },
  );
}

/// generated route for
/// [_i4.CategoriesPage]
class CategoriesRoute extends _i24.PageRouteInfo<void> {
  const CategoriesRoute({List<_i24.PageRouteInfo>? children})
    : super(CategoriesRoute.name, initialChildren: children);

  static const String name = 'CategoriesRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i4.CategoriesPage();
    },
  );
}

/// generated route for
/// [_i5.CategoriesSwiperPage]
class CategoriesSwiperRoute
    extends _i24.PageRouteInfo<CategoriesSwiperRouteArgs> {
  CategoriesSwiperRoute({
    _i27.Key? key,
    required List<String> ids,
    required String title,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         CategoriesSwiperRoute.name,
         args: CategoriesSwiperRouteArgs(key: key, ids: ids, title: title),
         initialChildren: children,
       );

  static const String name = 'CategoriesSwiperRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CategoriesSwiperRouteArgs>();
      return _i5.CategoriesSwiperPage(
        key: args.key,
        ids: args.ids,
        title: args.title,
      );
    },
  );
}

class CategoriesSwiperRouteArgs {
  const CategoriesSwiperRouteArgs({
    this.key,
    required this.ids,
    required this.title,
  });

  final _i27.Key? key;

  final List<String> ids;

  final String title;

  @override
  String toString() {
    return 'CategoriesSwiperRouteArgs{key: $key, ids: $ids, title: $title}';
  }
}

/// generated route for
/// [_i6.CategoryPage]
class CategoryRoute extends _i24.PageRouteInfo<CategoryRouteArgs> {
  CategoryRoute({
    _i27.Key? key,
    required String categoryType,
    required String categoryName,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         CategoryRoute.name,
         args: CategoryRouteArgs(
           key: key,
           categoryType: categoryType,
           categoryName: categoryName,
         ),
         initialChildren: children,
       );

  static const String name = 'CategoryRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CategoryRouteArgs>();
      return _i6.CategoryPage(
        key: args.key,
        categoryType: args.categoryType,
        categoryName: args.categoryName,
      );
    },
  );
}

class CategoryRouteArgs {
  const CategoryRouteArgs({
    this.key,
    required this.categoryType,
    required this.categoryName,
  });

  final _i27.Key? key;

  final String categoryType;

  final String categoryName;

  @override
  String toString() {
    return 'CategoryRouteArgs{key: $key, categoryType: $categoryType, categoryName: $categoryName}';
  }
}

/// generated route for
/// [_i7.CategoryPageOld]
class CategoryRouteOld extends _i24.PageRouteInfo<CategoryRouteOldArgs> {
  CategoryRouteOld({
    _i25.Key? key,
    required _i4.AssetCategory category,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         CategoryRouteOld.name,
         args: CategoryRouteOldArgs(key: key, category: category),
         initialChildren: children,
       );

  static const String name = 'CategoryRouteOld';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CategoryRouteOldArgs>();
      return _i7.CategoryPageOld(key: args.key, category: args.category);
    },
  );
}

class CategoryRouteOldArgs {
  const CategoryRouteOldArgs({this.key, required this.category});

  final _i25.Key? key;

  final _i4.AssetCategory category;

  @override
  String toString() {
    return 'CategoryRouteOldArgs{key: $key, category: $category}';
  }
}

/// generated route for
/// [_i8.DateTimePickerBottomSheetPage]
class DateTimePickerBottomSheetRoute
    extends _i24.PageRouteInfo<DateTimePickerBottomSheetRouteArgs> {
  DateTimePickerBottomSheetRoute({
    _i27.Key? key,
    DateTime? initialDate,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         DateTimePickerBottomSheetRoute.name,
         args: DateTimePickerBottomSheetRouteArgs(
           key: key,
           initialDate: initialDate,
         ),
         initialChildren: children,
       );

  static const String name = 'DateTimePickerBottomSheetRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DateTimePickerBottomSheetRouteArgs>(
        orElse: () => const DateTimePickerBottomSheetRouteArgs(),
      );
      return _i8.DateTimePickerBottomSheetPage(
        key: args.key,
        initialDate: args.initialDate,
      );
    },
  );
}

class DateTimePickerBottomSheetRouteArgs {
  const DateTimePickerBottomSheetRouteArgs({this.key, this.initialDate});

  final _i27.Key? key;

  final DateTime? initialDate;

  @override
  String toString() {
    return 'DateTimePickerBottomSheetRouteArgs{key: $key, initialDate: $initialDate}';
  }
}

/// generated route for
/// [_i9.ErrorModalPage]
class ErrorModalRoute extends _i24.PageRouteInfo<ErrorModalRouteArgs> {
  ErrorModalRoute({
    _i25.Key? key,
    required String message,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         ErrorModalRoute.name,
         args: ErrorModalRouteArgs(key: key, message: message),
         initialChildren: children,
       );

  static const String name = 'ErrorModalRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ErrorModalRouteArgs>();
      return _i9.ErrorModalPage(key: args.key, message: args.message);
    },
  );
}

class ErrorModalRouteArgs {
  const ErrorModalRouteArgs({this.key, required this.message});

  final _i25.Key? key;

  final String message;

  @override
  String toString() {
    return 'ErrorModalRouteArgs{key: $key, message: $message}';
  }
}

/// generated route for
/// [_i10.FeedbackScreen]
class FeedbackRoute extends _i24.PageRouteInfo<void> {
  const FeedbackRoute({List<_i24.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i10.FeedbackScreen();
    },
  );
}

/// generated route for
/// [_i11.FeedbackSuccessScreen]
class FeedbackSuccessRoute extends _i24.PageRouteInfo<void> {
  const FeedbackSuccessRoute({List<_i24.PageRouteInfo>? children})
    : super(FeedbackSuccessRoute.name, initialChildren: children);

  static const String name = 'FeedbackSuccessRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i11.FeedbackSuccessScreen();
    },
  );
}

/// generated route for
/// [_i12.HomePage]
class HomeRoute extends _i24.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i27.Key? key,
    int initialTabIndex = 0,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         HomeRoute.name,
         args: HomeRouteArgs(key: key, initialTabIndex: initialTabIndex),
         initialChildren: children,
       );

  static const String name = 'HomeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>(
        orElse: () => const HomeRouteArgs(),
      );
      return _i12.HomePage(
        key: args.key,
        initialTabIndex: args.initialTabIndex,
      );
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.initialTabIndex = 0});

  final _i27.Key? key;

  final int initialTabIndex;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, initialTabIndex: $initialTabIndex}';
  }
}

/// generated route for
/// [_i13.ImageFullPage]
class ImageFullRoute extends _i24.PageRouteInfo<ImageFullRouteArgs> {
  ImageFullRoute({
    _i25.Key? key,
    required _i28.AssetEntity entity,
    required _i28.ThumbnailOption option,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         ImageFullRoute.name,
         args: ImageFullRouteArgs(key: key, entity: entity, option: option),
         initialChildren: children,
       );

  static const String name = 'ImageFullRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ImageFullRouteArgs>();
      return _i13.ImageFullPage(
        key: args.key,
        entity: args.entity,
        option: args.option,
      );
    },
  );
}

class ImageFullRouteArgs {
  const ImageFullRouteArgs({
    this.key,
    required this.entity,
    required this.option,
  });

  final _i25.Key? key;

  final _i28.AssetEntity entity;

  final _i28.ThumbnailOption option;

  @override
  String toString() {
    return 'ImageFullRouteArgs{key: $key, entity: $entity, option: $option}';
  }
}

/// generated route for
/// [_i14.InfoModalPage]
class InfoModalRoute extends _i24.PageRouteInfo<InfoModalRouteArgs> {
  InfoModalRoute({
    _i25.Key? key,
    required String message,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         InfoModalRoute.name,
         args: InfoModalRouteArgs(key: key, message: message),
         initialChildren: children,
       );

  static const String name = 'InfoModalRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InfoModalRouteArgs>();
      return _i14.InfoModalPage(key: args.key, message: args.message);
    },
  );
}

class InfoModalRouteArgs {
  const InfoModalRouteArgs({this.key, required this.message});

  final _i25.Key? key;

  final String message;

  @override
  String toString() {
    return 'InfoModalRouteArgs{key: $key, message: $message}';
  }
}

/// generated route for
/// [_i15.MediaPreviewPage]
class MediaPreviewRoute extends _i24.PageRouteInfo<MediaPreviewRouteArgs> {
  MediaPreviewRoute({
    _i25.Key? key,
    required _i29.MediaFile file,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         MediaPreviewRoute.name,
         args: MediaPreviewRouteArgs(key: key, file: file),
         initialChildren: children,
       );

  static const String name = 'MediaPreviewRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MediaPreviewRouteArgs>();
      return _i15.MediaPreviewPage(key: args.key, file: args.file);
    },
  );
}

class MediaPreviewRouteArgs {
  const MediaPreviewRouteArgs({this.key, required this.file});

  final _i25.Key? key;

  final _i29.MediaFile file;

  @override
  String toString() {
    return 'MediaPreviewRouteArgs{key: $key, file: $file}';
  }
}

/// generated route for
/// [_i16.PaywallThreePlansScreen]
class PaywallThreePlansRoute extends _i24.PageRouteInfo<void> {
  const PaywallThreePlansRoute({List<_i24.PageRouteInfo>? children})
    : super(PaywallThreePlansRoute.name, initialChildren: children);

  static const String name = 'PaywallThreePlansRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i16.PaywallThreePlansScreen();
    },
  );
}

/// generated route for
/// [_i17.PermissionRequestPage]
class PermissionRequestRoute extends _i24.PageRouteInfo<void> {
  const PermissionRequestRoute({List<_i24.PageRouteInfo>? children})
    : super(PermissionRequestRoute.name, initialChildren: children);

  static const String name = 'PermissionRequestRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i17.PermissionRequestPage();
    },
  );
}

/// generated route for
/// [_i18.PrivacyPolicyPage]
class PrivacyPolicyRoute extends _i24.PageRouteInfo<void> {
  const PrivacyPolicyRoute({List<_i24.PageRouteInfo>? children})
    : super(PrivacyPolicyRoute.name, initialChildren: children);

  static const String name = 'PrivacyPolicyRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i18.PrivacyPolicyPage();
    },
  );
}

/// generated route for
/// [_i19.SettingsScreen]
class SettingsRoute extends _i24.PageRouteInfo<void> {
  const SettingsRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i19.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i20.SettingsShellPage]
class SettingsShellRoute extends _i24.PageRouteInfo<void> {
  const SettingsShellRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsShellRoute.name, initialChildren: children);

  static const String name = 'SettingsShellRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i20.SettingsShellPage();
    },
  );
}

/// generated route for
/// [_i21.SplashScreenPage]
class SplashRouteRoute extends _i24.PageRouteInfo<void> {
  const SplashRouteRoute({List<_i24.PageRouteInfo>? children})
    : super(SplashRouteRoute.name, initialChildren: children);

  static const String name = 'SplashRouteRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i21.SplashScreenPage();
    },
  );
}

/// generated route for
/// [_i22.SwipeScreen]
class SwipeRoute extends _i24.PageRouteInfo<void> {
  const SwipeRoute({List<_i24.PageRouteInfo>? children})
    : super(SwipeRoute.name, initialChildren: children);

  static const String name = 'SwipeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i22.SwipeScreen();
    },
  );
}

/// generated route for
/// [_i23.VideoFullPage]
class VideoFullRoute extends _i24.PageRouteInfo<VideoFullRouteArgs> {
  VideoFullRoute({
    _i25.Key? key,
    required _i28.AssetEntity entity,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         VideoFullRoute.name,
         args: VideoFullRouteArgs(key: key, entity: entity),
         initialChildren: children,
       );

  static const String name = 'VideoFullRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VideoFullRouteArgs>();
      return _i23.VideoFullPage(key: args.key, entity: args.entity);
    },
  );
}

class VideoFullRouteArgs {
  const VideoFullRouteArgs({this.key, required this.entity});

  final _i25.Key? key;

  final _i28.AssetEntity entity;

  @override
  String toString() {
    return 'VideoFullRouteArgs{key: $key, entity: $entity}';
  }
}
