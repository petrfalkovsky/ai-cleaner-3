import 'package:ai_cleaner_2/core/widgets/tap_animation.dart';
import 'package:ai_cleaner_2/feature/premium/presentation/widgets/iphone_storage_widget.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/l10n.dart';
import '../../domain/apphud_service.dart';
import '../../domain/premium_service.dart';
import '../../../../core/services/disk_space_service.dart';

// ДЛЯ ПУБЛИКАЦИИ
@RoutePage()
class PaywallThreePlansScreen extends StatefulWidget {
  const PaywallThreePlansScreen({super.key});

  @override
  State<PaywallThreePlansScreen> createState() => _PaywallThreePlansScreenState();
}

class _PaywallThreePlansScreenState extends State<PaywallThreePlansScreen>
    with TickerProviderStateMixin {
  int _selectedPlanIndex = 1; // default to yearly (центральный и самый дорогой)
  bool _isLoading = false;
  List<ApphudProduct> _apphudProducts = [];
  late AnimationController _shineController;
  double? _freeSpace; // Свободное место в GB

  @override
  void initState() {
    super.initState();
    _loadApphudProducts();
    _loadFreeSpace();

    // Анимация блика на кнопке (раз в 1.5 секунды)
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _loadFreeSpace() async {
    final freeGB = await DiskSpaceService.instance.getFreeDiskSpace();
    if (mounted && freeGB != null) {
      setState(() {
        _freeSpace = freeGB;
      });
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _loadApphudProducts() async {
    debugPrint('💳 PaywallThreePlans: Loading Apphud products...');
    final products = ApphudService().products;
    debugPrint('💳 PaywallThreePlans: Found ${products.length} products');

    if (products.isNotEmpty) {
      setState(() {
        _apphudProducts = products;
      });
      for (var product in products) {
        debugPrint('💳 Product: ${product.productId} - ${product.name}');
      }
    } else {
      debugPrint('⚠️ PaywallThreePlans: No products available!');
    }
  }

  Future<void> _purchaseProduct() async {
    debugPrint('💳 PaywallThreePlans: Purchase button pressed');

    if (_apphudProducts.isEmpty) {
      debugPrint('⚠️ PaywallThreePlans: No products loaded, showing error');
      _showErrorDialog(Locales.current.products_not_loaded);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedProduct = _apphudProducts[_selectedPlanIndex];
      final productId = selectedProduct.productId;

      debugPrint('💳 PaywallThreePlans: Attempting to purchase: $productId');

      final success = await PremiumService().purchaseSubscription(productId);

      setState(() => _isLoading = false);

      if (success && mounted) {
        debugPrint('✅ PaywallThreePlans: Purchase successful');
        _showSuccessDialog();
      } else if (mounted) {
        debugPrint('❌ PaywallThreePlans: Purchase failed');
        _showErrorDialog('Purchase failed. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ PaywallThreePlans: Purchase error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _restorePurchases() async {
    debugPrint('💳 PaywallThreePlans: Restore purchases button pressed');

    setState(() => _isLoading = true);

    try {
      final success = await ApphudService().restorePurchases();

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        debugPrint('✅ PaywallThreePlans: Purchases restored successfully');
        _showSuccessDialog();
      } else {
        debugPrint('⚠️ PaywallThreePlans: No purchases found');
        _showInfoDialog(Locales.current.restore_purchases, Locales.current.no_purchases_to_restore);
      }
    } catch (e) {
      debugPrint('❌ PaywallThreePlans: Restore error: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to restore purchases: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Locales.current.success),
        content: Text(Locales.current.trial_activated),
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

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Locales.current.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Locales.current;
    final plans = _buildPlans();

    return Material(
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.whiteBackground.withOpacity(.99),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: TapAnimation(
                  onTap: () => context.router.maybePop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.whiteTextSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .9,
                      child: IPhoneStorageWidget(),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: 50,
                              child: Image.asset('assets/images/gallery_icon.png'),
                            ),

                            SizedBox(
                              width: 244,
                              child: IPhoneStorageWidget(
                                showOnlyPhotos: true,
                                title: 'Photos & Videos',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    if (_freeSpace != null)
                      Text(
                        'Only ${_freeSpace!.toStringAsFixed(1)} GB left',
                        style: const TextStyle(
                          color: AppColors.whiteTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    if (_freeSpace != null)
                      const Text(
                        'free up space now',
                        style: TextStyle(
                          color: AppColors.whiteTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 20),

                    // Горизонтальные планы
                    Row(
                      children: List.generate(
                        plans.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 6,
                              right: index == plans.length - 1 ? 0 : 6,
                            ),
                            child: _buildPlanCard(
                              plan: plans[index],
                              isSelected: _selectedPlanIndex == index,
                              isCenterPlan: index == 1, // Центральный план
                              onTap: () => setState(() => _selectedPlanIndex = index),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Кнопка с анимацией блика
                    _buildAnimatedButton(locale),

                    const SizedBox(height: 16),

                    // Restore button
                    CupertinoButton(
                      onPressed: _isLoading ? null : _restorePurchases,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        locale.restore_purchases,
                        style: const TextStyle(
                          color: AppColors.whiteTextSecondary,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Terms
                    Text(
                      locale.subscription_terms,
                      style: const TextStyle(
                        color: AppColors.whiteTextSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_PaywallPlan> _buildPlans() {
    return [
      _PaywallPlan(title: 'Weekly', price: '\$9.99', period: 'week'),
      _PaywallPlan(title: 'Yearly', price: '\$29.99', period: 'year', badge: 'POPULAR'),
      _PaywallPlan(title: 'Lifetime', price: '\$39.99', period: 'once'),
    ];
  }

  Widget _buildPlanCard({
    required _PaywallPlan plan,
    required bool isSelected,
    required bool isCenterPlan,
    required VoidCallback onTap,
  }) {
    return TapAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.whiteSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCenterPlan ? AppColors.whiteAccentBlue : Colors.transparent,
            width: isCenterPlan ? 2 : 1,
          ),
          // iPhone-style тень
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isCenterPlan ? 0.12 : 0.08),
              offset: const Offset(0, 2),
              blurRadius: isCenterPlan ? 12 : 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Badge
            if (plan.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.whiteAccentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.badge!,
                  style: const TextStyle(
                    color: AppColors.whiteAccentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const SizedBox(height: 18),

            const SizedBox(height: 12),

            // Title
            Text(
              plan.title,
              style: const TextStyle(
                color: AppColors.whiteTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Price
            Text(
              plan.price,
              style: const TextStyle(
                color: AppColors.whiteTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Period
            Text(
              plan.period,
              style: const TextStyle(color: AppColors.whiteTextSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.whiteAccentBlue : AppColors.whiteTextSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.whiteAccentBlue,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(Locales locale) {
    return TapAnimation(
      onTap: _isLoading ? null : _purchaseProduct,
      child: AnimatedBuilder(
        animation: _shineController,
        builder: (context, child) {
          return Stack(
            children: [
              // Основная кнопка
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.whiteAccentBlue,
                  borderRadius: BorderRadius.circular(16),
                  // iPhone-style тень для кнопки
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.whiteAccentBlue.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          locale.continue_action,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // Анимация блика
              if (!_isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(painter: _ShinePainter(progress: _shineController.value)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PaywallPlan {
  const _PaywallPlan({required this.title, required this.price, required this.period, this.badge});

  final String title;
  final String price;
  final String period;
  final String? badge;
}

// Painter для анимации блика на кнопке
class _ShinePainter extends CustomPainter {
  final double progress;

  _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Блик появляется раз в секунду (progress идет от 0 до 1)
    // Блик движется слева направо под углом

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0),
            ],
            stops: const [0.3, 0.5, 0.7],
          ).createShader(
            Rect.fromLTWH(
              (size.width * 1.5) * progress - size.width * 0.5,
              -size.height * 0.5,
              size.width,
              size.height * 2,
            ),
          );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
