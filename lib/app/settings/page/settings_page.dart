import 'package:auto_route/auto_route.dart';
import '../../../core/extensions/core_extensions.dart';
import '../../../core/widgets/common/context_menu/context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.onLogoutCallback});
  final Future<void> Function()? onLogoutCallback;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.router.maybePop();
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        body: ContextMenuPage(
          items: [
            MenuItem(
              icon: FeatherIcons.user,
              title: 'profile',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.barChart,
              title: 'stats',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.info,
              title: 'about',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.shield,
              title: 'privacy policy',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.download,
              title: 'data export',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.userX,
              title: 'delete account',
              onTap: () {
              },
            ),
            MenuItem(
              icon: FeatherIcons.send,
              title: 'send feedback',
              onTap: () {
              },
            ),
          ],
        ),
      ).blur(32),
    );
  }
}