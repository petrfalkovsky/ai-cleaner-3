import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/tab_view/ios26_reference_view.dart';

@RoutePage()
class iOS26ReferencePage extends StatelessWidget {
  const iOS26ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: const Text('iOS 26 Reference'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.maybePop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: const SafeArea(
        child: iOS26ReferenceView(),
      ),
    );
  }
}
