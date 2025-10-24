import 'package:flutter/material.dart';
class TransparentRoute extends ModalRoute<void> {
  late Widget child;
  final bool dismissable;
  TransparentRoute({required this.child, this.dismissable = false});
  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => false;
  @override
  Color get barrierColor => Colors.black.withValues(alpha: 0.0);
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: _buildOverlayContent(context),
    );
  }
  Widget _buildOverlayContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (dismissable) Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          child,
        ],
      ),
    );
  }
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}