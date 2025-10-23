import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../categories/presentation/pages/category_page.dart';
import '../../../../core/extensions/core_extensions.dart';
import '../../../../core/router/router.gr.dart';
import '../../../../core/theme/button.dart';

class HomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppbar({super.key, this.onDelete});

  final Function(List<String>)? onDelete;

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        flexibleSpace: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Row(
              spacing: 12,
              children: [
                Spacer(),
                ...AssetCategory.values.map(((category) {
                  return StyledButton.icon(
                    icon: category.icon,
                    onPressed: () {
                      context.router.push(
                        CategoryRoute(categoryType: 'photo', categoryName: category.name),
                      );
                    },
                  );
                })),
              ],
            ).p(right: 12),
          ),
        ),
      ),
    );

    return widget;
  }

  @override
  Size get preferredSize => const Size.fromHeight(75);
}
