import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/router/router.gr.dart';
import '../../../../generated/l10n.dart';
import '../../../premium/domain/apphud_service.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  String? _loadingButton; // ID кнопки которая сейчас в loading

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _restorePurchases() async {
    if (!mounted || _loadingButton != null) return;

    debugPrint('⚙️ SettingsScreen: Начало восстановления покупок');

    setState(() => _loadingButton = 'restore');

    try {
      final success = await ApphudService().restorePurchases();

      if (!mounted) return;

      setState(() => _loadingButton = null);

      if (success) {
        debugPrint('⚙️ SettingsScreen: ✅ Покупки восстановлены успешно');
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('✅ Success'),
            content: const Text('Your purchases have been restored successfully!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        debugPrint('⚙️ SettingsScreen: ⚠️ Активные покупки не найдены');
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(Locales.current.restore_purchases),
            content: Text(Locales.current.no_purchases_to_restore),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚙️ SettingsScreen: ❌ Ошибка восстановления: $e');

      if (mounted) {
        setState(() => _loadingButton = null);

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to restore purchases: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    final appleAppID = dotenv.env['APPLE_APP_ID'];

    if (!mounted || _loadingButton != null) return;

    setState(() => _loadingButton = 'rate');

    try {
      final InAppReview inAppReview = InAppReview.instance;

      // Для кнопки в настройках лучше всегда открывать App Store напрямую
      // т.к. requestReview() ограничен Apple (max 3 раза в год)
      // и может не показаться, оставив пользователя в недоумении
      await inAppReview.openStoreListing(
        appStoreId: appleAppID, // App Store ID
      );
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  Future<void> _shareApp() async {
    if (!mounted || _loadingButton != null) return;

    setState(() => _loadingButton = 'share');

    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        'Check out AI Cleaner - the perfect app for cleaning your photo gallery!',
        subject: 'AI Cleaner App',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        setState(() => _loadingButton = null);
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://www.freeprivacypolicy.com/live/36e12763-9a4d-4efa-ae3d-afc67a86a479';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTermsOfService() async {
    const url = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0E27),
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF0A0E27),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.router.maybePop(),
            child: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          middle: Text(Locales.current.settings, style: const TextStyle(color: Colors.white)),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 20),

              // Аккаунт
              _buildSectionHeader(Locales.current.account),
              _buildSettingsTile(
                icon: CupertinoIcons.arrow_clockwise,
                title: Locales.current.restore_purchases,
                onTap: _restorePurchases,
                isLoading: _loadingButton == 'restore',
              ),

              // 🧪 ТЕСТОВАЯ КНОПКА (только в Mock режиме)
              if (ApphudService().isMockMode)
                _buildSettingsTile(
                  icon: CupertinoIcons.clear_circled,
                  title: '🧪 TEST: Reset Premium (Mock)',
                  onTap: () {
                    debugPrint('⚙️ SettingsScreen: Сброс mock premium');
                    ApphudService().resetMockPremium();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🧪 Mock Premium сброшен. Нажмите "Restore Purchases" для теста.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 30),

              // Обратная связь
              _buildSectionHeader(Locales.current.feedback),
              _buildSettingsTile(
                icon: CupertinoIcons.mail,
                title: Locales.current.contact_and_feedback,
                onTap: () => context.router.push(const FeedbackRoute()),
                showChevron: true,
              ),
              _buildSettingsTile(
                icon: CupertinoIcons.star,
                title: Locales.current.rate_app,
                onTap: _rateApp,
                isLoading: _loadingButton == 'rate',
              ),
              _buildSettingsTile(
                icon: CupertinoIcons.square_arrow_up,
                title: Locales.current.share_app,
                onTap: _shareApp,
                isLoading: _loadingButton == 'share',
              ),

              const SizedBox(height: 30),

              // Политика
              _buildSectionHeader(Locales.current.policy),
              _buildSettingsTile(
                icon: CupertinoIcons.doc_text,
                title: Locales.current.terms_and_privacy,
                onTap: _openTermsOfService,
                showChevron: true,
              ),
              _buildSettingsTile(
                icon: CupertinoIcons.lock_shield,
                title: Locales.current.privacy_policy,
                onTap: _openPrivacyPolicy,
                showChevron: true,
              ),

              const SizedBox(height: 30),

              // Версия приложения
              if (_appVersion.isNotEmpty)
                Center(
                  child: Text(
                    '${Locales.current.version} $_appVersion',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showChevron = false,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: isLoading ? null : onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(isLoading ? 0.3 : 0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: isLoading
                  ? Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: const CupertinoActivityIndicator(color: Colors.white),
                    )
                  : Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            if (showChevron && !isLoading)
              Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
