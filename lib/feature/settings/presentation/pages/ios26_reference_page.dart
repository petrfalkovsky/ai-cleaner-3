import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/tab_view/ios26_reference_view.dart';

/// iOS 26 Reference Page
/// Эта страница просто вызывает нативный Swift модуль
/// Нативный экран открывается модально в полноэкранном режиме
@RoutePage()
class iOS26ReferencePage extends StatefulWidget {
  const iOS26ReferencePage({super.key});

  @override
  State<iOS26ReferencePage> createState() => _iOS26ReferencePageState();
}

class _iOS26ReferencePageState extends State<iOS26ReferencePage> {
  @override
  void initState() {
    super.initState();
    // Открываем нативный экран сразу после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openNativeScreen();
    });
  }

  Future<void> _openNativeScreen() async {
    try {
      // Открываем полностью нативный iOS экран
      await iOS26ReferenceHelper.openNativeScreen();

      // После закрытия нативного экрана возвращаемся назад
      if (mounted) {
        context.router.maybePop();
      }
    } catch (e) {
      print('Error opening native screen: $e');
      if (mounted) {
        // Показываем ошибку и возвращаемся назад
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to open native screen: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.router.maybePop();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем индикатор загрузки пока открывается нативный экран
    return const CupertinoPageScaffold(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
